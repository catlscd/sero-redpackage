<template>
  <b-container class="page-content" id="settings">
    <b-alert variant="success" :show="showSuccess">
      <b-icon icon="check-circle"></b-icon> {{ $t("nickname_ok") }}
    </b-alert>
    <b-overlay
      :show="txHash != ''"
      rounded
      opacity="0.6"
      spinner-small
      spinner-variant="primary"
      class="d-block"
      style="padding:10px;"
    >
      <template v-slot:overlay>
        <div class="text-center">
          <b-icon
            icon="arrow-counterclockwise"
            animation="spin-reverse-pulse"
          ></b-icon>
          {{ $t("nickname_setting") }}
        </div>
      </template>
      <b-form @submit="setName">
        <b-form-group :label="$t('nickname')">
          <b-form-input v-model="name"></b-form-input>
        </b-form-group>
        <div class="text-center" style="margin-top:35px;">
          <b-button type="submit" size="lg" variant="warning">
            {{ $t("save") }}
          </b-button>
        </div>
      </b-form>
    </b-overlay>
    <div class="qa-item" style="margin-top:25px">
      <strong class="title">
        {{ $t("tips") }}
      </strong>
      <div class="text-muted content">
        <p>
          {{ $t("tipsContent") }}
        </p>
      </div>
    </div>
    <p class="text-danger" v-if="$i18n.locale == 'zh'">
      <b>风险提示：</b>本应用发的其他Token红包跟此项目无任何关系，任何人都可以在
      SERO 链上以极低价格发行 Token！
    </p>
  </b-container>
</template>

<script>
export default {
  methods: {
    setName(evt) {
      evt.preventDefault();
      this.showSuccess = false;

      if (!this.name) {
        alert(this.$t("pls_input_nickname"));
        return false;
      }

      this.executeMethod("setName", [this.name], 0, "SERO").then((res) => {
        // console.log("sero:setName", res);
        this.txHash = res;
        this.queryTxStatus();
      });
      return false;
    },
    queryTxStatus() {
      if (!this.txHash) {
        return;
      }
      this.getTransactionReceipt(this.txHash).then((res) => {
        if (!res) {
          res = { status: "0x0" };
        }
        this.txStatus = res.status;
        if (res.status == "0x0") {
          setTimeout(this.queryTxStatus, 3000);
        } else {
          this.txHash = "";
          this.$root.getNickname();
          this.showSuccess = true;
        }
      });
    },
  },
  created() {
    this.$root.changeNavTitle(this.$t("nickname"));
    this.callMethod("getName", []).then(({ name }) => {
      this.name = name;
    });
  },
  data() {
    return {
      name: "",
      txHash: "",
      showSuccess: false,
    };
  },
};
</script>
