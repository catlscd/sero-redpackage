<template>
  <!-- 我抢的红包 -->
  <b-container id="my-list" class="page-content">
    <b-overlay :show="loadding" no-wrap> </b-overlay>
    <b-alert
      variant="warning"
      :show="true"
      v-if="!loadding && !openPackages.length"
    >
      {{ $t("not_get_any") }}
    </b-alert>
    <div class="list" v-else>
      <div
        class="item"
        v-for="(item, index) in openPackages"
        :key="index"
        @click="goDetail(item)"
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
                $t("red_envelope_from2").replace(
                  "{nickname}",
                  item.nickname || item.currency
                )
              }}
            </div>
            <div class="money">
              {{ $t("total") }}
              {{ item.money | formatMoney(item.decimals, true) }}
              {{ item.currency }}
            </div>
          </div>
          <div class="meta">
            <div class="time">{{ item.created | formatDatetime }}</div>
            <div class="tool">
              {{ $t("get") }}
              {{ item.getMoney | formatMoney(item.decimals, true) }}
              {{ item.currency }}
            </div>
          </div>
        </div>
      </div>
    </div>
  </b-container>
</template>
<script>
export default {
  methods: {
    goDetail(item) {
      this.$router.push({
        name: "Detail",
        query: {
          code: item.shareCode,
          currency: item.currency,
          txhash: item.txhash,
        },
      });
    },
    fetchMyOpenPackage() {
      this.loadding = true;
      this.callMethod("myOpenPackageList", [0, 50]).then(
        ({ total, openPackages }) => {
          if (total > 0) {
            this.$root.changeNavTitle(
              this.$t("my_open_red_envelope") + `(${total})`
            );
          }
          // console.log("sero:myOpenPackageList ", total, openPackages);
          this.openPackages = openPackages;
          this.loadding = false;
        }
      );
    },
  },
  created() {
    this.$root.changeNavTitle(this.$t("my_open_red_envelope"));
    this.fetchMyOpenPackage();
  },
  data() {
    return {
      openPackages: [],
      loadding: true,
    };
  },
};
</script>
<style>
#my-list .list {
  border-bottom: 1px #eee solid;
}
#my-list .list .item {
  display: flex;
  border-top: 1px #eee solid;
  padding: 15px 0px;
}
#my-list .list .item .logo {
  width: 38px;
  padding-right: 15px;
  border-radius: 5px;
}
#my-list .list .item .info {
  display: flex;
  flex: 1;
  justify-content: space-between;
  flex-direction: column;
}
#my-list .list .item .info > div {
  display: flex;
  justify-content: space-between;
  align-items: center;
}
#my-list .list .item .info .detail {
  color: #282828;
  font-size: 16px;
}
#my-list .list .item .info .detail .nums {
  max-width: 150px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
#my-list .list .item .info .detail .money {
  min-width: 100px;
}
#my-list .list .item .info .time {
  color: #cbcbcb;
  font-size: 14px;
}
#my-list .list .item .info .tool {
  color: #28a745;
}
</style>
