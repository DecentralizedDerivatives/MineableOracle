

const Web3 = require("web3");
const fs = require('fs');
const Tx = require('ethereumjs-tx')
const web3 = new Web3(new Web3.providers.HttpProvider("https://rinkeby.infura.io/zkGX3Vf8njIXiHEGRueB"));
var json = require('../build/contracts/OracleToken.json');

solution = process.argv[2]
value = process.argv[3] - 0


console.log('Nonce submitted: ',solution,'      ')
console.log('Value submitted: ',value,'              ')


  var address = process.argv[4];
  var abi = json.abi;
  var account = process.argv[5];
  var privateKey = new Buffer('fe5f52e7e0381448fe7d4a99e409b6da987b31362125ccb7bca781949cf61710', 'hex');
  web3.eth.getTransactionCount(account, function (err, nonce) {
    console.log(web3.toHex(solution))
    var data = web3.eth.contract(abi).at(address).proofOfWork.getData(web3.toHex(solution),value);
    console.log(data);
    //data = "0x42e0857f0000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000038400000000000000000000000000000000000000000000000000000000000000092733343132333431270000000000000000000000000000000000000000000000"
    var tx = new Tx({
      nonce: nonce,
      gasPrice: web3.toHex(web3.toWei('20', 'gwei')),
      gasLimit: 4000000,
      to: address,
      value: 0,
      data: data,
    });
    tx.sign(privateKey);

    var raw = '0x' + tx.serialize().toString('hex');
    web3.eth.sendRawTransaction(raw, function (err, transactionHash) {
       console.log(transactionHash);
    });
  });