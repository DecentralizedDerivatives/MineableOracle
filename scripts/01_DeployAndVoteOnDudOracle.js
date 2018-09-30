function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}
//truffle-flattener ./contracts/OracleVote.sol > ./flat_files/OracleVote_flat.sol
// truffle exec scripts/DeployOracleandOracleVote.js --network rinkeby


var oracleToken = artifacts.require("OracleToken");
var oracleVote = artifacts.require("OracleVote");
//var timeframe = (86400/60)/6; //10mins
var timeframe = (86400); //Daily
var _sender = "0xe010ac6e0248790e08f42d5f697160dedf97e024";


module.exports =async function(callback) {
    let oracletoken;
    let oraclevote;

        oraclevote = await oracleVote.new(22,1,1);
        console.log("oraclevote", oraclevote.address);
        oracletoken = await oracleToken.new(_sender,22,timeframe,[1,5,10,5,1]);
        console.log("oracletoken dud", oracletoken.address);
        await oraclevote.propDudOracle(oracletoken.address);
        console.log("proposed dud");
        await oraclevote.vote(1, true);
        console.log("voted");

}
