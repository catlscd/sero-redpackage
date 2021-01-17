<template>
  <b-container
    id="about"
    class="page-content"
    style="text-align:left;"
    @click.stop.prevent="addTokenShow()"
  >
    <div v-html="$t('about_content')"></div>

    <p class="text-danger" v-if="$i18n.locale == 'zh'">
      <b>风险提示：</b>本应用发的其他Token红包跟此项目无任何关系，任何人都可以在
      SERO 链上以极低价格发行 Token！
    </p>

    <div v-if="showAddToken">
      <b-form>
        <b-form-group label="Token" description="如：SERO">
          <b-form-input v-model="token.currency"></b-form-input>
        </b-form-group>
        <b-form-group label="小数点位数">
          <b-form-input v-model="token.decimals" type="number"></b-form-input>
        </b-form-group>
        <b-form-group
          label="手续费"
          description="扣除多少个 token，如 1e18  表示1SERO"
        >
          <b-form-input v-model="token.fees" type="number"></b-form-input>
        </b-form-group>
        <b-form-group label="最小提币数量" description="如：1e18 表示1SERO">
          <b-form-input
            v-model="token.minWithdrawAmount"
            type="number"
          ></b-form-input>
        </b-form-group>
        <b-form-group label="最小红包额" description="如：1e18 表示1SERO">
          <b-form-input
            v-model="token.minSendAmount"
            type="number"
          ></b-form-input>
        </b-form-group>
        <b-form-group label="排序" description="越大越靠前">
          <b-form-input v-model="token.weight" type="number"></b-form-input>
        </b-form-group>
        <b-button type="submit" size="sm" variant="primary" @click="addToken">
          添加 Token
        </b-button>
      </b-form>
      <hr />
      <!-- <b-button variant="primary" size="sm" @click="getSalt()">
        获取salt
      </b-button>
      &nbsp;&nbsp; -->
      <b-button variant="primary" size="sm" @click="getOwner()">
        获取owner
      </b-button>
      &nbsp;&nbsp;
      <b-button variant="primary" size="sm" @click="setSeroFee()">
        setSeroFee
      </b-button>
      &nbsp;&nbsp;
      <b-button variant="primary" size="sm" @click="balanceOf()">
        合约余额
      </b-button>
      <hr />
    </div>
  </b-container>
</template>
<script>
import BigNumber from "bignumber.js";
import { getDecimal } from "@/common/utils";
export default {
  methods: {
    balanceOf() {
      let input = prompt("请输入货币，例如：SERO", "SERO");
      input = input.trim();
      if (!input) {
        return;
      }
      let currency = input;
      this.callMethod("balanceOf", [currency], 0, "SERO").then((res) => {
        getDecimal(currency, (decimal) => {
          alert(
            new BigNumber(res.amount).div(10 ** decimal).toString() +
              currency +
              "." +
              decimal
          );
        });
      });
    },
    setSeroFee() {
      let fee = prompt("请输入 Token SERO 手续费，例如：1e17 表示 0.1SERO");
      if (fee == null) {
        return;
      }
      fee = new BigNumber(fee).toString();
      if (isNaN(fee)) {
        alert("请输入正确的数字");
        return;
      }
      this.executeMethod("setSeroFee", [fee], 0, "SERO").then(() => {});
    },
    getSalt() {
      this.callMethod("getSalt", []).then((salt) => {
        alert(JSON.stringify(salt));
      });
    },
    getOwner() {
      this.callMethod("owner", []).then((salt) => {
        let fullAddress = this.$contract.web3.sero.getFullAddress([salt[0]]);
        alert(fullAddress[salt[0].toLowerCase()]);
      });
    },
    addTokenShow() {
      this.i += 1;
      if (this.i >= 5) {
        this.showAddToken = true;
      }
    },
    addToken() {
      let params = [
        this.token.decimals,
        this.token.weight,
        new BigNumber(this.token.fees).toString(),
        new BigNumber(this.token.minWithdrawAmount).toString(),
        new BigNumber(this.token.minSendAmount).toString(),
        this.token.currency,
      ];
      console.log("sero:addToken ", params);

      this.executeMethod("addToken", params, 0, "SERO").then((res) => {
        console.log("sero:addToken ", res);
      });
      return false;
    },
  },
  created() {
    this.$root.changeNavTitle(this.$t("about"));

    // this.callMethod("balanceOf", ["SERO"]).then((res) => {
    //   console.log("sero:balanceOf ", res.amount / 1e18);
    // });
  },
  data() {
    return {
      i: 0,
      token: {
        currency: "",
        decimals: 18,
        fees: "1e17",
        weight: 0,
        minWithdrawAmount: "1e17",
        minSendAmount: "1e17",
      },
      showAddToken: false,
    };
  },
};
</script>
