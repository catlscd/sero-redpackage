import { seroRPC } from "./request";

let defaultDecimal = {
  SERO: 18,
  PFID: 18,
  SUSD: 18,
  CORAL: 18,
};

function getDecimalLocal(token) {
  var decimal = defaultDecimal[token];
  if (decimal != undefined) {
    return decimal;
  } else {
    return parseInt(localStorage.getItem("D_" + token));
  }
}

export function getDecimal(token, callback, err_callback) {
  let decimalLocal = getDecimalLocal(token);
  if (decimalLocal && callback) {
    return callback(decimalLocal);
  } else {
    // {"jsonrpc":"2.0","id":0,"error":{"code":-32000,"message":"DAnot exists!"}}
    // {"jsonrpc":"2.0","id":0,"result":"0x9"}
    seroRPC("sero_getDecimal", [token], function({ data: { error, result } }) {
      if (error) {
        if (err_callback) {
          err_callback(error);
        }
        return;
      }
      let decimal = parseInt(result, "16");
      // console.log("sero_getDecimal:" + decimal);
      localStorage.setItem("D_" + token, decimal);
      if (callback) {
        callback(decimal);
      }
    });
  }
}
export default {
  getDecimal,
};
