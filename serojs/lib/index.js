var contract = require('./abi/index');

var createContract = function (abi,data){
    var factory= new contract(abi,data);
    return  factory;
};

var callContract = function (abi,address) {
    var factory= new contract(abi);
    factory.at(address);
    return  factory;
};


module.exports = {
    createContract:createContract,
    callContract:callContract
};
