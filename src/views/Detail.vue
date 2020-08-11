<template>
  <!-- 红包详情页 -->
  <div id="detail">
    <img src="../assets/detail-bg.png" class="img-fluid" alt="" />
    <b-container>
      <div class="info">
        <div class="sender">
          <my-img
            v-if="redPackage.currency"
            :src="'img/token-' + redPackage.currency.toLowerCase() + '.png'"
            default-img="img/token-sero.png"
            class="token-logo img-fluid"
          ></my-img>
          <span class="name">
            {{
              $t("red_envelope_from").replace(
                "{nickname}",
                redPackage.nickname || redPackage.currency
              )
            }}
          </span>
          <span
            class="icon-ping"
            v-if="redPackage.typ == 0 && $i18n.locale == 'zh'"
            >拼</span
          >
        </div>
        <div class="desc">{{ redPackage.note }}</div>

        <div
          class="text-center grab-status"
          v-if="from == 'grabPackage' && txStatus == '0x0'"
        >
          {{ $t("tx_submit_success") }}<br />
          <b-overlay
            :show="txStatus == '0x0'"
            rounded
            opacity="0.2"
            spinner-small
            spinner-variant="primary"
            class="d-inline-block"
          >
            <b-badge variant="warning">{{ $t("confirming") }}</b-badge>
          </b-overlay>
        </div>

        <div class="money" v-else>
          <span v-if="from == 'MyPackage' || from == 'ViewAll'">
            {{ redPackage.money }}
          </span>
          <span v-else>
            {{ getMoney | formatMoney(redPackage.decimals, true) }}
          </span>
          <span class="token">{{ redPackage.currency }}</span>
          <p class="tips" v-if="getMoney > 0">
            {{ $t("transferred_to_asset") }}
          </p>
        </div>
      </div>
    </b-container>
    <div class="hr"></div>
    <div class="list">
      <div class="head" v-if="redPackage.openNums != redPackage.nums">
        {{
          $t("opened_nums")
            .replace("{openNums}", redPackage.openNums)
            .replace("{nums}", redPackage.nums)
        }},&nbsp;
        <span v-if="$i18n.locale == 'zh'">剩余</span>
        {{
          redPackage.remainAmount | formatMoney(redPackage.decimals, true)
        }}/{{ redPackage.money }}
        {{ redPackage.currency }}
      </div>
      <div class="head" v-else>
        {{ $t("red_envelope_nums").replace("{nums}", redPackage.nums) }}
        {{ $t("total") }}
        <span @click="showMoney({ money: redPackage.moneyTa })">
          {{ redPackage.money }}{{ redPackage.currency }}</span
        >,&nbsp;{{ $t("grab_finished") }}
      </div>
      <ul v-if="redPackage.decimals">
        <li v-for="item in openList" :key="item.txhash">
          <div class="user">
            <p class="name">{{ item.nickname }}</p>
            <p class="time">{{ item.created | formatDatetime }}</p>
          </div>
          <div class="money">
            <p class="val" @click="showMoney(item)">
              {{ item.money | formatMoney(redPackage.decimals, true) }}
            </p>
            <p class="best" v-if="checkBest(item)">🎉 {{ $t("best_luck") }}</p>
          </div>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
