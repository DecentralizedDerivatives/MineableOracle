function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}

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
        await oraclevote.vote(1, true);
 /*       await oraclevote.tallyVotes(1)
        await oraclevote.propAdd("json(https://api.gdax.com/products/BTC-USD/ticker).price",22,timeframe,[1,5,10,5,1]);
        await oraclevote.vote(2, true);
        let res = await oraclevote.tallyVotes(2);
        res = res.logs[0].args._newOracle;
        oracletoken = await oracleToken.at(res);
        console.log("oracle token address:", oracletoken.address);*/
}
