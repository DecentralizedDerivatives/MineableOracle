/** 
* This contract tests the Oracle functions
*/ 

// const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));

// const jsonrpc = '2.0'
// const id = 0
// const send = (method, params = []) => web3.currentProvider.send({ id, jsonrpc, method, params })



const Web3 = require('web3')
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545'));
const BN = require('bn.js');
const helper = require("./helpers/test_helpers");
//const ethers = require('ethers');

const Oracle = artifacts.require("./Oracle.sol"); // globally injected artifacts helper
var Reader = artifacts.require("Reader.sol");
var oracleAbi = Oracle.abi;
var oracleByte = Oracle.bytecode;

var api = 'json(https://api.gdax.com/products/BTC-USD/ticker).price';
var api2 = 'json(https://api.gdax.com/products/ETH-USD/ticker).price';

function promisifyLogWatch(_contract,_event) {
  return new Promise((resolve, reject) => {
    web3.eth.subscribe('logs', {
      address: _contract.options.address,
      topics:  ['0xba11e319aee26e7bbac889432515ba301ec8f6d27bf6b94829c21a65c5f6ff25']
    }, (error, result) => {
        if (error){
          console.log('Error',error);
          reject(error);
        }
        web3.eth.clearSubscriptions();
        //console.log(result);
        resolve(result);
    })
  });
}

