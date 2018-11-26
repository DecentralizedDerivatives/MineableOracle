function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}
//truffle-flattener ./contracts/proofOfWorkToken.sol > ./flat_files/proofOfWorkToken_flat.sol
// truffle exec scripts/DeployOracleandOracleVote.js --network rinkeby


var oracleToken = artifacts.require("OracleToken");
var proofOfWorkToken = artifacts.require("ProofOfWorkToken");
//var timeframe = (86400/60)/6; //10mins
var timeframe = (86400); //Daily
var api = 'json(https://api.gdax.com/products/BTC-USD/ticker).price';
var api2 = 'json(https://api.gdax.com/products/ETH-USD/ticker).price';

var _sender = "0xe010ac6e0248790e08f42d5f697160dedf97e024";


module.exports =async function(callback) {
    let oracletoken;
    let proofofworktoken;

        oracletoken = await oracleToken.new(_sender,22,timeframe,[1,5,10,5,1]);
        console.log("oracletoken dud", oracletoken.address);
        proofofworktoken = await proofOfWorkToken.new();
        console.log("oracletoken dud", proofofworktoken.address);
        await proofofworktoken.setDudOracle(oracletoken.address);
        let res = await proofofworktoken.deployNewOracle(api,22,timeframe,[1,5,10,5,1]);
        res = res.logs[0].args._newOracle;
        console.log("oracle1:", api,":", res.address);
        let res2 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1]);
        res2 = res2.logs[0].args._newOracle;
        console.log("oracle2:", api2,":", res2.address);
}