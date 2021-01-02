import axios from "axios";
import seropp from "sero-pp";

const request = axios.create({
  baseURL: "", // url = base url + request url
  // withCredentials: true, // send cookies when cross-domain requests
  timeout: 10000, // request timeout
});

let rpcURL = "";

function getRPCURL(callback) {
  if (rpcURL) {
    callback(rpcURL);
    return;
  }

  seropp.getInfo((info) => {
    if (!info) {
      rpcURL = "https://sero-light-node.ririniannian.com/";
    } else {
      rpcURL = info.rpc;
    }
    callback(rpcURL);
  });
}

function seroRPC(method, params, callback) {
  getRPCURL((rpcURL) => {
    request
      .post(rpcURL, {
        id: 0,
        jsonrpc: "2.0",
        method: method,
        params: params,
      })
      .then((result) => {
        callback(result);
      });
  });
}

export { request, seroRPC };
