<template>
  <!-- 主页：输入口令抢红包，发红包按钮，广告！ -->
  <b-container class="page-content" id="home">
    <b-alert show variant="secondary" style="font-size:13px;">
      <b-icon icon="info-circle-fill"></b-icon>
      &nbsp;&nbsp;&nbsp;{{ $t("bannerText") }}
    </b-alert>
    <!-- <img
      src="../assets/home-banner.png"
      class="banner img-fluid"
      referrerPolicy="no-referrer"
    /> -->
    <div class="open-container">
      <div class="top">
        <img alt="Sero logo" class="logo img-fluid" src="../assets/logo.png" />
        <h2 class="title">{{ $t("title") }}</h2>
      </div>

      <b-row>
        <b-col cols="12">
          <div class="get">
            <b-input-group size="lg">
              <b-form-input
                v-model="code"
                :placeholder="$t('codePlaceholder')"
              ></b-form-input>
              <template v-slot:append>
                <b-input-group-text @click="getPackage">
                  {{ $t("open") }}
                </b-input-group-text>
              </template>
            </b-input-group>
            <!-- <b-form-text id="input-live-help">领取红包钱包需要留足手续费</b-form-text> -->
          </div>
        </b-col>
      </b-row>
      <div class="send">
        <b-button class="send-btn" variant="warning" @click="goToSendPackage()">
          {{ $t("home_send_btn") }}
        </b-button>
      </div>
    </div>
    <div
      class="redpackage-dialog redpackage-default"
      :class="['redpackage-cover-' + detail.cover]"
      v-show="showPackage"
      @click="hidePackage()"
    >
      <b-overlay
        :show="!detail.code"
        rounded
        opacity="0"
        spinner-small
        spinner-variant="primary"
        class="d-inline-block"
      >
        <div
          class="wrapper"
          @click.stop.prevent="void 0"
          :class="{ animate: detail.code != '' }"
        >
          <div class="top">
            <div class="author">
              <my-img
                v-if="detail.currency"
                :src="'img/token-' + detail.currency.toLowerCase() + '.png'"
                default-img="img/token-sero.png"
              >
              </my-img>
              &nbsp;&nbsp;
              {{
                $t("red_envelope_from")
                  .replace("{nickname}", detail.nickname)
                  .replace("{currency}", detail.currency)
              }}
            </div>
            <p class="desc">{{ detail.note }}</p>
            <p>
              <span style="font-size:22px;">
                {{ detail.money | formatMoney(detail.decimal, true) }}
              </span>
              <span style="font-size:13px;">{{ detail.currency }}</span>
            </p>
            <p class="open-error" :class="{ animate: openError != '' }">
              {{ openError }}
            </p>
          </div>

          <button
            class="open"
            :class="[openAnimate ? 'animate' : '', $i18n.locale]"
            @click="openRedpackage()"
          >
            {{ $t("openBtn") }}
          </button>
          <a href="" class="view" @click.prevent.stop="goDetail()">
            {{ $t("see_luck") }}<b-icon icon="chevron-right"></b-icon>
          </a>
        </div>
      </b-overlay>
    </div>
  </b-container>
</template>

<script>
// @ is an alias to /src
import { getDecimal } from "@/common/utils";

