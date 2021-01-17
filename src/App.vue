<template>
  <div id="app">
    <b-container fluid id="nav" :class="{ 'nav-white': $root.navWhite }">
      <b-row align-h="between" align-x="center">
        <b-col cols="3" class="left">
          <b-icon
            v-if="navTitle"
            icon="chevron-left"
            class="back"
            @click="back()"
            variant="secondary"
          ></b-icon>
        </b-col>
        <b-col cols="6" class="navtitle">
          <span>{{ navTitle }}</span>
        </b-col>
        <b-col cols="3" style="text-align:right;">
          <b-dropdown right>
            <template v-slot:button-content>
              <b-icon
                class="navpeople"
                icon="person-circle"
                variant="secondary"
              ></b-icon>
            </template>
            <b-dropdown-item href="#/nickname">
              {{ $t("nickname") }}:&nbsp;
              <span class="nickname" v-if="$root.nickname">
                {{ $root.nickname }}
              </span>
              <span class="text-primary" v-else>
                {{ $t("not_set_nickname") }}
              </span>
            </b-dropdown-item>
            <b-dropdown-divider></b-dropdown-divider>
            <b-dropdown-item @click="changeAccount">
              {{ $t("wallet") }}:&nbsp;
              <div class="wallt">
                <span class="text-muted">{{ $root.account.Name }}</span>
                <b-link style="font-size:13px;">{{ $t("change") }}</b-link>
              </div>
              <div
                class="text-muted"
                style="font-size:13px;"
                v-if="$root.account.MainPKr"
              >
                {{ $root.account.MainPKr.substr(0, 5) }}.....{{
                  $root.account.MainPKr.substr(-5)
                }}
              </div>
            </b-dropdown-item>
            <b-dropdown-divider></b-dropdown-divider>
            <b-dropdown-item href="#/">{{ $t("home") }}</b-dropdown-item>
            <b-dropdown-item href="#/assets">
              {{ $t("assets") }}
            </b-dropdown-item>
            <b-dropdown-item href="#/send">
              {{ $t("send_red_envelope") }}
            </b-dropdown-item>
            <b-dropdown-item href="#/my-package">
              {{ $t("my_send_red_envelope") }}
            </b-dropdown-item>
            <b-dropdown-item href="#/list">
              {{ $t("my_open_red_envelope") }}
            </b-dropdown-item>
            <b-dropdown-item href="#/friends">
              {{ $t("my_friends") }}
            </b-dropdown-item>
            <!-- <b-dropdown-item href="#/custom-cover" v-if="$i18n.locale == 'zh'">
              红包封面定制
            </b-dropdown-item> -->
            <b-dropdown-item href="#/nickname">
              {{ $t("set_nickname") }}
            </b-dropdown-item>
            <b-dropdown-item href="#/about">{{ $t("about") }}</b-dropdown-item>
            <b-dropdown-divider></b-dropdown-divider>
            <b-dropdown-item href="" @click.stop.prevent="changeLang">
              {{ $t("lang") }}
            </b-dropdown-item>
          </b-dropdown>
        </b-col>
      </b-row>
    </b-container>
    <b-modal
      ref="lang-modal"
      id="lang-modal"
      content-class="lang-modal-content"
      size="sm"
      centered
      :hide-backdrop="false"
      hide-footer
      :title="$t('lang')"
    >
      <div class="d-block">
        <div class="lang-list">
          <div
            class="item"
            @click="saveLang(item)"
            v-for="item in lang"
            :key="item.locale"
          >
            <span>{{ item.lang }}</span>
            <div class="check">
              <b-icon
                icon="check-circle"
                v-if="item.locale == $i18n.locale"
              ></b-icon>
            </div>
          </div>
        </div>
      </div>
    </b-modal>

    <b-modal
      ref="wallet-modal"
      id="wallet-modal"
      content-class="wallet-modal-content"
      size="sm"
      centered
      :hide-backdrop="false"
      hide-footer
      :title="$t('select_wallet')"
    >
      <div class="d-block">
        <div class="wallt-list">
          <div
            class="wallt-item"
            v-for="item in $root.accounts"
            :key="item.Name"
            @click.stop.prevent="selectAccount(item)"
          >
            <div class="account">
              <p class="name">{{ item.Name }}</p>
              <p class="address text-muted">
                {{ item.MainPKr.substr(0, 5) }}.....{{
                  item.MainPKr.substr(-5)
                }}
              </p>
            </div>
            <div class="check">
              <b-icon
                icon="check-circle"
                v-if="item.MainPKr == $root.account.MainPKr"
              ></b-icon>
            </div>
          </div>
        </div>
      </div>
    </b-modal>
    <router-view v-if="isRouterAlive" />
  </div>
