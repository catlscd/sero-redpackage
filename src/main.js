import BigNumber from "bignumber.js";
// import Vue from "vue";
import Vue from "./plugins/bootstrap-vue";
import App from "./App.vue";
import router from "./router";

import contract from "./contract";
import coder from "serojs/lib/abi/solidity/coder";

import MyImg from "./components/MyImg";

import i18n from "./i18n";

// import { BootstrapVue, IconsPlugin } from "bootstrap-vue/esm";
// import "bootstrap/dist/css/bootstrap.css";
// import "bootstrap-vue/dist/bootstrap-vue.css";
// Vue.use(BootstrapVue);
// Vue.use(IconsPlugin);

Vue.config.productionTip = false;

Vue.mixin({
  methods: {
    callMethod(_method, _args) {
      return contract.callMethod(_method, _args);
    },
    executeMethod(_method, args, value, cy) {
      return contract.executeMethod(_method, args, value, cy);
    },
    getTransactionReceipt(txhash) {
      return contract.getTransactionReceipt(txhash);
    },
    getShortAddress(MainPkr) {
      return "0x" + coder.encodeParams(["address"], [MainPkr]).substr(-40);
    },
  },
});

Vue.filter("formatDatetime", (t) => {
  let d = new Date();
  d.setTime(t * 1000);
  return (
    d.getFullYear() +
    "-" +
    (d.getMonth() + 1) +
    "-" +
    d.getDate() +
    " " +
    d.getHours() +
    ":" +
    d.getMinutes()
  );
});

Vue.filter("formatMoney", (value, decimals, replaceZero) => {
  var decimal = new BigNumber(10).pow(decimals),
    money = new BigNumber(value).div(decimal);
  if (money.comparedTo("0.0009") == 1) {
    money = money.toFixed(4, BigNumber.ROUND_DOWN);
  }
  if (replaceZero) {
    money = money.toString().replace(/\.?0+$/, "");
  }
  return money == "" ? 0 : money;
});

Vue.prototype.$contract = contract;

Vue.component("my-img", MyImg);

var vm = new Vue({
  router,
  i18n,
  watch: {
    account: function() {
      this.getNickname();
    },
  },
  methods: {
    changeNavTitle(title) {
      this.navTitle = title;
    },
    getNickname() {
      this.callMethod("getName", []).then(({ name }) => {
        localStorage.setItem("nickname", name);
        this.nickname = name;
      });
    },
  },
  mounted() {
    this.getNickname();
  },
  data: () => {
    return {
      accounts: [],
      account: {},
      nickname: "",
      navTitle: "",
      navWhite: false,
    };
  },
  render: (h) => h(App),
});
window.vm = vm;

contract.init(vm).then(() => {
  let locale = contract.pplang.split("_")[0];
  if (locale != "zh") {
    locale = "en";
  }
  let ls_locale = localStorage.getItem("locale");

  i18n.locale = ls_locale || locale;
  vm.$mount("#app");
});