export default {
  name: "Home",
  components: {},
  methods: {
    hidePackage() {
      this.showPackage = false;
      this.detail.code = "";
    },
    goDetail() {
      this.$router.push({
        name: "Detail",
        query: {
          code: this.detail.code,
          currency: this.detail.currency,
          from: "ViewAll",
        },
      });
    },
    checkNickname() {
      let nickname = localStorage.getItem("nickname");
      if (nickname === null) {
        return true;
      }
      if (!nickname) {
        return false;
      }
      return true;
    },
    getPackage() {
      if (!this.checkNickname()) {
        this.$bvToast.toast(this.$t("tipsContent"), {
          title: this.$t("tips"),
          toaster: "b-toaster-top-center",
          autoHideDelay: 3000,
          appendToast: false,
          variant: "danger",
        });
        return false;
      }
      if (!this.code) {
        return false;
      }
      var codeExp = /^[a-zA-Z0-9]{5,}$/;
      if (codeExp.test(this.code) == false) {
        var match = null;
        if (this.$i18n.locale == "zh") {
          match = this.code.match(/红包口令：([a-zA-Z0-9]{5,})/);
        } else if (this.$i18n.locale == "zh-hant") {
          match = this.code.match(/紅包口令：([a-zA-Z0-9]{5,})/);
        } else if (this.$i18n.locale == "en") {
          match = this.code.match(/Code:\s?([a-zA-Z0-9]{5,})/);
        }
        if (match) {
          this.code = match[1];
        }
      }
      this.callMethod("packageInfo", [this.code])
        .then(({ detail, canOpen, cover, nickname, note }) => {
          if (!canOpen) {
            this.$bvToast.toast(this.$t("cant_open"), {
              title: this.$t("error"),
              toaster: "b-toaster-top-center",
              autoHideDelay: 3000,
              appendToast: false,
              variant: "danger",
            });
            return;
          }
          this.openError = "";
          this.showPackage = true;
          getDecimal(detail.currency, (decimal) => {
            this.detail = {
              code: detail.shareCode,
              nickname: nickname || detail.currency,
              note: note,
              cover: cover,
              currency: detail.currency,
              nums: detail.nums,
              openNums: detail.openNums,
              money: detail.money,
              decimal: decimal,
            };
          });

          // console.log("sero:packageInfo ", res);
        })
        .catch(() => {
          this.$bvToast.toast(this.$t("home_get_error"), {
            title: this.$t("error"),
            toaster: "b-toaster-top-center",
            autoHideDelay: 3000,
            appendToast: false,
            variant: "danger",
          });
        });
    },
    goToSendPackage() {
      this.$router.push({ name: "Send" });
    },
    makeid(length) {
      var result = "";
      var characters =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
      var charactersLength = characters.length;
      for (var i = 0; i < length; i++) {
        result += characters.charAt(
          Math.floor(Math.random() * charactersLength)
        );
      }
      return result;
    },
    openRedpackage() {
      this.openAnimate = true;
      if (parseInt(this.detail.openNums) >= parseInt(this.detail.nums)) {
        setTimeout(() => {
          this.openError = this.$t("home_get_over");
          this.openAnimate = false;
        }, 1000);

        return;
      }

      this.executeMethod("grabPackage", [this.code, this.makeid(12)], 0, "SERO")
        .then((res) => {
          // console.log("sero:grabPackage ", res);
          if (!res) {
            this.openAnimate = false;
            alert(this.$t("send_tx_failed"));
            return;
          }
          //  跳转到交易状态查询页查询成功后，跳转到详情页
          this.$router.push({
            name: "Detail",
            query: {
              code: this.detail.code,
              currency: this.detail.currency,
              txhash: res,
              from: "grabPackage",
            },
          });
        })
        .catch(() => {
          this.openAnimate = false;
          this.openError = this.$t("home_get_error2");
        });
    },
  },
  created() {
    this.$root.changeNavTitle("");
  },
  data() {
    return {
      openAnimate: false,
      code: "",
      detail: {
        code: "",
        cover: "default",
        currency: "",
        nickname: "",
        note: "",
      },
      openError: "",
      showPackage: false,
    };
  },
};
</script>
<style>
#home {
  height: 100vh;
  display: flex;
  flex-direction: column;
}
#home .open-container {
  display: flex;
  flex-direction: column;
  flex: 1;
  justify-content: center;
}
#home .top {
  text-align: center;
}
#home .banner {
  margin-bottom: 8px;
  border-radius: 3px;
}
#home .logo {
  width: 69px;
}
#home .title {
  margin: 10px 0px;
  font-size: 20px;
}
#home .get {
  margin: 20px 0px 30px;
}
#home .send {
  text-align: center;
}
#home .open-error {
  /* display: none; */
  font-size: 12px;
}
#home .open-error.animate {
  display: block;
  font-size: 22px;
  transition: font-size 0.8s;
}
</style>
