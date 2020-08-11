import serojs from "serojs";
import seropp from "sero-pp";
import Web3 from "sero-web3";
import ABI from "./abi.json";

var contractList = {
  v0: {
    version: "v0",
    address:
      "66u1LkDvEFXTWhEJMP3aDErAy8KvMv2GEcs1WrhTzjBbH9xExRgWufYXZnft1pp6noHEhGrgJ8yve74zJXhkPu8W",
  },
  latest: {
    address:
      "4sQ5g2wE4cGpbKanCRR9PUzc4BBN4EEea5yQb7x7b3kgAiF4BFmeujQbf1E6wN8C5TdCb8sPo6ocMgnZSeEnSvf5",
  },
};

var contractAddress =
  localStorage.getItem("contractAddress") || contractList.latest.address;

const contract = serojs.callContract(ABI, contractAddress);

var dapp;
if (location.hostname.indexOf("gitee") != -1) {
  dapp = {
    name: "SERO红包",
    contractAddress: contractAddress,
    github: "https://gitee.com/anonymous2020/sero-redpackage",
    author: "SERO",
    url: "https://anonymous2020.gitee.io/sero-redpackage/",
    logo:
      "https://anonymous2020.gitee.io/sero-redpackage/img/logo.77472dad.png",
  };
} else {
  dapp = {
    name: "Red Envelope",
    contractAddress: contractAddress,
    github: "https://github.com/catlscd/sero-redpackage",
    author: "SERO",
    url: "https://catlscd.github.io/sero-redpackage/",
    logo: "https://catlscd.github.io/sero-redpackage/img/logo.77472dad.png",
  };
}

var web3 = new Web3();

export default {
  contract: contract,
  app: null,
  web3: web3,
  pplang: "zh_CN",
  rpc: "http://127.0.0.1:8545",
  contractList: contractList,
  contractAddress: contractAddress,
  isLatestContract: function() {
    return this.contractAddress == contractList.latest.address;
  },
  setContractAddress(address) {
    localStorage.setItem("contractAddress", address);
    location.href = dapp.url;
    // location.href = "http://192.168.37.111:8080";
  },
  init(app) {
    this.app = app;
    return new Promise((resolve, reject) => {
      seropp.init(dapp, () => {
        seropp.getInfo((res) => {
          if (!res) {
            alert("获取 SERO 账号信息失败，请在 SERO 官方钱包打开此应用！");
            reject();
            return;
          }
          this.pplang = res.language;
          this.rpc = res.rpc;
          this.initWeb3();
        });

        seropp.getAccountList((accountList) => {
          app.accounts = accountList;

          this.initAccount(accountList);

          resolve(accountList);
          // console.log("sero:accountList ", accountList);
        });
      });
    });
  },
  initAccount(accounts) {
    let account = {};
    try {
      account = JSON.parse(localStorage.getItem("sero_account"));
    } catch (error) {
      alert(error);
    }

    if (!account) {
      this.saveAccount(accounts[0]);
      return;
    }
    this.app.account = account;
  },
  saveAccount(account) {
    let detail = {
      Name: account.Name,
      MainPKr: account.MainPKr,
      PK: account.PK,
    };
    localStorage.setItem("sero_account", JSON.stringify(detail));
    this.app.account = detail;
  },
  initWeb3() {
    web3.setProvider(new web3.providers.HttpProvider(this.rpc));
  },
  getTransactionReceipt(txhash) {
    return new Promise((resolve, reject) => {
      web3.sero.getTransactionReceipt(txhash, (error, res) => {
        if (error) {
          reject(error);
        } else {
          resolve(res);
        }
      });
    });
  },
  callMethod(_method, _args) {
    // console.log("sero:callMethod ", _method + "@" + JSON.stringify(_args));
    let packData = contract.packData(_method, _args);
    let callParams = {
      from: this.app.account.MainPKr,
      to: contractAddress,
      data: packData,
    };

    return new Promise((resolve, reject) => {
      seropp.call(callParams, function(callData) {
        if (callData !== "0x") {
          try {
            let res = contract.unPackData(_method, callData);
            resolve(res);
          } catch (err) {
            reject(err);
          }
        } else {
          reject("0x0");
        }
      });
    });
  },
  // 执行智能合约的方法（发送交易）
  executeMethod(_method, args, value, cy) {
    let packData = contract.packData(_method, args);
    let executeData = {
      from: this.app.account.PK,
      to: contractAddress,
      value: "0x" + value, //SERO
      data: packData,
      // gasPrice: "0x" + new BigNumber("1000000000").toString(16),
      gasPrice: "0x3b9aca00",
      cy: cy,
    };
    let estimateParam = {
      from: this.app.account.MainPKr,
      to: contractAddress,
      value: "0x" + value, //SERO
      data: packData,
      // gasPrice: "0x" + (3000000000).toString(16),
      gasPrice: "0x3b9aca00",
      cy: cy,
    };
    return new Promise((resolve, reject) => {
      seropp.estimateGas(estimateParam, function(gas, err) {
        if (err) {
          alert("estimateGas error:" + err);
          reject(err);
          return;
        }
        // console.log("sero:gas ", gas);
        executeData["gas"] = gas * 2;
        seropp.executeContract(executeData, function(res) {
          if (res == "0x") {
            reject("0x0");
            return;
          }
          resolve(res);
        });
      });
    });
  },
};
