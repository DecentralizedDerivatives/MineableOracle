/** 
* This contract tests the Oracle functions
*/ 
const Web3 = require("web3"); // import web3 v1.0 constructor
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:9545"));
const BN = require('bn.js');
//const BN = require('BN.js').BN;
//const BigNumber = web3.utils.BN;
//var test = new BN(10e18);
//console.log("test", test);
//const BN = web3.utils.BN;
const ethers = require('ethers');

const Oracle = artifacts.require("./Oracle.sol"); // globally injected artifacts helper
var oracleAbi = Oracle.abi;
var oracleByte = Oracle.bytecode;

const jsonrpc = '2.0'
const id = 0
const send = (method, params = []) => web3.currentProvider.send({ id, jsonrpc, method, params })

const timeTravel = async seconds => {
  await send('evm_increaseTime', [seconds])
  await send('evm_mine')
}


var minimumStake = 1e18;

async function expectThrow(promise){
  try {
    await promise;
  } catch (error) {
    // TODO: Check jump destination to destinguish between a throw
    //       and an actual invalid jump.
    const invalidOpcode = error.message.search('invalid opcode') >= 0;
    // TODO: When we contract A calls contract B, and B throws, instead
    //       of an 'invalid jump', we get an 'out of gas' error. How do
    //       we distinguish this from an actual out of gas event? (The
    //       testrpc log actually show an 'invalid jump' event.)
    const outOfGas = error.message.search('out of gas') >= 0;
    const revert = error.message.search('revert') >= 0;
    assert(
      invalidOpcode || outOfGas || revert,
      'Expected throw, got \'' + error + '\' instead',
    );
    return;
  }
  assert.fail('Expected throw not received');
};


