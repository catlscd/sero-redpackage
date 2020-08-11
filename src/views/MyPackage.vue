<template>
  <!-- 我发的红包 -->
  <!-- Token、时间、金额、已抢信息 -->
  <b-container id="my-package" class="page-content">
    <p
      class="text-center"
      style="font-size:15px;color:#333;"
      v-if="loadding == false && !packages.length"
    >
      {{ $t("unsent_tips") }}
      <b-button
        class="send-btn"
        variant="warning"
        @click="goToSendPackage()"
        style="margin-top:20px"
      >
        {{ $t("home_send_btn") }}
      </b-button>
    </p>
    <b-overlay :show="loadding && start == 0" no-wrap> </b-overlay>
    <p
      class="text-center"
      style="font-size:13px;color:#ccc;"
      v-if="packages.length"
    >
      <b-icon icon="info-circle-fill"></b-icon>
      &nbsp;&nbsp;{{ $t("share_tips") }}
    </p>
    <div class="list">
      <div
        class="item"
        v-for="item in packages"
        :key="item.shareCode"
        @click.stop="goDetail(item)"
      >
        <div class="logo">
          <my-img
            :src="'img/token-' + item.currency.toLowerCase() + '.png'"
            default-img="img/token-sero.png"
            class="img-fluid"
          ></my-img>
        </div>
        <div class="info">
          <div class="detail">
            <div class="nums">
              {{
                $t("opened_nums")
                  .replace("{openNums}", item.openNums)
                  .replace("{nums}", item.nums)
              }}
            </div>
            <div class="money">
              <span
                v-if="item.typ == 0 && $i18n.locale == 'zh'"
                class="icon-ping"
                >拼</span
              >
              <span v-if="$i18n.locale == 'zh'">剩</span>
              <span class="remain">
                {{ item.remainAmount / 10 ** (item.decimal || 0) }}
              </span>
              /{{ item.money / 10 ** (item.decimal || 0) }}
              {{ item.currency }}
            </div>
          </div>
          <div class="meta">
            <div class="time">{{ item.created | formatDatetime }}</div>
            <div class="tool">
              <b-icon
                icon="reply"
                @click.stop.prevent="sharePackage(item)"
              ></b-icon>
            </div>
          </div>
        </div>
      </div>
      <div
        class="text-center"
        style="padding:13px 0px 25px;"
        v-if="start != 0 && !loadMoreDisabled"
      >
        <b-overlay
          :show="loadding"
          rounded
          opacity="0.6"
          spinner-small
          class="d-inline-block"
        >
          <b-btn
            @click.stop.prevent="loadMore"
            :disabled="loadMoreDisabled"
            size="sm"
            variant="warning"
          >
            {{ $t("loadmore") }}
          </b-btn>
        </b-overlay>
      </div>
    </div>
  </b-container>
</template>
<script>
export default {
  methods: {
    goToSendPackage() {
      this.$router.push({ name: "Send" });
    },
    goDetail(item) {
      this.$router.push({
        name: "Detail",
        query: {
          code: item.shareCode,
          currency: item.currency,
          from: "MyPackage",
        },
      });
    },
    loadMore() {
      var start = this.start - this.perPage;
      if (!start || this.loadMoreDisabled) {
        this.loadMoreDisabled = true;
        return;
      }
      this.start = start;
      this.mySendPackages();
    },
    mySendPackages() {
      this.loadding = true;
      this.callMethod("mySendPackageList", [this.start, this.perPage]).then(
        ({ total, sendPackages }) => {
          if (total > 0) {
            this.$root.changeNavTitle(
              this.$t("my_send_red_envelope") + `（${total}）`
            );
          }
          // console.log("sero:mySendPackages   ", total, sendPackages);
          if (!this.total) {
            this.total = total;
          }
          if (!this.start) {
            this.start = total;
          }
          if (
            sendPackages.length < this.perPage ||
            this.start == this.perPage
          ) {
            this.loadMoreDisabled = true;
          }
          this.loadding = false;
          this.packages = this.packages.concat(sendPackages);
        }
      );
    },
    sharePackage(item) {
      this.$router.push({
        name: "SendResult",
        query: { code: item.shareCode, currency: item.currency },
      });
    },
  },
  created() {
    this.$root.changeNavTitle(this.$t("my_send_red_envelope"));
    this.mySendPackages();
  },
  data() {
    return {
      packages: [],
      loadding: true,
      total: 0,
      start: 0,
      perPage: 50,
      loadMoreDisabled: false,
    };
  },
};
</script>
<style>
/* #my-package .list { */
/* border-bottom: 1px #eee solid; */
/* } */
#my-package .list .item {
  display: flex;
  border-top: 1px #eee solid;
  padding: 15px 0px;
}
#my-package .list .item .logo {
  width: 38px;
  padding-right: 15px;
  border-radius: 5px;
}
#my-package .list .item .info {
  display: flex;
  flex: 1;
  justify-content: space-between;
  flex-direction: column;
}
#my-package .list .item .remain {
  display: inline-block;
  max-width: 50px;
  overflow: hidden;
  text-overflow: ellipsis;
  margin-left: 5px;
}
#my-package .list .item .info > div {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
#my-package .list .item .info .money {
  display: flex;
}
#my-package .list .item .info .detail {
  color: #282828;
  font-size: 16px;
}
#my-package .list .item .info .time {
  color: #cbcbcb;
  font-size: 14px;
}
#my-package .list .item .info .tool {
  font-size: 20px;
}
#my-package .btn-warning:focus {
  box-shadow: none;
  background-color: #ffc107;
  border-color: #ffc107;
}
</style>
