<template>
  <!-- 发红包结果页 -->
  <b-container id="send-result" class="page-content">
    <div v-if="txhash">
      <b-alert variant="success" show>
        {{ $t("send_success_tips") }}
      </b-alert>

      <p>
        {{ $t("tx_status_label") }}
        <b-overlay
          :show="txStatus == '0x0'"
          rounded
          opacity="0.2"
          spinner-small
          spinner-variant="primary"
          class="d-inline-block"
        >
          <b-badge variant="warning" v-if="txStatus == '0x0'">{{
            $t("confirming")
          }}</b-badge>
        </b-overlay>
        <b-badge variant="success" v-if="txStatus == '0x1'">{{
          $t("confirmed")
        }}</b-badge>
      </p>
      <p class="alert alert-warning" v-if="txStatus == '0x0'">
        {{ $t("send_result_tips1") }}
      </p>
      <div
        class="text-center"
        v-if="txStatus == '0x1'"
        style="padding-top:20px;"
      >
        <b-button
          variant="danger"
          size="sm"
          @click.prevent.stop="goMyPackage()"
        >
          {{ $t("view_my_sent") }}
        </b-button>
      </div>
    </div>
    <div v-if="code">
      <p>
        <b>{{ $t("copy_tips1") }}</b>
      </p>
      <p class="text-muted" style="font-size:13px">
        {{ $t("copy_tips2") }}
      </p>
      <b-form>
        <b-form-group>
          <b-form-textarea
            id="share-content"
            v-model="shareText"
            rows="11"
          ></b-form-textarea>
          <p
            class="text-muted"
            style="padding-top:8px;"
            v-if="!$root.nickname && $i18n.locale == 'zh'"
            @click="goNickname()"
          >
            你还没有设置昵称，请注意修改最前面的用户昵称！
            <span class="text-primary">
              立即设置昵称
            </span>
          </p>
        </b-form-group>
      </b-form>
      <div class="text-center" style="padding-top:20px;">
        <b-button id="copy2clipboard" data-clipboard-target="#share-content">
          {{ $t("copy_content") }}
        </b-button>
        <b-tooltip target="copy2clipboard" triggers="click">
          {{ $t("copy_success") }}
        </b-tooltip>
      </div>
    </div>
  </b-container>
</template>
<script>
import ClipboardJS from "clipboard";
export default {
  methods: {
    goNickname() {
      this.$router.push({ name: "Nickname" });
    },
    goMyPackage() {
      this.$router.push({ name: "MyPackage" });
    },
    buildShareText() {
      let currency = this.$route.query.currency,
        code = this.$route.query.code;
      if (!code) {
        return;
      }

      this.shareText = this.shareText
        .replace(
          "{nickname}",
          this.$root.nickname || (this.$i18n.locale == "zh" ? "我" : "")
        )
        .replace("{code}", code)
        .replace("{currency}", currency);
      this.code = code;
    },
    queryTxStatus() {
      if (!this.txhash) {
        return;
      }
      this.getTransactionReceipt(this.txhash).then((res) => {
        if (!res) {
          res = { status: "0x0" };
        }
        this.txStatus = res.status;
        if (res.status == "0x0") {
          setTimeout(this.queryTxStatus, 3000);
        }
      });
    },
  },
  created() {
    this.$root.changeNavTitle(this.$t("send_red_envelope"));
    new ClipboardJS(".btn");
    this.buildShareText();

    this.queryTxStatus();
  },
  data() {
    return {
      code: "",
      timedown: 3,
      txhash: this.$route.query.txhash,
      txStatus: "0x0",
      shareText: this.$t("share_content"),
    };
  },
};
</script>
