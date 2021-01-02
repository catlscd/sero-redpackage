<template>
  <!-- 发送包页面 -->
  <b-container id="send" class="page-content">
    <b-form @submit.prevent.stop="onSubmit">
      <b-form-group>
        <div class="cell">
          <div class="title">{{ $t("send_token") }}</div>
          <div v-if="token.currency == '@other'">
            <b-form-input
              class="value token-value"
              v-model="redPackage.token"
              placeholder="请输入 Token 名称"
            ></b-form-input>
          </div>
          <b-dropdown
            v-else
            size="sm"
            right
            variant="muted"
            toggle-class="text-decoration-none"
            no-caret
          >
            <template v-slot:button-content>
              <div class="content">
                <div class="value">{{ redPackage.token }}</div>
                <b-icon icon="chevron-right"></b-icon>
              </div>
            </template>
            <b-dropdown-item
              @click="changeToken(item)"
              :key="item.value"
              v-for="item in tokens"
            >
              {{ item.text }}
            </b-dropdown-item>
          </b-dropdown>
        </div>
      </b-form-group>

      <b-form-group>
        <b-input-group size="lg" :append="redPackage.token">
          <template v-slot:prepend>
            <b-input-group-text v-if="redPackage.playType == 0">
              <span class="icon-ping" v-if="$i18n.locale == 'zh'">拼</span>
              {{ $t("send_total") }}
            </b-input-group-text>
            <b-input-group-text v-if="redPackage.playType == 1">
              {{ $t("amount_each") }}
            </b-input-group-text>
          </template>
          <b-form-input v-model="redPackage.price"></b-form-input>
        </b-input-group>
      </b-form-group>
      <p v-if="redPackage.playType == 0">
        {{ $t("send_mode_1") }}
        <span class="yellow" @click="redPackage.playType = 1">
          {{ $t("change_mode_1") }}
        </span>
      </p>
      <p v-if="redPackage.playType == 1">
        {{ $t("send_mode_2") }}
        <span class="yellow" @click="redPackage.playType = 0">
          {{ $t("change_mode_2") }}
        </span>
      </p>

      <b-form-group>
        <b-input-group
          size="lg"
          :prepend="$t('send_quantity')"
          :append="$i18n.locale == 'zh' ? '个' : ''"
        >
          <b-form-input v-model="redPackage.nums"></b-form-input>
        </b-input-group>
        <b-form-invalid-feedback
          :state="redPackage.nums && redPackage.nums > 0"
        >
          {{ $t("send_nums_err") }}
        </b-form-invalid-feedback>
      </b-form-group>

      <b-form-group>
        <b-form-textarea
          v-model="redPackage.msg"
          size="sm"
          :placeholder="$t('best_wishes')"
        ></b-form-textarea>
      </b-form-group>

      <b-form-group>
        <div class="cell">
          <div class="title">{{ $t("cover") }}</div>
          <!-- <div class="content" style="padding-right: 0.5rem;">
            <div class="value">默认</div>
            <b-icon icon="chevron-right"></b-icon>
          </div> -->

          <b-dropdown
            size="sm"
            right
            variant="muted"
            toggle-class="text-decoration-none"
            no-caret
          >
            <template v-slot:button-content style="padding-right:0px">
              <div class="content">
                <div class="value">{{ coverText }}</div>
                <b-icon icon="chevron-right"></b-icon>
              </div>
            </template>
            <b-dropdown-item
              @click="changeCover(item)"
              :key="item.value"
              v-for="item in coverList"
              >{{ item.text }}
            </b-dropdown-item>
          </b-dropdown>
        </div>
      </b-form-group>
      <!-- 
      <b-form-group style="display:none;">
        <div class="cell">
          <div class="title">红包口令</div>
          <div class="content">
            <div class="value">默认生成</div>
            <b-icon icon="chevron-right"></b-icon>
          </div>
        </div>
      </b-form-group> -->

      <b-form-group>
        <div class="cell">
          <div class="title">{{ $t("who_can_open") }}</div>
          <b-dropdown
            size="sm"
            right
            variant="muted"
            toggle-class="text-decoration-none"
            no-caret
          >
            <template v-slot:button-content style="padding-right:0px">
              <div class="content">
                <div class="value">{{ whoCanGetText }}</div>
                <b-icon icon="chevron-right"></b-icon>
              </div>
            </template>
            <b-dropdown-item
              @click="changeWhoCanGet(item)"
              :key="item.value"
              v-for="item in whoCanGetEnum"
              >{{ item.text }}</b-dropdown-item
            >
          </b-dropdown>
        </div>
      </b-form-group>
      <!-- <b-form-group v-if="redPackage.whoCanGet == 2">
        <b-form-textarea
          v-model="redPackage.canGetUser"
          size="md"
          placeholder="请输入可以抢红包的地址，一行一个"
        ></b-form-textarea>
      </b-form-group> -->
      <div
        class="total"
        style="text-align: center;font-weight: bold;font-size: 20px;margin: 20px;"
      >
        {{ $t("send_total2") }}{{ totalPrice }} {{ redPackage.token }}
      </div>
      <div class="text-center" style="margin:35px auto;">
        <b-button type="submit" size="lg" variant="danger">
          {{ $t("send_prepare") }}
        </b-button>
      </div>
    </b-form>
  </b-container>
