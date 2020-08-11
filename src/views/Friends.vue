<template>
  <!-- 好友管理页面 -->
  <b-container id="friends" class="page-content">
    <b-modal
      id="add-friends-modal"
      ref="modal"
      :title="$t('add_friend')"
      @show="resetModal"
      @hidden="resetModal"
      @ok="handleModalOk"
      :ok-title="$t('add')"
      :cancel-title="$t('cancel')"
    >
      <form ref="form" @submit.stop.prevent="addFriends">
        <b-form-group
          :state="nameState"
          :label="$t('address')"
          label-for="address-input"
          :invalid-feedback="$t('add_friend_err1')"
        >
          <b-form-textarea
            id="address-input"
            v-model="friend.address"
            :state="nameState"
            :placeholder="$t('mainPKrTips')"
            required
          ></b-form-textarea>
        </b-form-group>

        <b-form-group
          :state="noteState"
          :label="$t('remark')"
          label-for="note-input"
          :invalid-feedback="$t('remark_tips')"
        >
          <b-form-input
            id="note-input"
            v-model="friend.note"
            :state="noteState"
            required
          ></b-form-input>
        </b-form-group>
      </form>
    </b-modal>
    <b-alert variant="success" :show="showSuccess">
      <b-icon icon="check-circle"></b-icon> {{ tips }}
    </b-alert>
    <div style="text-align:right;margin-top:10px;">
      <b-overlay
        :show="txStatus == '0x0'"
        rounded
        opacity="0.2"
        spinner-small
        spinner-variant="primary"
        class="d-inline-block"
      >
        <b-button variant="warning" size="sm" v-b-modal.add-friends-modal>
          {{ $t("add") }}
        </b-button>
      </b-overlay>
    </div>
    <ul>
      <li v-for="(item, index) in friends" :key="item.address">
        <p class="address">
          {{ item.address }}
        </p>
        <div class="name">
          <div>{{ item.note }}</div>
          <div class="action">
            <!-- <b-icon icon="trash"></b-icon> -->
            <b-button
              variant="link"
              size="sm"
              @click.stop.prevent="delFriend(item, index)"
            >
              {{ $t("delete") }}
            </b-button>
          </div>
        </div>
      </li>
    </ul>
  </b-container>
</template>
<script>
import { isStrictAddress } from "sero-web3/lib/utils/utils";

export default {
  created() {
    this.$root.changeNavTitle(this.$t("my_friends"));
    this.fetchFriends();
  },
  data() {
    return {
      friend: {
        address: "",
        note: "",
      },
      friends: [],
      name: "",
      nameState: null,
      noteState: null,
      // txStatus:null,
      txStatus: null,
      txhash: "",
      tips: "",
      showSuccess: false,
    };
  },
  methods: {
    delFriend(item, index) {
      index = this.friends.length - index - 1;
      this.executeMethod("delFriend", [item.address, index], 0, "SERO").then(
        (res) => {
          // console.log("sero:delFriend ", res);
          this.txhash = res;
          this.tips = this.$t("friend_del_success");
          this.queryTxStatus();
        }
      );
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
        } else {
          this.txStatus = null;
          this.txhash = null;
          this.fetchFriends();
          this.showSuccess = true;
          setTimeout(() => {
            this.showSuccess = false;
          }, 3000);
        }
      });
    },
    fetchFriends() {
      this.callMethod("getFriends", []).then(({ friendList }) => {
        // console.log("sero:getFriends ", friendList);
        friendList.reverse();
        let friends = [];
        for (let i = 0; i < friendList.length; i++) {
          const friend = friendList[i];
          let fullAddress = this.$contract.web3.sero.getFullAddress([
            friend.user,
          ])[friend.user.toLowerCase()];
          friends.push({
            address: fullAddress,
            note: friend.note,
          });
        }
        this.friends = friends;
      });
    },
    checkFormValidity() {
      const valid = this.$refs.form.checkValidity();
      let nameState = true,
        noteState = true;
      if (!valid) {
        nameState = false;
        noteState = false;
      }
      let address = this.friend.address.trim();
      if (!isStrictAddress(address)) {
        nameState = false;
      }

      this.nameState = nameState;
      this.noteState = noteState;
      return valid && nameState && noteState;
    },
    resetModal() {
      this.friend = {
        address: "",
        note: "",
      };
      this.nameState = null;
      this.noteState = null;
    },
    handleModalOk(bvModalEvt) {
      // Prevent modal from closing
      bvModalEvt.preventDefault();
      // Trigger submit handler
      this.handleSubmit();
    },
    handleSubmit() {
      if (!this.checkFormValidity()) {
        return;
      }

      // let address = this.getShortAddress(this.friend.address.trim());
      let address = this.friend.address.trim();
      this.executeMethod(
        "addFriend",
        [address, this.friend.note],
        0,
        "SERO"
      ).then((res) => {
        // console.log("sero:addFriend ", res);
        if (!res) {
          return;
        }
        this.txhash = res;
        this.txStatus = "0x0";
        this.tips = this.$t("friend_add_success");
        this.queryTxStatus();
      });
      this.$nextTick(() => {
        this.$bvModal.hide("add-friends-modal");
      });
    },
  },
};
</script>

<style>
#add-friends-modal {
  top: 70px;
}
#friends ul {
  padding: 0px;
  margin: 0px;
  list-style: none;
}
#friends ul .address {
  word-break: break-all;
  margin-bottom: 5px;
}
#friends ul .name {
  color: #6c757d;
  margin: 0px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}
#friends ul li {
  border-bottom: 1px #ccc dashed;
  padding: 15px 0px;
}
</style>
