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

var _sender = "0xe010ac6e0248790e08f42d5f697160dedf97e024";


module.exports =async function(callback) {
    let oracletoken;
    let proofofworktoken;

        oracletoken = await oracleToken.new(_sender,22,timeframe,[1,5,10,5,1]);
        console.log("oracletoken dud", oracletoken.address);
        proofofworktoken = await proofOfWorkToken.new();
        console.log("oracletoken dud", oracletoken.address);
        proofofworktoken.deployNewOracle("json(https://api.gdax.com/products/BTC-USD/ticker).price",22,timeframe,[1,5,10,5,1]);
        await proofofworktoken.setDudOracle(oracletoken.address);
        console.log("proposed dud");

}
