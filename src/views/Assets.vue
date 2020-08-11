<template>
  <b-container class="page-content" id="my-assets">
    <b-overlay :show="loadding" no-wrap> </b-overlay>
    <b-modal
      id="withdrawModal"
      ref="modal"
      :title="$t('withdraw')"
      :ok-title="$t('withdraw')"
      :cancel-title="$t('cancel')"
      @show="resetModal"
      @hidden="resetModal"
      @ok="handleOk"
    >
      <form ref="form" @submit.stop.prevent="handleSubmit">
        <b-form-group :label="$t('balance')">
          <b-form-input readonly :value="withdrawInfo.balance"></b-form-input>
          <b-form-text
            class="link"
            text-variant="secondary"
            @click="withdrawInfo.amount = withdrawInfo.balance"
          >
            {{ $t("withdraw_all") }}
          </b-form-text>
        </b-form-group>
        <b-form-group
          :state="withdrawAmountState"
          :label="$t('withdrawal_amount')"
          :invalid-feedback="withdrawAmountTips"
        >
          <b-input-group :append="currentToken.currency">
            <b-form-input
              v-model="withdrawInfo.amount"
              :state="withdrawAmountState"
              required
            ></b-form-input>
          </b-input-group>
          <b-form-text>
            {{ $t("fees") }}:&nbsp;
            {{ currentToken.fees | formatMoney(currentToken.decimals, true)
            }}{{ currentToken.currency }}
            <span v-if="currentToken.currency != 'SERO'">
              + {{ tokenSeroFee | formatMoney(18, true) }}SERO
            </span>
            <span v-if="withdrawInfo.realAmount" style="margin-left:10px">
              &nbsp;&nbsp;{{ $t("actual_amount_received") }}&nbsp;
              {{ withdrawInfo.realAmount }}
              {{ currentToken.currency }}
            </span>
          </b-form-text>
        </b-form-group>
      </form>
    </b-modal>
    <!-- 
    <b-modal
      id="rechargeModal"
      ref="recharge-modal"
      title="充值"
      ok-title="充值"
      cancel-title="取消"
      @show="resetRechargeModal"
      @hidden="resetRechargeModal"
      @ok="rechargeSubmit"
    >
      <form @submit.stop.prevent="rechargeSubmit">
        <b-form-group label="余额">
          <b-form-input readonly :value="rechargeInfo.balance"></b-form-input>
        </b-form-group>
        <b-form-group
          :state="rechargeAmountState"
          label="充值金额"
          :invalid-feedback="rechargeAmountTips"
        >
          <b-input-group :append="currentToken.currency">
            <b-form-input
              type="number"
              v-model="rechargeInfo.amount"
              :state="rechargeAmountState"
              required
            ></b-form-input>
          </b-input-group>
        </b-form-group>
      </form>
    </b-modal> -->

    <b-alert show variant="secondary" v-if="txHash != ''">
      {{ $t("tx_submit_success") }}
      <b-overlay
        :show="txStatus == '0x0'"
        rounded
        opacity="0.2"
        spinner-small
        spinner-variant="primary"
        class="d-inline-block"
      >
        <b-badge variant="warning" v-if="txStatus == '0x0'">
          {{ $t("confirming") }}
        </b-badge>
      </b-overlay>
    </b-alert>
    <p class="text-right" v-if="$i18n.locale == 'zh'">
      <a
        href=""
        @click.stop.prevent="changeContract()"
        style="color:#ccc;font-size:12px;"
      >
        {{ changeContractTips }}
      </a>
    </p>

    <b-card-group v-if="tokens['SERO'] && tokens['SERO']['currency']">
      <b-card
        header-tag="header"
        footer-tag="footer"
        v-for="item in balances"
        :key="item.currency"
      >
        <template v-slot:header>
          <h6 class="mb-0 header">
            <my-img
              :src="'img/token-' + item.currency.toLowerCase() + '.png'"
              class="token-logo img-fluid"
              default-img="img/token-sero.png"
            ></my-img>
            {{ item.currency }}
          </h6>
        </template>

        <b-card-text>
          <div>
            {{ $t("balance") }}：
            <b class="text-secondary">
              {{
                item.balance | formatMoney(tokens[item.currency].decimals, true)
              }}
            </b>
            {{ item.currency }}
          </div>
          <div>
            <span v-html="$t('open_nums').replace('{nums}', item.getNums)">
            </span
            >, &nbsp; {{ $t("total") }}: &nbsp;
            <b class="text-secondary">
              {{ item.get | formatMoney(tokens[item.currency].decimals, true) }}
            </b>
            {{ item.currency }}
          </div>
          <div>
            <span v-html="$t('send_nums').replace('{nums}', item.sendNums)">
            </span
            >, &nbsp; {{ $t("total") }}: &nbsp;
            <b class="text-secondary">
              {{
                item.send | formatMoney(tokens[item.currency].decimals, true)
              }}
            </b>
            {{ item.currency }}
          </div>
        </b-card-text>

        <template v-slot:footer>
          <div class="tips text-muted">
            <p>
              {{ $t("fees") }}
              {{
                tokens[item.currency].fees
                  | formatMoney(tokens[item.currency].decimals, true)
              }}{{ item.currency }}
              <span v-if="item.currency != 'SERO'">
                + {{ tokenSeroFee | formatMoney(18, true) }}SERO
              </span>
            </p>
            <p>
              {{ $t("min_withdrawal_amount") }}:&nbsp;{{
                tokens[item.currency].minWithdrawAmount
                  | formatMoney(tokens[item.currency].decimals, true)
              }}{{ item.currency }}
            </p>
          </div>
          <div class="action">
            <!-- <b-button
              href="#"
              variant="success"
              size="sm"
              v-if="item.currency == 'SERO' && false"
              @click.prevent.stop="recharge(item)"
            >
              充值
            </b-button> -->
            <b-button
              href="#"
              class="withdraw"
              variant="warning"
              size="sm"
              @click.prevent.stop="withdraw(item)"
            >
              {{ $t("withdraw") }}
            </b-button>
          </div>
        </template>
      </b-card>
    </b-card-group>
  </b-container>