</template>
<script>
export default {
  methods: {
    changeLang() {
      this.$refs["lang-modal"].show();
    },
    saveLang(lang) {
      localStorage.setItem("locale", lang.locale);
      this.$i18n.locale = lang.locale;
      this.$refs["lang-modal"].hide();
      this.reload();
    },
    reload() {
      if (
        [
          "Home",
          "Assets",
          "MyPackage",
          "Friends",
          "List",
          "Nickname",
          // "Detail",
          // "SendResult",
          "Send",
        ].indexOf(this.$route.name) == -1
      ) {
        this.$router.replace({ name: "Home" });
        return;
      }
      this.isRouterAlive = false;
      this.$nextTick(() => (this.isRouterAlive = true));
    },
    changeAccount() {
      this.$refs["wallet-modal"].show();
    },
    selectAccount(account) {
      this.$contract.saveAccount(account);
      this.$refs["wallet-modal"].hide();
      setTimeout(() => {
        this.reload();
      }, 0);
    },
    back() {
      if (this.$root.navWhite) {
        this.$root.navWhite = false;
      }
      this.$router.go(-1);
    },
  },
  watch: {
    "$root.navTitle": function(n) {
      this.navTitle = n;
    },
  },
  data() {
    return {
      navTitle: this.$root.navTitle,
      isRouterAlive: true,
      lang: [
        { locale: "en", lang: "English" },
        { locale: "zh", lang: "简体中文" },
        { locale: "zh-hant", lang: "繁體中文" },
      ],
    };
  },
};
</script>

<style>
.b-toaster {
  top: 65px !important;
}
#app {
  /* font-family: Avenir, Helvetica, Arial, sans-serif; */
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  color: #2c3e50;
  min-height: 100vh;
}

#nav {
  padding: 10px;
  position: fixed;
  width: 100%;
  height: 65px;
  z-index: 9999;
  background: #fff;
}
#nav .wallt {
  display: flex;
  align-items: center;
  margin: 0px;
}
#nav .wallt span {
  max-width: 100px;
  overflow: hidden;
  display: inline-block;
  text-overflow: ellipsis;
  margin-right: 3px;
}
.page-content {
  padding-top: 65px;
}
#nav .left {
  display: flex;
  align-items: center;
}
#nav .navtitle {
  display: flex;
  justify-content: center;
  align-items: center;
  font-weight: bold;
}
#nav .navpeople {
  font-size: 30px;
}
#nav .dropdown-toggle {
  background: none;
  border: none;
  outline: none;
}
#nav .dropdown-toggle:focus {
  box-shadow: none;
}
#nav .dropdown-toggle::after {
  display: none;
}
.qa-item .content {
  padding-top: 8px;
}
.redpackage-dialog {
  position: fixed;
  top: 0px;
  left: 0px;
  right: 0px;
  width: 100%;
  bottom: 0px;
  background: rgba(0, 0, 0, 0.2);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 10002;
}
.redpackage-dialog .wrapper {
  background-color: #f66654;
  border-radius: 8px;
  width: 300px;
  height: 494.03px;
  position: relative;
  transform: scale(0);
}
.redpackage-dialog .wrapper.animate {
  transform: scale(1);
  transition: transform 0.5s;
}
.redpackage-default .wrapper {
  background: #f66654 url(./assets/cover-default.png) no-repeat;
  background-size: cover;
  color: #eed3a0;
}
.redpackage-default .wrapper .open {
  position: absolute;
  background: #eed3a0;
  border: none;
  width: 70px;
  height: 70px;
  line-height: 70px;
  border-radius: 50%;
  font-size: 30px;
  bottom: 62px;
  left: 115px;
  color: #404040;
  outline: none;
}
.redpackage-default .wrapper .open.animate {
  transform-style: preserve-3d;
  animation: rotate 2s linear infinite;
}
.redpackage-default .wrapper .open.en {
  font-size: 20px;
}
@keyframes rotate {
  0% {
    transform: rotateY(0deg);
  }
  100% {
    transform: rotateY(360deg);
  }
}

.redpackage-default .wrapper .top {
  position: absolute;
  top: 100px;
  width: 100%;
}
.redpackage-default .wrapper .author {
  display: flex;
  justify-content: center;
  padding: 5px 0px;
  align-items: center;
}
.redpackage-default .wrapper .author img {
  width: 22px;
  border-radius: 2px;
  margin-right: 5px;
}
.redpackage-default .wrapper .desc {
  font-size: 20px;
  padding: 0px 15px;
}
.redpackage-default .wrapper .view {
  color: #eed3a0;
  text-align: center;
  position: absolute;
  bottom: 26px;
  display: block;
  width: 100%;
}

/* .redpackage-cover-xxx .wrapper {
  background: #f66654 url(./assets/cover-xxx.png) no-repeat;
  background-size: cover;
} */

.nav-white .b-icon {
  color: #fff !important;
}
#nav.nav-white {
  color: #fff;
  background: none;
}
.icon-ping {
  background: #d09e48;
  color: #fff;
  font-size: 15px;
  /* width: 22px; */
  height: 22px;
  padding: 0px 4px;
  line-height: 22px;
  border-radius: 3px;
  margin-right: 3px;
}
#wallet-modal___BV_modal_outer_ {
  z-index: 10040 !important;
}
#wallet-modal .modal-content {
  margin: 0px 25px;
}
#wallet-modal .modal-body {
  max-height: 250px;
  overflow: scroll;
}
#wallet-modal .wallt-item,
.lang-list .item {
  border-bottom: 1px #eee solid;
  padding: 10px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
#wallet-modal .wallt-item:last-child {
  border-bottom: none;
}
#wallet-modal .wallt-item p {
  margin: 0px;
}
#wallet-modal .wallt-item .check,
.lang-list .item .check {
  color: #28a745 !important;
  font-size: 20px;
}
#lang-modal .item {
  padding: 15px 10px;
}
#lang-modal .item:last-child {
  border-bottom: none;
}
</style>