contract('Token and Staking Tests', function(accounts) {
  let oracle;
  let oracle2;
  let owner;
  let reader;
  let logNewValueWatcher;
  let logMineWatcher;

    beforeEach('Setup contract for each test', async function () {
        owner = accounts[0];
        oracle = await Oracle.new();
        oracle2 = await new web3.eth.Contract(oracleAbi,oracle.address);
        await oracle.initStake();
        await oracle.requestData(api,0);
        await helper.advanceTime(86400 * 8);
        let withdrawreq = await oracle.requestWithdraw({from:accounts[2]});
        await helper.advanceTime(86400 * 8);
        await oracle.withdrawStake({from:accounts[2]});
        // console.log('Oracle Address ',oracle.address);
        // console.log('START MINING RIG!!');
        // var val = await oracle.getVariables();
        // logMineWatcher = await promisifyLogWatch(oracle2, 'NewValue');//or Event Mine?
        // res = web3.eth.abi.decodeParameters(['uint256','uint256','uint256'],logMineWatcher.data);
        // console.log("res" , res);
   });  

    it("Token transfer", async function(){
        balance2 = await oracle.balanceOf(accounts[2]);
        t = web3.utils.toWei('5', 'ether');
        await oracle.transfer(accounts[5],t,{from:accounts[2]});
        balance2a = await oracle.balanceOf(accounts[2]);
        balance5 = await oracle.balanceOf(accounts[5]);
        assert(web3.utils.fromWei(balance2a, 'ether') == 995, "balance for acct 2 is 995");
        assert(web3.utils.fromWei(balance5) == 1005, "balance for acct 5 is 1005");
    });

    it("Approve and transferFrom", async function(){
    	t = web3.utils.toWei('7', 'ether');
        await oracle.approve(accounts[1], t, {from:accounts[2]});
        balance0a = await (oracle.balanceOf(accounts[2],{from:accounts[1]}));
        await oracle.transferFrom(accounts[2], accounts[5], t, {from:accounts[1]}); 
        balance5a = await (oracle.balanceOf(accounts[5]));
        assert(web3.utils.fromWei(balance5a) == 1007, "balance for acct 5 is 1007");
    });

    it("Allowance after approve and transferFrom", async function(){
    	t = web3.utils.toWei('7', 'ether');
    	t2 = web3.utils.toWei('6', 'ether');
        await oracle.approve(accounts[1], t, {from:accounts[2]});
        balance0a = await (oracle.balanceOf(accounts[2],{from:accounts[1]}));
        await oracle.transferFrom(accounts[2], accounts[5], t2, {from:accounts[1]}); 
        balance5a = await (oracle.balanceOf(accounts[5]));
        assert.equal(web3.utils.fromWei(balance5a), 1006, "balance for acct 5 is 1006");
        allow = await oracle.allowance(accounts[2], accounts[1]);
        assert.equal(web3.utils.fromWei(allow, 'ether'), 1, "Allowance shoudl be 1 eth");
    });

/*   it("Total Supply", async function(){
        supply = await BN(oracle.totalSupply());
        console.log("supply", supply);
        console.log("supply:", web3.utils.hexToNumberString(supply));
        supply1 = new BN(2**256-1 - 5000e18).toString();
        console.log("supply1", web3.utils.hexToNumberString(supply1));
        assert.equal(web3.utils.hexToNumberString(supply1),web3.utils.hexToNumberString(supply),"Supply should be 10000");
        contra = await oracle.balanceOf(oracle.address);
        contra1 = await web3.utils.hexToNumberString(contra);
        contrabal= new BN(2**256 - 1 - 5000e18);
        assert.equal(contra1,contrabal,"Contract balance should be max");
    }); */  

    it("re-Staking without withdraw ", async function(){
    	await helper.advanceTime(86400 * 10);
        let withdrawreq = await oracle.requestWithdraw({from:accounts[1]});
        let weSender =  await withdrawreq.logs[0].args._sender;
        assert(weSender == accounts[1], "withdraw request by account 1");
        await helper.advanceTime(86400 * 10);
        assert(await oracle.isStaked(accounts[1]) == false, "is not Staked" );
        await oracle.depositStake({from:accounts[1]});
        assert(await oracle.isStaked(accounts[1]) == true, "Staked" );
    });    

    it("withdraw and re-stake", async function(){
    	await helper.advanceTime(86400 * 10);
        let withdrawreq = await oracle.requestWithdraw({from:accounts[1]});
        let weSender =  await withdrawreq.logs[0].args._sender;
        assert(weSender == accounts[1], "withdraw request by account 1");
        await helper.advanceTime(86400 * 10);
        assert(await oracle.isStaked(accounts[1]) == false, "is not Staked" );
        await oracle.withdrawStake({from:accounts[1]});
        assert(await oracle.isStaked(accounts[1]) == false, " not Staked" );
        await oracle.depositStake({from:accounts[1]}); 
        assert(await oracle.isStaked(accounts[1]) == true, " Staked" );
    }); 

    it("Attempt to transfer more than balance - stake", async function(){
        var tokens = web3.utils.toWei('1', 'ether');
        var tokens2 = web3.utils.toWei('2', 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[2]});
        balance1 = await (oracle.balanceOf(accounts[1],{from:accounts[2]}));
        await helper.expectThrow(oracle.transfer(accounts[1],tokens2,{from:accounts[1]}));
        balance1b = await (oracle.balanceOf(accounts[1],{from:accounts[2]}));
        assert( web3.utils.fromWei(balance1b) == 1001, "Balance should == (1000 + tokens)");
    });

    it("Attempt to Allow and transferFrom more than balance - stake", async function(){
        var tokens = web3.utils.toWei('2', 'ether');
        var tokens2 = web3.utils.toWei('3', 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[2]});
        balance1 = await (oracle.balanceOf(accounts[1],{from:accounts[2]}));
        await helper.expectThrow(oracle.approve(accounts[6],tokens,{from:accounts[1]}));
        await helper.expectThrow(oracle.transferFrom(accounts[1], accounts[8],tokens,{from:accounts[6]}));
        balance1b = await (oracle.balanceOf(accounts[1],{from:accounts[2]})); 
        assert((1000 + web3.utils.fromWei(tokens)*1) == web3.utils.fromWei(balance1)*1, "Balance for acct 1 should == 1000 + transferred amt ");
    });

    it("Attempt to withdraw before stake time is up", async function(){ 
        balance1b = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        await oracle.depositStake({from:accounts[1]}); 
        await helper.expectThrow(oracle.withdrawStake({from:accounts[1]}));
        assert(await oracle.isStaked(accounts[1]) == true, "still isStaked" );
        assert(web3.utils.fromWei(balance1b) == 1000, "Balance should equal transferred amt");
    });

    it("Staking, requestWithdraw, withdraw stake", async function(){
        let withdrawreq = await oracle.requestWithdraw({from:accounts[1]});
        let weSender =  await withdrawreq.logs[0].args._sender;
        assert(weSender == accounts[1], "withdraw request by account 1");
        await helper.advanceTime(86400 * 8);
        assert(await oracle.isStaked(accounts[1]) == false, "is not Staked" );//should the requestWitdraw change the stakeState
        await oracle.withdrawStake({from:accounts[1]});
        assert(await oracle.isStaked(accounts[1]) == false, " not Staked" );
    });

    it("getVariables", async function(){
    	let res = await oracle.requestData(api, 20, {from:accounts[2]});
        vars = await oracle.getVariables();
        //console.log("vars", vars);
        let miningApiId = web3.utils.hexToNumberString(vars['1']);
        let difficulty = web3.utils.hexToNumberString(vars['2']);
        let sapi = vars['3'];
        //console.log("miningApiId, difficulty, sapi", miningApiId, difficulty, sapi);
        assert(miningApiId == 1, "miningApiId should be 1");
        assert(difficulty == 1, "Difficulty should be 1");
        assert.equal(sapi,api, "sapi = api");
    }); 

    it("Get apiId", async function () {
        balance1 = await (oracle.balanceOf(accounts[2],{from:accounts[1]}));
        //data request 1
        let res = await oracle.requestData(api, 20, {from:accounts[2]});
        let resApiId = await res.logs[2].args._apiId;
        //console.log("resApiId", resApiId);
        //check apid can be retrieved through getter
        apiHash = await oracle.getApiHash(1); 
        apiId = await oracle.getApiId(apiHash);  
        //console.log("apiId from string",apiId);
        assert(web3.utils.hexToNumberString(apiId) == web3.utils.hexToNumberString(resApiId), "timestamp on Q should be apiID");
    });

    it("Get apiHash", async function () {
        balance1 = await (oracle.balanceOf(accounts[2],{from:accounts[1]}));
        //data request 1
        let res = await oracle.requestData(api2, 20, {from:accounts[2]});
        let resApiHash = await res.logs[2].args._apiHash;
        //console.log("resApiHash", resApiHash);
        apiHash = await oracle.getApiHash(2); 
        //console.log("apiHash", apiHash);
        assert(web3.utils.hexToNumberString(apiHash) == web3.utils.hexToNumberString(resApiHash), "api on Q should be apiId");
    });

    it("Request data", async function () {
        //data request 1
        let res = await oracle.requestData(api2, 20, {from:accounts[2]});
        let resSapi = await res.logs[2].args._sapi;
        //console.log("resSApi", resSapi);
        let resApiHash = await res.logs[2].args._apiHash;
        //console.log("resApiHash", resApiHash);
        let resApiId = await res.logs[2].args._apiId;
        //console.log("resApiId", resApiId);
        //check apid can be retrieved through getter
        apiId = await oracle.getApiId(resApiHash);  
        //console.log("apiId from hash",apiId);
        //check value pool
        let valuePool = await oracle.getValuePoolAt(resApiId);
        assert( web3.utils.hexToNumberString(valuePool) == 20, "value pool should be 20");
        //check apionQ updated via requestData
        let apionQ = await res.logs[1].args._apiOnQ;
        let apiIdonQ = await res.logs[1].args._apiId;
        let apiOnQPayout = await res.logs[1].args._apiOnQPayout;
        //console.log("apiIdonQ",apiIdonQ);
        //console.log("resApiId",resApiId);
        assert(web3.utils.hexToNumberString(apiOnQPayout) == 20, "Current payout on Q should be 20");
        assert(web3.utils.hexToNumberString(apionQ) == web3.utils.hexToNumberString(resApiHash), "api on Q should be apiId");
        assert(web3.utils.hexToNumberString(apiIdonQ) == web3.utils.hexToNumberString(resApiId), "timestamp on Q should be apiID");
    });

    it("several request data", async function () {
    //I need more apis'
       test1 = "https://api.gdax.com/products/ETH-USD/ticker";
       test2 = "https://api.gdax.com/products/BTC-USD/ticker";
       req1 = await oracle.requestData(test1, 20, {from:accounts[2]});
       //console.log('req1');
       //variables = await oracle.getVariablesOnQ();
       onQ = await oracle.apiIdOnQ.call();
       //console.log("q1",onQ);
       assert(web3.utils.hexToNumberString(onQ) == 2, "should be 2");
       req2 = await oracle.requestData(api2, 40, {from:accounts[2]});
       //console.log('req2');
       //variables2 = await oracle.getVariablesOnQ();
       onQ = await oracle.apiIdOnQ.call();
       //console.log("q2",onQ);
       assert(web3.utils.hexToNumberString(onQ) == 3, "should be 3");
       req3 = await oracle.addToValuePool(2, 31, {from:accounts[2]});
       //console.log('req3');
       //variables3 = await oracle.getVariablesOnQ();
       onQ = await oracle.apiIdOnQ.call();
       //console.log("q3",onQ);
       assert(web3.utils.hexToNumberString(onQ) == 2, "should be 2");
       req4 = await oracle.requestData(test2, 60, {from:accounts[2]});
       //console.log('req2');
       //variables2 = await oracle.getVariablesOnQ();
       onQ = await oracle.apiIdOnQ.call();
       //console.log("q4",onQ);
       assert(web3.utils.hexToNumberString(onQ) == 4, "should be 4");
    });

    it("Request data and change on queue with another request", async function () {
        balance1 = await (oracle.balanceOf(accounts[2],{from:accounts[1]}));
        test1 = 'test';
        let pay = web3.utils.toWei('20', 'ether');
        let pay2 = web3.utils.toWei('50', 'ether');
        //data request 1
        let res = await oracle.requestData(test1, pay, {from:accounts[2]});
        let resSapi = await res.logs[2].args._sapi;
        //console.log("resSApi", resSapi);
        let resApiHash = await res.logs[2].args._apiHash;
        //console.log("resApiHash", resApiHash);
        let resApiId = await res.logs[2].args._apiId;
        //console.log("resApiId", resApiId);
        //check apid can be retrieved through getter
        apiId = await oracle.getApiId(resApiHash);  
        //console.log("apiId from hash",apiId);
        //check value pool
        let valuePool = await oracle.getValuePoolAt(resApiId);
        assert( web3.utils.fromWei(valuePool) == 20, "value pool should be 20");
        //check apionQ updated via requestData
        let apionQ = await res.logs[1].args._apiOnQ;
        let apiIdonQ = await res.logs[1].args._apiId;
        let apiOnQPayout = await res.logs[1].args._apiOnQPayout;
        //console.log("apiIdonQ",apiIdonQ);
        //console.log("resApiId",resApiId);
        assert(web3.utils.fromWei(apiOnQPayout) == 20, "Current payout on Q should be 20");
        assert(web3.utils.hexToNumberString(apionQ) == web3.utils.hexToNumberString(resApiHash), "api on Q should be apiId");
        assert(web3.utils.hexToNumberString(apiIdonQ) == web3.utils.hexToNumberString(resApiId), "timestamp on Q should be apiID");
        //data request 2
        res2 = await oracle.requestData(api2, pay2, {from:accounts[2]});
        let resApi2 = await res2.logs[2].args._apiHash;
        let resApiId2 = await res2.logs[2].args._apiId;
        let resSapi2 = await res2.logs[2].args._sapi;
        let valuePool2 = await oracle.getValuePoolAt(2);
        let apionQ2 = await res2.logs[1].args._apiOnQ;
        let ApiIdonQ2 = await res2.logs[1].args._apiId;
        let apiOnQPayout2 = await res2.logs[1].args._apiOnQPayout;
        assert(web3.utils.fromWei(apiOnQPayout2) == 50, "2Current payout on Q should be 50");
        assert(web3.utils.hexToNumberString(apionQ2) == web3.utils.hexToNumberString(resApi2), "2api on Q should be apiId");
        assert(web3.utils.hexToNumberString(ApiIdonQ2) == web3.utils.hexToNumberString(resApiId2), "2timestamp on Q should be apiTimestamp");
        balance2 = await (oracle.balanceOf(accounts[2],{from:accounts[1]}));
        assert(web3.utils.fromWei(balance1) - web3.utils.fromWei(balance2) == 70, "balance should be down by 70");
    });

  it("Test Add Value to Pool and change on queue", async function () {
        balance1 = await (oracle.balanceOf(accounts[2],{from:accounts[1]}));
        test1 = 'test';
        let pay = web3.utils.toWei('20', 'ether');
        let pay2 = web3.utils.toWei('30', 'ether');
        let res = await oracle.requestData(test1, pay, {from:accounts[2]});
        let resSapi = await res.logs[2].args._sapi;
        let resApiHash = await res.logs[2].args._apiHash;
        let resApiId = await res.logs[2].args._apiId;
        //check apid can be retrieved through getter
        apiId = await oracle.getApiId(resApiHash);  

        //check value pool
        let valuePool = await oracle.getValuePoolAt(resApiId);
        assert( web3.utils.fromWei(valuePool) == 20, "value pool should be 20");

        //check apionQ updated via requestData
        let apionQ = await res.logs[1].args._apiOnQ;
        let apiIdonQ = await res.logs[1].args._apiId;
        let apiOnQPayout = await res.logs[1].args._apiOnQPayout;
        assert(web3.utils.fromWei(apiOnQPayout) == 20, "Current payout on Q should be 20");
        assert(web3.utils.hexToNumberString(apionQ) == web3.utils.hexToNumberString(resApiHash), "api on Q should be apiId");
        assert(web3.utils.hexToNumberString(apiIdonQ) == web3.utils.hexToNumberString(resApiId), "timestamp on Q should be apiID");
        
        //data request 2
        let res2 = await oracle.requestData(api2, pay2, {from:accounts[2]});
        let resApi2 = await res2.logs[2].args._apiHash;
        let resApiId2 = await res2.logs[2].args._apiId;
        let resSapi2 = await res2.logs[2].args._sapi;
        let valuePool2 = await oracle.getValuePoolAt(2);
        let apionQ2 = await res2.logs[1].args._apiOnQ;
        let ApiIdonQ2 = await res2.logs[1].args._apiId;
        let apiOnQPayout2 = await res2.logs[1].args._apiOnQPayout;
        assert(web3.utils.fromWei(apiOnQPayout2) == 30, "2Current payout on Q should be 30");
        assert(web3.utils.hexToNumberString(apionQ2) == web3.utils.hexToNumberString(resApi2), "2api on Q should be apiId");
        assert(web3.utils.hexToNumberString(ApiIdonQ2) == web3.utils.hexToNumberString(resApiId2), "2timestamp on Q should be apiTimestamp");

        //balance check
        balance2 = await (oracle.balanceOf(accounts[2],{from:accounts[1]}));
        assert(web3.utils.fromWei(balance1) - web3.utils.fromWei(balance2) == 50, "balance should be down by 50")

        //add to value pool of request not on Q 
        let addvaluePool = await oracle.addToValuePool(2,pay,{from:accounts[2]});
        getValuePool = await oracle.getValuePoolAt(1);
        balance3 = await (oracle.balanceOf(accounts[2],{from:accounts[0]}));
        assert(web3.utils.fromWei(balance1) - web3.utils.fromWei(balance3) == 70, "balance should be down by 70")
        
        //check request on Q updates via addToValuePool
        let vpApiOnQ = await addvaluePool.logs[1].args._apiOnQ;
        let vpApiIdonQ = await addvaluePool.logs[1].args._apiId;
        let vpapiOnQPayout = await addvaluePool.logs[1].args._apiOnQPayout;
        assert(web3.utils.fromWei(vpapiOnQPayout) == 40, "Current payout on Q should be 40");
        assert(web3.utils.hexToNumberString(vpApiOnQ) == web3.utils.hexToNumberString(resApiHash), "api on Q should be apiId");
        assert(web3.utils.hexToNumberString(vpApiIdonQ) == web3.utils.hexToNumberString(resApiId), "timestamp on Q should be apiTimestamp");
          
    }); 

});