</template>
<script>
import BigNumber from "bignumber.js";
export default {
  methods: {
    changeContract() {
      if (
        !confirm(
          "点击“确定”切换到历史版本（提取历史版本资产），如果你不知道这是什么，请点击取消！"
        )
      ) {
        return;
      }
      let address = this.$contract.contractList.latest.address;
      if (this.$contract.isLatestContract()) {
        address = this.$contract.contractList.v0.address;
      }

      this.$contract.setContractAddress(address);
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
          this.fetchAssets();
        }
      });
    },
    checkFormValidity() {
      let valid = this.$refs.form.checkValidity(),
        unit = new BigNumber(10).pow(this.currentToken.decimals);

      if (
        new BigNumber(this.withdrawInfo.amount)
          .times(unit)
          .comparedTo(this.currentToken.minWithdrawAmount) == -1
      ) {
        valid = false;
        this.withdrawAmountTips =
          this.$t("min_withdrawal_amount") +
          " " +
          new BigNumber(this.currentToken.minWithdrawAmount).div(unit) +
          this.currentToken.currency;
      }
      if (new BigNumber(this.withdrawInfo.realAmount).comparedTo(0) != 1) {
        valid = false;
        this.withdrawAmountTips = this.$t("assets_withdrawal_tips1");
      }
      //检查余额
      if (
        new BigNumber(this.withdrawInfo.amount)
          .times(unit)
          .comparedTo(this.clickToken.balance) == 1
      ) {
        valid = false;
        this.withdrawAmountTips = this.$t("insufficient_balance");
      }

      if (valid) {
        this.withdrawAmountTips = "";
      }
      this.withdrawAmountState = valid;
      return valid;
    },
    resetModal() {
      this.withdrawInfo.amount = "";
      this.withdrawAmountState = null;
      this.withdrawAmountTips = this.$t("assets_withdrawal_tips2");
    },
    resetRechargeModal() {
      this.rechargeInfo.amount = "";
      this.rechargeAmountState = null;
      this.rechargeAmountTips = this.$t("assets_withdrawal_tips2");
    },

    handleOk(bvModalEvt) {
      // Prevent modal from closing
      bvModalEvt.preventDefault();
      // Trigger submit handler
      this.handleSubmit();
    },
    handleSubmit() {
      // Exit when the form isn't valid
      if (!this.checkFormValidity()) {
        return;
      }
      let params = [
        this.currentToken.currency,
        new BigNumber(this.withdrawInfo.amount)
          .times(new BigNumber(10).pow(this.currentToken.decimals))
          .toString(),
      ];

      // console.log(
      //   "sero:withdrawparams ",
      //   params,
      //   new BigNumber(this.tokenSeroFee).toString(16)
      // );

      let fee = this.tokenSeroFee;
      if (this.currentToken.currency == "SERO") {
        fee = 0;
      }

      this.executeMethod(
        "withdraw",
        params,
        new BigNumber(fee).toString(16),
        "SERO"
      ).then((res) => {
        this.txHash = res;
        // console.log("sero:withdraw ", res);
      });
      // Hide the modal manually
      this.$nextTick(() => {
        this.$bvModal.hide("withdrawModal");
      });
    },
    rechargeSubmit(e) {
      e.preventDefault();
      var amount = new BigNumber(this.rechargeInfo.amount);
      if (amount.comparedTo(0) != 1) {
        this.rechargeAmountState = false;
        this.rechargeAmountTips = "充值金额不正确";
        return;
      }
      this.rechargeAmountState = true;

      amount = amount
        .times(new BigNumber(10).pow(this.currentToken.decimals))
        .toString(16);
      this.executeMethod(
        "recharge",
        [],
        amount,
        this.currentToken.currency
      ).then((res) => {
        this.txHash = res;
        console.log("sero:recharge ", res);
        this.$nextTick(() => {
          this.$bvModal.hide("rechargeModal");
        });
      });
    },
    recharge(token) {
      this.clickToken = token;
      this.currentToken = this.tokens[token.currency];
      this.rechargeInfo.balance = new BigNumber(token.balance)
        .div(new BigNumber(10).pow(this.currentToken.decimals))
        .toString();
      this.$bvModal.show("rechargeModal");
    },
    withdraw(token) {
      this.clickToken = token;
      this.currentToken = this.tokens[token.currency];
      // if (
      //   token.currency != "SERO" &&
      //   this.balanceMap["SERO"].balance < this.tokenSeroFee
      // ) {
      //   this.$bvToast.toast(`SERO余额不足`, {
      //     title: "提示",
      //     toaster: "b-toaster-top-center",
      //     autoHideDelay: 3000,
      //     appendToast: false,
      //     variant: "danger",
      //   });
      //   return false;
      // }
      // 检查余额是否够
      if (
        parseInt(token.balance) < parseInt(this.currentToken.minWithdrawAmount)
      ) {
        var minWithdrawAmount = new BigNumber(
            this.currentToken.minWithdrawAmount
          ).div(10 ** this.currentToken.decimals),
          currency = this.currentToken.currency;
        this.$bvToast.toast(
          this.$t("insufficient_balance") +
            ", " +
            this.$t("min_withdrawal_amount") +
            ` ${minWithdrawAmount}${currency}`,
          {
            title: this.$t("tips"),
            toaster: "b-toaster-top-center",
            autoHideDelay: 3000,
            appendToast: false,
            variant: "danger",
          }
        );
        return false;
      }

      this.withdrawInfo.balance = new BigNumber(token.balance)
        .div(new BigNumber(10).pow(this.currentToken.decimals))
        .toString();
      // console.log(JSON.stringify(token));
      this.$bvModal.show("withdrawModal");
    },
    fetchTokens() {
      this.callMethod("tokenList", []).then(({ result }) => {
        for (let i = 0; i < result.length; i++) {
          const item = result[i];
          this.tokens[item.currency] = {
            currency: item.currency,
            decimals: item.decimals,
            fees: item.fees,
            minSendAmount: item.minSendAmount,
            minWithdrawAmount: item.minWithdrawAmount,
            weight: item.weight,
          };
        }
      });
    },
    fetchAssets() {
      this.callMethod("userBalances", []).then(
        ({ tokenSeroFee, currencyList, balancesList }) => {
          this.loadding = false;
          this.tokenSeroFee = tokenSeroFee;
          // console.log("sero:userBalances  ", currencyList, balancesList);
          let balances = [],
            balanceMap = {};
          for (let i = 0; i < currencyList.length; i++) {
            const info = balancesList[i];
            let item = {
              balance: info.balance,
              get: info.get,
              getMax: info.getMax,
              getNums: info.getNums,
              send: info.send,
              sendNums: info.sendNums,
              currency: currencyList[i],
              weight:
                currencyList[i] == "SERO" ? 99999 : parseInt(info.getNums),
            };
            balances.push(item);
            balanceMap[currencyList[i]] = item;
          }
          if (!balanceMap["SERO"]) {
            let item = {
              balance: 0,
              get: 0,
              getMax: 0,
              getNums: 0,
              send: 0,
              sendNums: 0,
              currency: "SERO",
              weight: 99999,
            };
            balances.unshift(item);
            balanceMap["SERO"] = item;
          }
          balances.sort((a, b) => {
            return b.weight - a.weight;
          });
          this.balances = balances;
          this.balanceMap = balanceMap;
        }
      );
    },
  },
  watch: {
    txHash: function() {
      this.queryTxStatus();
    },
    "withdrawInfo.amount": function(n) {
      if (!n) {
        this.withdrawInfo.realAmount = "";
        return;
      }
      // console.log(this.currentToken, this.currentToken.fees / 100);
      var unit = new BigNumber(10).pow(this.currentToken.decimals);
      this.withdrawInfo.realAmount = new BigNumber(n)
        .times(unit)
        .minus(this.currentToken.fees)
        .div(unit);
    },
  },
  created() {
    this.$root.changeNavTitle(this.$t("assets"));
    this.fetchTokens();
    this.fetchAssets();
    // console.log(this);
  },
  data() {
    return {
      loadding: true,
      changeContractTips: this.$contract.isLatestContract()
        ? "历史版本"
        : "最新版本",
      withdrawAmountState: null,
      withdrawAmountTips: this.$t("assets_withdrawal_tips2"),
      rechargeAmountState: null,
      rechargeAmountTips: "必须输入充值金额",
      currentToken: {},
      clickToken: {},
      txStatus: "0x0",
      txHash: "",
      withdrawInfo: {
        currency: "",
        amount: "",
        realAmount: "",
        balance: 0,
      },
      rechargeInfo: {
        currency: "",
        amount: "",
        realAmount: "",
        balance: 0,
      },
      tokens: { SERO: {} },
      tokenSeroFee: 1e16,
      balances: [],
      balanceMap: {},
    };
  },
};
</script>
<style>
#my-assets .header {
  display: flex;
  align-items: center;
}
#my-assets .token-logo {
  width: 25px;
  margin-right: 5px;
}
#my-assets .card-footer p {
  margin-bottom: 0px;
  font-size: 12px;
}
#my-assets .card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
#my-assets .card-footer .withdraw {
  margin-left: 5px;
}
#withdrawModal___BV_modal_outer_,
#rechargeModal___BV_modal_outer_ {
  z-index: 100090 !important;
}
</style>