contract('Token and Staking Tests', function(accounts) {
  let oracle;
  let owner;

    beforeEach('Setup contract for each test', async function () {
        //readcontract = await reader.new();
        owner = accounts[0];
        oracle = await Oracle.new(600);
        //var oracle = await new web3.eth.Contract(oracleAbi, oracle.address);
        balance0 = await (oracle.balanceOf(accounts[0],{from:accounts[0]}));
        await oracle.transfer(accounts[4],100,{from:accounts[0]});
        await oracle.transfer(accounts[5],100,{from:accounts[0]});
        await oracle.transfer(accounts[6],100,{from:accounts[0]});
        await oracle.transfer(accounts[7],100,{from:accounts[0]});
        await oracle.transfer(accounts[8],100,{from:accounts[0]});
    });

    it("Token transfer", async function(){
        balance4 = await oracle.balanceOf(accounts[4]);
        await oracle.transfer(accounts[4],50,{from:accounts[6]});
        balance4a = await oracle.balanceOf(accounts[4]);
        balance6 = await oracle.balanceOf(accounts[6]);
        assert.equal(balance4a, 150, "balance for acct 4 is 150");
        assert.equal(balance6, 50, "balance for acct 6 is 50");
    });

    it("Approve and transferFrom", async function(){
        await oracle.approve(accounts[1], 500);
        balance0a = await (oracle.balanceOf(accounts[0],{from:accounts[1]}));
        await oracle.transferFrom(accounts[0], accounts[5], 500, {from:accounts[1]}); 
        balance5a = await (oracle.balanceOf(accounts[5]));
        assert.equal(balance5a, 600, "balance for acct 5 is 600");
    });

    it("Allowance after approve and transferFrom", async function(){
        await oracle.approve(accounts[1], 500);
        balance0a = await (oracle.balanceOf(accounts[0],{from:accounts[1]}));
        await oracle.transferFrom(accounts[0], accounts[5], 400, {from:accounts[1]}); 
        balance5a = await (oracle.balanceOf(accounts[5]));
        assert.equal(balance5a, 500, "balance for acct 5 is 600");
        allow = await oracle.allowance(accounts[0], accounts[1]);
        assert.equal(allow, 100, "Allowance shoudl be 100");
    });

    it("Staking and attempt to transfer more than balance - stake", async function(){
        var trsf = 2;
        var tokens = web3.utils.toWei(trsf.toString(), 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        balance1 = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        console.log("Start balance1", balance1);
        await oracle.depositStake(minimumStake.toString(),{from:accounts[1]}); 
        balance1b = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        console.log("End balance1", balance1b);
        stakeAmt = await oracle.getStakeAmt(accounts[1]);
        console.log("stakeAmt", web3.utils.hexToNumberString(stakeAmt));
        await expectThrow(oracle.transfer(accounts[0],tokens,{from:accounts[1]}));
    });

    it("Staking and attempt to withdraw before stake time is up", async function(){
        var trsf = 2;
        var tokens = web3.utils.toWei(trsf.toString(), 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        balance1 = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        console.log("Start balance1", balance1);
        await oracle.depositStake(minimumStake.toString(),{from:accounts[1]}); 
        balance1b = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        console.log("End balance1", balance1b);
        stakeAmt = await oracle.getStakeAmt(accounts[1]);
        console.log("stakeAmt", web3.utils.hexToNumberString(stakeAmt));
        await expectThrow(oracle.withdrawStake({from:accounts[1]}));
    });

    it("Staking and withdraw stake ", async function(){
        var trsf = 2;
        var tokens = web3.utils.toWei(trsf.toString(), 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        balance1 = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        console.log("Start balance1", balance1);
        await oracle.depositStake(minimumStake.toString(),{from:accounts[1]}); 
        balance1b = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        console.log("End balance1", balance1b);
        stakeAmt = await oracle.getStakeAmt(accounts[1]);
        console.log("stakeAmt", web3.utils.hexToNumberString(stakeAmt));
/*      await timeTravel(15552000);
        await oracle.withdrawStake({from:accounts[1]});
        stakeAmt2 = await oracle.getStakeAmt(accounts[1]);
        console.log("stakeAmt", web3.utils.hexToNumberString(stakeAmt2));*/
    });





/*    it("Total Supply", async function(){
        supply = await oracle.totalSupply();
        console.log("supply:", supply.toString());
        const supply1 = new BN(2**256 - 1).toString();
        console.log("supply1", supply1.toString());
        assert.equal(supply1.toString,supply.toString,"Supply should be 10000");
        contra = await oracle.balanceOf(oracle.address);
        contra1 = contra.toNumber();
        contrabal= new BN(2**256 - 1 - 1000e18);
        assert.equal(contra1,contrabal,"Contract balance should be max");
    });*/



    it("getVariables", async function(){
        vars = await oracle.getVariables();
        console.log(vars);
        assert(vars[2] == 1);
    }); 

    it("Request data", async function () {
        //api = web3.utils.sha3("btc/usd");
        //test = Bytes32(api);
        //hex1 = await web3.utils.asciiToHex('btc/usd');
        //bytes = await web3.utils.hexToBytes(hex1)
        //api = await web3.utils.randomHex(32);
        api2 = "0xa5b9d60f32436310afebcfda832817a68921beb782fabf7915cc0460b443116a";
        api1 = "0x0";
        console.log("api1", api1);
        balance1 = await (oracle.balanceOf(accounts[4],{from:accounts[1]}));
        console.log("balance1", web3.utils.hexToNumberString(balance1));
        let res = await oracle.requestData(api1 ,0, 20, {from:accounts[4]});
        let resApi = await res.logs[0].args._api;//undefined???
        console.log("resApi", resApi);
        let resApiId = await res.logs[0].args._apiId;
        console.log("resApiId", resApiId);
        apiId = await oracle.getApiId(api1);
        console.log("apiId",apiId); //works      

        let res2 = await oracle.requestData(api2 ,1549080000, 20, {from:accounts[4]});
        let apiTimestamp = await res2.logs[0].args._timestamp;
        console.log("_timestamp",apiTimestamp);
        apiids2 = await oracle.getAllApiIds();
        console.log("allapiids2", apiids2)
        let valuePool = await oracle.getValuePoolAt(2,1549080000);
        console.log(valuePool);
    });

  it("Test Add Value to Pool", async function () {
        api1 = "0x0";
        time = 1549080000;
        balance1 = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        console.log("balance1", web3.utils.hexToNumberString(balance1));
        let res = await oracle.requestData(api1,time, 20, {from:accounts[1]});
        console.log(res.logs[2].args);
        let resApi = await res.logs[2].args._api;//undefined???
        console.log("resApi", resApi);
        let resApiId = await res.logs[2].args._apiId;
        console.log("resApiId", resApiId);
        let apiTimestamp = await res.logs[2].args._timestamp;
        console.log("_timestamp",apiTimestamp);
        valuePool = await oracle.addToValuePool(1,apiTimestamp,5,{from:accounts[1]});//apiTimestamp
        //console.log("valuePool", valuePool);
        getValuePool = await oracle.getValuePoolAt(1, apiTimestamp);//apiTimestamp
        console.log("Get Value Pool at", getValuePool);
        balance2 = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        console.log("balance2", web3.utils.hexToNumberString(balance2));
 /*     assert(valuePool == 5, "assert the value pool now has 5");      
       balances = [];
        for(var i = 0;i<6;i++){
            balances[i] = await oracle.balanceOf(accounts[i]);
            //console.log(i, balances[i]);
        }
        await timeTravel(86400 * 10);
        logMineWatcher = await promisifyLogWatch(oracle.NewValue({ fromBlock: 'latest' }));//or Event Mine?
        new_balances = [];
        for(var i = 0;i<6;i++){
            new_balances[i] = await oracle.balanceOf(accounts[i]);
            //console.log(i, new_balances[i]);
        }
        assert((new_balances[5] - balances[5]) == web3.toWei(1, 'ether'), "Assert miner 5(furthest from median) got lowest reward");
        assert((new_balances[1] - balances[1]) == web3.toWei(5, 'ether'), "Assert miner 1(second from median) got lowest reward");
        assert((new_balances[2] - balances[2]) == web3.toWei(10, 'ether'),"Assert miner 2(median) got largest reward");
        assert((new_balances[3] - balances[3]) == web3.toWei(5, 'ether'),"Assert miner 3(second from median) got lowest reward");
        assert((new_balances[4] - balances[4]) == web3.toWei(1, 'ether'), "Assert miner 4(furthest from median) got lowest reward");
 */  });


});
 