import BigNumber from "bignumber.js";
export default {
  methods: {
    checkBest(item) {
      return (
        (this.redPackage.openNums == this.redPackage.nums ||
          parseInt(this.redPackage.remainAmount) < parseInt(item.money)) &&
        item.best
      );
    },
    showMoney(item) {
      alert(
        new BigNumber(item.money)
          .div(new BigNumber(10 ** this.redPackage.decimals))
          .toString()
      );
    },
    fetchDetail() {
      // console.log("sero:packageInfo: ", this.code);
      this.callMethod("packageInfo", [this.code]).then(
        ({ detail, nickname, note }) => {
          // canOpen,cover,
          var decimal = new BigNumber(10).pow(detail.decimal);
          this.redPackage = {
            currency: detail.currency,
            nickname: nickname,
            decimals: detail.decimal,
            moneyTa: detail.money,
            money: new BigNumber(detail.money).div(decimal),
            note: note,
            nums: detail.nums,
            openNums: detail.openNums,
            remainAmount: detail.remainAmount,
            typ: detail.typ,
            created: detail.created,
          };
        }
      );
    },
    fetchOpenList() {
      this.callMethod("packageOpenInfo", [this.code]).then(
        ({ openedList, nameList }) => {
          // console.log("sero:packageOpenInfo", openedList);
          let openList = [],
            best = 0,
            bestIndex = 0,
            openLen = openedList.length;
          for (let i = openLen - 1; i >= 0; i--) {
            const item = openedList[i];
            if (item.txhash == this.txhash) {
              this.getMoney = item.money;
            }
            if (new BigNumber(item.money).comparedTo(best) === 1) {
              best = item.money;
              bestIndex = openLen - 1 - i;
            }
            // console.log(best, bestIndex);
            openList.push({
              nickname:
                nameList[i] || (this.$i18n.locale == "zh" ? "匿名用户" : "-"),
              money: item.money,
              created: item.created,
            });
          }

          if (best) {
            openList[bestIndex].best = true;
          }
          this.openList = openList;
          if (this.openList.length != this.redPackage.nums) {
            this.cron();
            // setTimeout(this.fetchOpenList, 3000);
          } else {
            this.totalTime = openList[0].created - this.redPackage.created;
          }
        }
      );
    },
    cron() {
      setTimeout(() => {
        this.fetchDetail();
        this.fetchOpenList();
      }, 3000);
    },
    fetchGetPackage() {
      // console.log("sero:fetchGetPackage ", this.txhash, this.from);
      if (this.from != "grabPackage" || !this.txhash) {
        return;
      }
      this.getTransactionReceipt(this.txhash).then((res) => {
        if (res && res.status == "0x1") {
          this.txStatus = "0x1";
          this.fetchDetail();
          this.fetchOpenList();
        } else {
          setTimeout(this.fetchGetPackage, 3000);
        }
      });
    },
  },

  created() {
    this.$root.changeNavTitle(this.$t("red_envelope"));
    this.$root.navWhite = true;
    this.fetchDetail();
    this.fetchOpenList();
    this.fetchGetPackage();
  },
  data() {
    return {
      totalTime: 0,
      code: this.$route.query.code,
      txhash: this.$route.query.txhash,
      from: this.$route.query.from,
      // from: "grabPackage",
      // txhash:"0x67c8c55e7f6f503ad17ad044dff42889f3aba21db9601b34d6c7307c9d186098",
      txStatus: "0x0",
      openList: [],
      getMoney: 0,
      redPackage: {
        currency: "",
        decimals: "",
        money: "",
        note: "",
        nums: "",
        openNums: "",
        remainAmount: "",
        typ: "",
      },
    };
  },
  destroyed() {
    this.$root.navWhite = false;
  },
};
</script>
<style>
#detail .hr {
  background-color: #f3f3f3;
  height: 10px;
  /* margin-left: -15px; */
  /* margin-right: -15px; */
}
#detail .info {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding: 30px;
}
#detail .info .token-logo {
  width: 22px;
  height: 22px;
  border-radius: 2px;
}
#detail .info .sender {
  display: flex;
  align-items: center;
}
#detail .info .sender .name {
  color: #1c1c1c;
  font-weight: bold;
  padding: 0px 6px;
  font-size: 18px;
}
#detail .info .desc {
  color: #b4b4b4;
  margin-top: 6px;
}
#detail .info .money {
  color: #d4b07c;
  font-size: 40px;
  margin-top: 10px;
  text-align: center;
}
#detail .info .grab-status {
  color: #d4b07c;
  margin-top: 30px;
}
#detail .info .money .token {
  font-size: 15px;
  margin-left: 6px;
}
#detail .info .tips {
  color: #d4b07c;
  margin-bottom: 0px;
  font-size: 16px;
}

#detail .list .head {
  color: #b7b7b7;
  padding: 10px 15px;
  border-bottom: 1px #eee solid;
}
#detail .list ul {
  padding: 0px 10px;
  list-style: none;
}
#detail .list ul li {
  display: flex;
  justify-content: space-between;
  border-bottom: 1px #eee solid;
  padding: 10px 0px;
}
#detail .list ul li p {
  margin-bottom: 0px;
}
#detail .list ul li .name {
  color: #262626;
  margin-bottom: 0px;
  font-size: 16px;
}
#detail .list ul li .time {
  margin-bottom: 0px;
  color: #cbcbcb;
  font-size: 14px;
}
#detail .list ul li .money {
  padding-right: 12px;
  font-size: 16px;
  text-align: right;
}
#detail .list ul li .money .best {
  font-size: 14px;
  color: #d4b07c;
}
</style>
