function sleep_s(secs) {
  secs = (+new Date) + secs * 1000;
  while ((+new Date) < secs);
}
//truffle-flattener ./contracts/OracleVote.sol > ./flat_files/OracleVote_flat.sol
// truffle exec scripts/DeployOracleandOracleVote.js --network rinkeby


var oracleToken = artifacts.require("OracleToken");
var oracleVote = artifacts.require("OracleVote");
var timeframe2 = (86400/60)/6; //10mins
var timeframe = (86400); //Daily
//var _sender = "0xe010ac6e0248790e08f42d5f697160dedf97e024";
var _oraclevote = "0xbdfc820b1450dea533d23d9a30ee4b2c323c3586";
//oraclevote 0xbdfc820b1450dea533d23d9a30ee4b2c323c3586
//oracletoken dud 0x2e5f0945ce0bbe87601484fbcf7f5b6665e9484a


module.exports =async function(callback) {
    let oraclevote;
        oraclevote = await oracleVote.at(_oraclevote);
        await oraclevote.tallyVotes(1);
        console.log("tallyVotes");
        await oraclevote.propAdd("json(https://api.gdax.com/products/BTC-USD/ticker).price",22,timeframe,[1,5,10,5,1]);
        console.log("propose add btc daily");
        await oraclevote.vote(2, true);
        console.log("vote2");
        await oraclevote.propAdd("json(https://api.gdax.com/products/BTC-USD/ticker).price",22,timeframe2,[1,5,10,5,1]);
        console.log("propose add btc 10min");
        await oraclevote.vote(3, true);
        console.log("vote3");
/*        let res = await oraclevote.tallyVotes(2);
        res = res.logs[0].args._newOracle;
        console.log("get new oracle address daily", res);
        oracletoken = await oracleToken.at(res);
        console.log("oracle token address daily:", oracletoken.address);
        let res2 = await oraclevote.tallyVotes(3);
        res2 = res2.logs[0].args._newOracle;
        console.log("get new oracle address 10 min", res);
        oracletoken2 = await oracleToken.at(res2);
        console.log("oracle token address 10 min:", oracletoken2.address);*/
}