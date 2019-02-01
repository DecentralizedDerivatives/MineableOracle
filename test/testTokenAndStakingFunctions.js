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

    it("Staking and attempt to transfer more than balance - stake", async function(){
        var trsf = 2;
        var tokens = web3.utils.toWei(trsf.toString(), 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        balance1 = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        await oracle.depositStake(minimumStake.toString(),{from:accounts[1]}); 
        balance1b = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        stakeAmt = await oracle.getStakeAmt(accounts[1]);
        await expectThrow(oracle.transfer(accounts[0],tokens,{from:accounts[1]}));
        assert(web3.utils.hexToNumberString(stakeAmt) == minimumStake.toString(), "minstake should eaqal stakeamt" );
        assert(web3.utils.toWei(trsf.toString(), 'ether') == web3.utils.hexToNumberString(balance1), "Balance should equal transferred amt trsf");
    });

    it("Staking and attempt to Allow and transferFrom more than balance - stake", async function(){
        var trsf = 2;
        var tokens = web3.utils.toWei(trsf.toString(), 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        balance1 = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        await oracle.depositStake(minimumStake.toString(),{from:accounts[1]}); 
        balance1b = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        stakeAmt = await oracle.getStakeAmt(accounts[1]);
        await expectThrow(oracle.approve(accounts[0],tokens,{from:accounts[1]}));
        await expectThrow(oracle.transferFrom(accounts[1], accounts[8],tokens,{from:accounts[0]}));
        assert(web3.utils.hexToNumberString(stakeAmt) == minimumStake.toString(), "minstake should eaqal stakeamt" );
        assert(web3.utils.toWei(trsf.toString(), 'ether') == web3.utils.hexToNumberString(balance1), "Balance should equal transferred amt trsf");
    });


    it("Staking and attempt to withdraw before stake time is up", async function(){
        var trsf = 2;
        var tokens = web3.utils.toWei(trsf.toString(), 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        balance1 = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        await oracle.depositStake(minimumStake.toString(),{from:accounts[1]}); 
        balance1b = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        stakeAmt = await oracle.getStakeAmt(accounts[1]);
        await expectThrow(oracle.withdrawStake({from:accounts[1]}));
        assert(web3.utils.hexToNumberString(stakeAmt) == minimumStake.toString(), "minstake should eaqal stakeamt" );
        assert(web3.utils.toWei(trsf.toString(), 'ether') == web3.utils.hexToNumberString(balance1), "Balance should equal transferred amt trsf");
  
    });

    it("Staking and withdraw stake ", async function(){
        var trsf = 2;
        var tokens = web3.utils.toWei(trsf.toString(), 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        await oracle.depositStake(minimumStake.toString(),{from:accounts[1]}); 
        stakeAmt = await oracle.getStakeAmt(accounts[1]);
/*       console.log("stakeAmt", web3.utils.hexToNumberString(stakeAmt));
        await timeTravel(86400 * 180);//time travel notworking/ timingout
        await oracle.withdrawStake({from:accounts[1]});
        stakeAmt2 = await oracle.getStakeAmt(accounts[1]);
        console.log("stakeAmt", web3.utils.hexToNumberString(stakeAmt2));*/
    });


    it("getVariables", async function(){
        vars = await oracle.getVariables();
        assert(vars[2] == 1);
    }); 

    it("Request data", async function () {
        api1 = "0x0";
        api2 = "0xa5b9d60f32436310afebcfda832817a68921beb782fabf7915cc0460b443116a";
        time = 1549080000;

        balance1 = await (oracle.balanceOf(accounts[4],{from:accounts[1]}));

        //data request 1
        let res = await oracle.requestData(api1,time, 20, {from:accounts[4]});
        let resApi = await res.logs[2].args._api;
        let resApiId = await res.logs[2].args._apiId;
        let apiTimestamp = await res.logs[2].args._timestamp;  
        //check apid can be retrieved through getter
        apiId = await oracle.getApiId(api1);  
        //check value pool
        let valuePool = await oracle.getValuePoolAt(1, time);
        assert( web3.utils.hexToNumberString(valuePool) == 20, "value pool should be 20");
        //check apionQ updated via requestData
        let apionQ = await res.logs[1].args._apiOnQ;
        let timeonQ = await res.logs[1].args._timeOnQ;
        let apiOnQPayout = await res.logs[1].args._apiOnQPayout;
        assert(web3.utils.hexToNumberString(apiOnQPayout) == 20, "Current payout on Q should be 20");
        assert(web3.utils.hexToNumberString(apionQ) == web3.utils.hexToNumberString(resApi), "api on Q should be apiId");
        assert(web3.utils.hexToNumberString(timeonQ) == web3.utils.hexToNumberString(apiTimestamp), "timestamp on Q should be apiTimestamp");
        
        //data request 2
        let res2 = await oracle.requestData(api2,time, 50, {from:accounts[4]});
        let resApi2 = await res2.logs[2].args._api;
        let resApiId2 = await res2.logs[2].args._apiId;
        let apiTimestamp2 = await res2.logs[2].args._timestamp;
        let valuePool2 = await oracle.getValuePoolAt(2, web3.utils.hexToNumberString(apiTimestamp2));
        let apionQ2 = await res2.logs[1].args._apiOnQ;
        let timeonQ2 = await res2.logs[1].args._timeOnQ;
        let apiOnQPayout2 = await res2.logs[1].args._apiOnQPayout;
        assert(web3.utils.hexToNumberString(apiOnQPayout2) == 50, "Current payout on Q should be 50");
        assert(web3.utils.hexToNumberString(apionQ2) == web3.utils.hexToNumberString(resApi2), "api on Q should be apiId");
        assert(web3.utils.hexToNumberString(timeonQ2) == web3.utils.hexToNumberString(apiTimestamp2), "timestamp on Q should be apiTimestamp");
 
        //check apiIds[] is being updated
        apiIds = await oracle.getAllApiIds();
        assert( apiIds = [1,2], "Assert apiIds 1 and 2 exist");

        balance2 = await (oracle.balanceOf(accounts[4],{from:accounts[1]}));
        assert(web3.utils.hexToNumberString(balance1) - web3.utils.hexToNumberString(balance2) == 70, "balance should be down by 70")

    });

  it("Test Add Value to Pool", async function () {
        api1 = "0x0";
        api2 = "0xa5b9d60f32436310afebcfda832817a68921beb782fabf7915cc0460b443116a";
        time = 1549080000;
        balance1 = await (oracle.balanceOf(accounts[4],{from:accounts[1]}));

        //data request 1
        let res = await oracle.requestData(api1,time, 10, {from:accounts[4]});
        let resApi = await res.logs[2].args._api;
        let resApiId = await res.logs[2].args._apiId;
        let apiTimestamp = await res.logs[2].args._timestamp; 
        //check value pool  
        apiId = await oracle.getApiId(api1);
        let valuePool = await oracle.getValuePoolAt(1, time);
        assert( web3.utils.hexToNumberString(valuePool) == 10, "value pool should be 20");
        //check apionQ updated via requestData
        let apionQ = await res.logs[1].args._apiOnQ;
        let timeonQ = await res.logs[1].args._timeOnQ;
        let apiOnQPayout = await res.logs[1].args._apiOnQPayout;
        assert(web3.utils.hexToNumberString(apiOnQPayout) == 10, "Current payout on Q should be 20");
        assert(web3.utils.hexToNumberString(apionQ) == web3.utils.hexToNumberString(resApi), "api on Q should be apiId");
        assert(web3.utils.hexToNumberString(timeonQ) == web3.utils.hexToNumberString(apiTimestamp), "timestamp on Q should be apiTimestamp");

        //data request 2
        let res2 = await oracle.requestData(api2,time, 20, {from:accounts[4]});
        let resApi2 = await res2.logs[2].args._api;
        let resApiId2 = await res2.logs[2].args._apiId;
        let apiTimestamp2 = await res2.logs[2].args._timestamp;
        let valuePool2 = await oracle.getValuePoolAt(2, web3.utils.hexToNumberString(apiTimestamp2));
        let apionQ2 = await res2.logs[1].args._apiOnQ;
        let timeonQ2 = await res2.logs[1].args._timeOnQ;
        let apiOnQPayout2 = await res2.logs[1].args._apiOnQPayout;
        assert(web3.utils.hexToNumberString(apiOnQPayout2) == 20, "Current payout on Q should be 50");
        assert(web3.utils.hexToNumberString(apionQ2) == web3.utils.hexToNumberString(resApi2), "api on Q should be apiId");
        assert(web3.utils.hexToNumberString(timeonQ2) == web3.utils.hexToNumberString(apiTimestamp2), "timestamp on Q should be apiTimestamp");

        //check apiIds[] is being updated
        apiIds = await oracle.getAllApiIds();
        assert( apiIds = [1,2], "Assert apiIds 1 and 2 exist");

        //balance check
        balance2 = await (oracle.balanceOf(accounts[4],{from:accounts[1]}));
        assert(web3.utils.hexToNumberString(balance1) - web3.utils.hexToNumberString(balance2) == 30, "balance should be down by 70")

        //add to value pool of request not on Q 
        let addvaluePool = await oracle.addToValuePool(1,time,30,{from:accounts[4]});//apiTimestamp
        getValuePool = await oracle.getValuePoolAt(1, time);//apiTimestamp
        balance3 = await (oracle.balanceOf(accounts[4],{from:accounts[0]}));
        assert(web3.utils.hexToNumberString(balance1) - web3.utils.hexToNumberString(balance3) == 60, "balance should be down by 60")
        
        //check request on Q updates via addToValuePool
        vpApiOnQ = await addvaluePool.logs[1].args._apiOnQ;
        vptimeonQ  = await addvaluePool.logs[1].args._timeOnQ;
        vpapiOnQPayout = await addvaluePool.logs[1].args._apiOnQPayout;
        assert(web3.utils.hexToNumberString(vpapiOnQPayout) == 40, "Current payout on Q should be 40");
        assert(web3.utils.hexToNumberString(vpApiOnQ) == web3.utils.hexToNumberString(resApi), "api on Q should be apiId");
        assert(web3.utils.hexToNumberString(vptimeonQ) == web3.utils.hexToNumberString(apiTimestamp), "timestamp on Q should be apiTimestamp");
 /*          
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
/*
initDispute external
vote    public
tallyVotes  public
getDisputeInfo  public view
countDisputes   public view
getDisputesIds  public view
updateDisputeValue  internal

*/



});
 