</template>
<script>
import BigNumber from "bignumber.js";
import { getDecimal } from "@/common/utils";
export default {
  name: "Send",
  components: {},
  methods: {
    onSubmit() {
      if (!this.$contract.isLatestContract()) {
        alert("旧版本已关闭发送红包功能！请尽快提取资产！");
        return false;
      }
      if (!this.redPackage.msg) {
        this.redPackage.msg = this.$t("best_wishes");
      }
      // console.log("sero:sendPackage ", JSON.stringify(this.redPackage));

      if (parseInt(this.redPackage.nums) < 1) {
        alert(this.$t("send_nums_err"));
        return;
      }

      if (parseInt(this.redPackage.nums) > 200) {
        alert(this.$t("send_nums_err2"));
        return;
      }
      this.redPackage.token = this.redPackage.token.toUpperCase();
      if (!this.redPackage.token.match(/^[A-Z][A-Z0-9_]+$/)) {
        alert(this.$t("input_token_name_err"));
      }

      getDecimal(
        this.redPackage.token,
        (decimal) => {
          let unit = new BigNumber(10).pow(decimal),
            totalPrice = unit.times(this.totalPrice),
            minSend = new BigNumber(this.token.minSendAmount).div(unit),
            currency = this.redPackage.token;
          // console.log(this.token);
          var ret = totalPrice.comparedTo(this.token.minSendAmount);
          if (ret == -1 || ret === null) {
            this.$bvToast.toast(
              this.$t("send_amount_er") + ` ${minSend}${currency}`,
              {
                title: this.$t("tips"),
                toaster: "b-toaster-top-center",
                autoHideDelay: 3000,
                appendToast: false,
                variant: "danger",
              }
            );
            return;
          }
          let params = [
            this.redPackage.playType,
            this.redPackage.nums,
            this.redPackage.token,
            this.redPackage.msg,
            this.redPackage.cover,
            this.redPackage.whoCanGet,
          ];
          this.executeMethod(
            "createPackage",
            params,
            totalPrice.toString(16),
            this.redPackage.token
          )
            .then((res) => {
              if (!res) {
                // this.$bvToast.toast(this.$t("send_tx_failed"), {
                //   title: this.$t("tips"),
                //   toaster: "b-toaster-top-center",
                //   autoHideDelay: 3000,
                //   appendToast: false,
                //   variant: "danger",
                // });
                return;
              }

              this.saveSendTokenName(this.redPackage.token);

              this.$router.push({
                name: "SendResult",
                query: { txhash: res },
              });
            })
            .catch((err) => {
              alert(this.$t("send_faild") + err);
            });
        },
        (error) => {
          alert(error.message);
        }
      );
    },
    changeToken(token) {
      this.token = token;
      this.redPackage.token = token.value;
      let cover = this.coverMap[token.value.toLowerCase()];
      if (!cover) {
        cover = this.coverMap["default"];
      }
      this.changeCover(cover);
    },
    changeWhoCanGet(item) {
      this.redPackage.whoCanGet = item.value;
      this.whoCanGetText = item.text;
    },
    changeCover(item) {
      this.coverText = item.text;
      this.redPackage.cover = item.value;
    },
    saveSendTokenName(tokenName) {
      var sendTokens = JSON.parse(
        localStorage.getItem("MY_SEND_TOKENS") || "[]"
      );
      for (const t of sendTokens) {
        if (t == tokenName) {
          return;
        }
      }
      sendTokens.push(tokenName);

      localStorage.setItem("MY_SEND_TOKENS", JSON.stringify(sendTokens));
    },
    getTokenList() {
      this.callMethod("tokenList", []).then(({ result }) => {
        // console.log("sero:tokens ", result);
        var tokenList = [];
        var tokenNameMap = {};
        for (let i = 0; i < result.length; i++) {
          let item = result[i];
          if (item.weight == 0) {
            continue;
          }
          if (item.currency == "SUSD") {
            item.weight = 999;
          }
          item.text = item.currency;
          item.value = item.currency;
          tokenList.push(item);

          tokenNameMap[item.currency] = true;
        }

        tokenList.sort((a, b) => {
          return b.weight - a.weight;
        });

        var sendTokens = JSON.parse(
          localStorage.getItem("MY_SEND_TOKENS") || "[]"
        );

        for (var t of sendTokens) {
          if (tokenNameMap[t]) {
            continue;
          }
          tokenList.push({
            currency: t,
            decimals: "0",
            fees: "0",
            minSendAmount: "1",
            minWithdrawAmount: "0",
            text: t,
            value: t,
            weight: "1",
          });
        }

        tokenList.push({
          currency: "@other",
          decimals: "0",
          fees: "0",
          minSendAmount: "1",
          minWithdrawAmount: "0",
          text: this.$t("other"),
          value: "",
          weight: "1",
        });
        this.tokens = tokenList;
      });
    },
  },
  computed: {
    totalPrice() {
      var p = this.redPackage.price;
      if (!p) {
        p = 0;
      }
      var price =
        this.redPackage.playType == 0
          ? new BigNumber(p)
          : new BigNumber(p).times(this.redPackage.nums || 1);

      return price;
    },
  },
  created() {
    this.$root.changeNavTitle(this.$t("send_red_envelope"));

    this.getTokenList();
  },
  data() {
    let coverList = [
        { text: this.$t("default").toUpperCase(), value: "default" },
        // { text: "ASNOW", value: "asnow" },
      ],
      coverMap = {};
    for (var cover of coverList) {
      coverMap[cover.value] = cover;
    }
    return {
      whoCanGetText: this.$t("all_people").toUpperCase(),
      coverText: this.$t("default").toUpperCase(),
      whoCanGetEnum: [
        { text: this.$t("all_people").toUpperCase(), value: 0 },
        { text: this.$t("my_friends"), value: 1 },
        // { text: "自定义", value: 2 },
      ],
      coverList: coverList,
      coverMap: coverMap,
      token: {
        text: "SERO",
        value: "SERO",
        decimals: 18,
        minSendAmount: 1e16,
        weight: 999,
      },
      tokens: [
        // { text: "SERO", value: "SERO" },
        // { text: "ASNOW", value: "ASNOW" },
        // { text: "HAPY", value: "HAPY" },
      ],
      redPackage: {
        token: "SERO",
        price: "1",
        nums: "10",
        msg: "",
        cover: "default",
        word: 0,
        whoCanGet: 0,
        canGetUser: "",
        playType: 0, //0：拼手气，1：普通
      },
    };
  },
};
</script>

<style>
/* #send {
  padding-top: 25px;
} */
.token-value {
  min-width: 66px;
  border: none;
  border-bottom: 1px #ced4da solid;
  border-radius: 0px;
  max-width: 220px;
  text-align: right;
  width: auto;
  display: inline-block;
}
.cell {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 5px 0px;
}
.cell .title {
  font-size: 1.25rem;
}
.cell .content {
  display: flex;
  justify-content: center;
  align-items: center;
}
.cell .btn:focus {
  box-shadow: none;
}
.cell .content .b-icon {
  font-size: 1.25rem;
}
.cell .content .value {
  color: #aaa;
}
.cell .content .value .b-icon {
  color: #2c3e50;
}
#send .yellow {
  color: #d09e48;
}
</style>
