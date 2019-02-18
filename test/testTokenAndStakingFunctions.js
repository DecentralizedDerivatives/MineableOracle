/** 
* This contract tests the Oracle functions
*/ 
const helper = require("./helpers/test_helpers");
const Web3 = require("web3"); // import web3 v1.0 constructor
const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:8545"));
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

var api = 'json(https://api.gdax.com/products/BTC-USD/ticker).price';
var api2 = "json(https://api.gdax.com/products/ETH-USD/ticker).price";


contract('Token and Staking Tests', function(accounts) {
  let oracle;


    beforeEach('Setup contract for each test', async function () {
        //readcontract = await reader.new();
        oracle = await Oracle.new();
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
        console.log("supply:", web3.utils.hexToNumberString(supply));
        const supply1 = new BN(2**256 - 1).toString();
        console.log("supply1", web3.utils.hexToNumberString(supply1));
        assert.equal(web3.utils.hexToNumberString(supply1),web3.utils.hexToNumberString(supply),"Supply should be 10000");
        contra = await oracle.balanceOf(oracle.address);
        contra1 = await web3.utils.hexToNumberString(contra);
        contrabal= new BN(2**256 - 1 - 1000e18);
        assert.equal(contra1,contrabal,"Contract balance should be max");
    });*/    

    it("Staking ", async function(){
        var trsf = 2;
        var tokens = web3.utils.toWei(trsf.toString(), 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        balance1 = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        await oracle.depositStake({from:accounts[1]}); 
        balance1b = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        assert(web3.utils.toWei(trsf.toString(), 'ether') == web3.utils.hexToNumberString(balance1), "Balance should equal transferred amt trsf");
        assert(await oracle.isStaked(accounts[1]) == true, "still isStaked" );
    });    

    it("Staking and attempt to transfer more than balance - stake", async function(){
        var trsf = 2;
        var tokens = web3.utils.toWei(trsf.toString(), 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        balance1 = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        await oracle.depositStake({from:accounts[1]}); 
        balance1b = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        await helper.expectThrow(oracle.transfer(accounts[0],tokens,{from:accounts[1]}));
        assert(web3.utils.toWei(trsf.toString(), 'ether') == web3.utils.hexToNumberString(balance1), "Balance should equal transferred amt trsf");
    });

    it("Staking and attempt to Allow and transferFrom more than balance - stake", async function(){
        var trsf = 2;
        var tokens = web3.utils.toWei(trsf.toString(), 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        balance1 = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        await oracle.depositStake({from:accounts[1]}); 
        balance1b = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        await helper.expectThrow(oracle.approve(accounts[0],tokens,{from:accounts[1]}));
        await helper.expectThrow(oracle.transferFrom(accounts[1], accounts[8],tokens,{from:accounts[0]}));
        assert(web3.utils.toWei(trsf.toString(), 'ether') == web3.utils.hexToNumberString(balance1), "Balance should equal transferred amt trsf");
    });

    it("Staking and attempt to withdraw before stake time is up", async function(){
        var trsf = 2;
        var tokens = web3.utils.toWei(trsf.toString(), 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        balance1 = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        await oracle.depositStake({from:accounts[1]}); 
        balance1b = await (oracle.balanceOf(accounts[1],{from:accounts[0]}));
        await helper.expectThrow(oracle.withdrawStake({from:accounts[1]}));
        assert(await oracle.isStaked(accounts[1]) == true, "still isStaked" );
        assert(web3.utils.toWei(trsf.toString(), 'ether') == web3.utils.hexToNumberString(balance1), "Balance should equal transferred amt trsf");
    });

    it("Staking, requestWithdraw, withdraw stake", async function(){
        var trsf = 2;
        var tokens = web3.utils.toWei(trsf.toString(), 'ether');
        await oracle.transfer(accounts[1],tokens,{from:accounts[0]});
        await oracle.depositStake({from:accounts[1]}); 
        await helper.advanceTime(86400 * 8);
        let withdrawreq = await oracle.requestWithdraw({from:accounts[1]});
        let weSender =  await withdrawreq.logs[0].args._sender;
        assert(weSender == accounts[1], "withdraw request by account 1");
        await helper.advanceTime(86400 * 10);
        assert(await oracle.isStaked(accounts[1]) == false, "is not Staked" )
        await oracle.withdrawStake({from:accounts[1]});
        assert(await oracle.isStaked(accounts[1]) == false, " not Staked" )
    });

    it("getVariables", async function(){
    	let res = await oracle.requestData(api, 20, {from:accounts[4]});
        vars = await oracle.getVariables();
        console.log("vars", vars);
        let miningApiId = web3.utils.hexToNumberString(vars['1']);
        let difficulty = web3.utils.hexToNumberString(vars['2']);
        let sapi = vars['3'];
        console.log("miningApiId, difficulty, sapi", miningApiId, difficulty, sapi);
        assert(miningApiId == 1, "miningApiId should be 1");
        assert(difficulty == 1, "Difficulty should be 1");
        assert.equal(sapi,api, "sapi = api");
    }); 

    it("Get apiId", async function () {
        balance1 = await (oracle.balanceOf(accounts[4],{from:accounts[1]}));
        //data request 1
        let res = await oracle.requestData(api, 20, {from:accounts[4]});
        let resApiId = await res.logs[2].args._apiId;
        console.log("resApiId", resApiId);
        //check apid can be retrieved through getter
        apiHash = await oracle.getApiHash(1); 
        apiId = await oracle.getApiId(apiHash);  
        console.log("apiId from string",apiId);
        assert(web3.utils.hexToNumberString(apiId) == web3.utils.hexToNumberString(resApiId), "timestamp on Q should be apiID");
    });

    it("Get apiHash", async function () {
        balance1 = await (oracle.balanceOf(accounts[4],{from:accounts[1]}));
        //data request 1
        let res = await oracle.requestData(api, 20, {from:accounts[4]});
        let resApiHash = await res.logs[2].args._apiHash;
        console.log("resApiHash", resApiHash);
        apiHash = await oracle.getApiHash(1); 
        assert(web3.utils.hexToNumberString(apiHash) == web3.utils.hexToNumberString(resApiHash), "api on Q should be apiId");
  });
    it("Request data", async function () {
        balance1 = await (oracle.balanceOf(accounts[4],{from:accounts[1]}));
        //data request 1
        let res = await oracle.requestData(api, 20, {from:accounts[4]});
        let resSapi = await res.logs[2].args._sapi;
        console.log("resSApi", resSapi);
        let resApiHash = await res.logs[2].args._apiHash;
        console.log("resApiHash", resApiHash);
        let resApiId = await res.logs[2].args._apiId;
        console.log("resApiId", resApiId);
        //check apid can be retrieved through getter
        apiId = await oracle.getApiId(resApiHash);  
        console.log("apiId from hash",apiId);
        //check value pool
        let valuePool = await oracle.getValuePoolAt(resApiId);
        assert( web3.utils.hexToNumberString(valuePool) == 20, "value pool should be 20");
        //check apionQ updated via requestData
        let apionQ = await res.logs[1].args._apiOnQ;
        let apiIdonQ = await res.logs[1].args._apiId;
        let apiOnQPayout = await res.logs[1].args._apiOnQPayout;
        console.log("apiIdonQ",apiIdonQ);
        console.log("resApiId",resApiId);
        assert(web3.utils.hexToNumberString(apiOnQPayout) == 20, "Current payout on Q should be 20");
        assert(web3.utils.hexToNumberString(apionQ) == web3.utils.hexToNumberString(resApiHash), "api on Q should be apiId");
        assert(web3.utils.hexToNumberString(apiIdonQ) == web3.utils.hexToNumberString(resApiId), "timestamp on Q should be apiID");
    });

    it("several request data", async function () {
    //why won't it take json().price....???????????	
       test1 = "https://api.gdax.com/products/ETH-USD/ticker";
       test2 = "https://api.gdax.com/products/BTC-USD/ticker";
       req1 = await oracle.requestData(test1, 20, {from:accounts[4]});
       console.log('req1');
       //variables = await oracle.getVariablesOnQ();
       onQ = await oracle.apiIdOnQ.call();
       console.log("q1",onQ);
       assert(web3.utils.hexToNumberString(onQ) == 1, "should be 1");
       req2 = await oracle.requestData(api2, 40, {from:accounts[4]});
       console.log('req2');
       //variables2 = await oracle.getVariablesOnQ();
       onQ = await oracle.apiIdOnQ.call();
       console.log("q2",onQ);
       assert(web3.utils.hexToNumberString(onQ) == 2, "should be 2");
       req3 = await oracle.addToValuePool(1, 31, {from:accounts[4]});
       console.log('req3');
       //variables3 = await oracle.getVariablesOnQ();
       onQ = await oracle.apiIdOnQ.call();
       console.log("q3",onQ);
       assert(web3.utils.hexToNumberString(onQ) == 1, "should be 1");
       req4 = await oracle.requestData(test2, 60, {from:accounts[0]});
       console.log('req2');
       //variables2 = await oracle.getVariablesOnQ();
       onQ = await oracle.apiIdOnQ.call();
       console.log("q4",onQ);
       assert(web3.utils.hexToNumberString(onQ) == 3, "should be 3");
    });

    it("Request data and change on queue with another request", async function () {
       balance1 = await (oracle.balanceOf(accounts[4],{from:accounts[1]}));
        test1 = 'test';
        //data request 1
        let res = await oracle.requestData(test1, 20, {from:accounts[4]});
        let resSapi = await res.logs[2].args._sapi;
        console.log("resSApi", resSapi);
        let resApiHash = await res.logs[2].args._apiHash;
        console.log("resApiHash", resApiHash);
        let resApiId = await res.logs[2].args._apiId;
        console.log("resApiId", resApiId);
        //check apid can be retrieved through getter
        apiId = await oracle.getApiId(resApiHash);  
        console.log("apiId from hash",apiId);
        //check value pool
        let valuePool = await oracle.getValuePoolAt(resApiId);
        assert( web3.utils.hexToNumberString(valuePool) == 20, "value pool should be 20");
        //check apionQ updated via requestData
        let apionQ = await res.logs[1].args._apiOnQ;
        let apiIdonQ = await res.logs[1].args._apiId;
        let apiOnQPayout = await res.logs[1].args._apiOnQPayout;
        console.log("apiIdonQ",apiIdonQ);
        console.log("resApiId",resApiId);
        assert(web3.utils.hexToNumberString(apiOnQPayout) == 20, "Current payout on Q should be 20");
        assert(web3.utils.hexToNumberString(apionQ) == web3.utils.hexToNumberString(resApiHash), "api on Q should be apiId");
        assert(web3.utils.hexToNumberString(apiIdonQ) == web3.utils.hexToNumberString(resApiId), "timestamp on Q should be apiID");
        console.log("before request2");

        //data request 2
        res2 = await oracle.requestData(api2, 50, {from:accounts[4]});
        console.log("request2")
        let resApi2 = await res2.logs[2].args._apiHash;
        let resApiId2 = await res2.logs[2].args._apiId;
        let resSapi2 = await res2.logs[2].args._sapi;
        let valuePool2 = await oracle.getValuePoolAt(2);
        let apionQ2 = await res2.logs[1].args._apiOnQ;
        let ApiIdonQ2 = await res2.logs[1].args._apiId;
        let apiOnQPayout2 = await res2.logs[1].args._apiOnQPayout;
        assert(web3.utils.hexToNumberString(apiOnQPayout2) == 50, "2Current payout on Q should be 50");
        assert(web3.utils.hexToNumberString(apionQ2) == web3.utils.hexToNumberString(resApi2), "2api on Q should be apiId");
        assert(web3.utils.hexToNumberString(ApiIdonQ2) == web3.utils.hexToNumberString(resApiId2), "2timestamp on Q should be apiTimestamp");


        balance2 = await (oracle.balanceOf(accounts[4],{from:accounts[1]}));
        assert(web3.utils.hexToNumberString(balance1) - web3.utils.hexToNumberString(balance2) == 70, "balance should be down by 70");
    });

  it("Test Add Value to Pool and change on queue", async function () {

        balance1 = await (oracle.balanceOf(accounts[4],{from:accounts[1]}));
        test1 = 'test';
        //data request 1
        let res = await oracle.requestData(test1, 20, {from:accounts[4]});
        let resSapi = await res.logs[2].args._sapi;
        let resApiHash = await res.logs[2].args._apiHash;
        let resApiId = await res.logs[2].args._apiId;

        //check apid can be retrieved through getter
        apiId = await oracle.getApiId(resApiHash);  
        console.log("apiId from hash",apiId);

        //check value pool
        let valuePool = await oracle.getValuePoolAt(resApiId);
        assert( web3.utils.hexToNumberString(valuePool) == 20, "value pool should be 20");

        //check apionQ updated via requestData
        let apionQ = await res.logs[1].args._apiOnQ;
        let apiIdonQ = await res.logs[1].args._apiId;
        let apiOnQPayout = await res.logs[1].args._apiOnQPayout;
        assert(web3.utils.hexToNumberString(apiOnQPayout) == 20, "Current payout on Q should be 20");
        assert(web3.utils.hexToNumberString(apionQ) == web3.utils.hexToNumberString(resApiHash), "api on Q should be apiId");
        assert(web3.utils.hexToNumberString(apiIdonQ) == web3.utils.hexToNumberString(resApiId), "timestamp on Q should be apiID");
        
        //data request 2
        let res2 = await oracle.requestData(api2, 30, {from:accounts[4]});
        let resApi2 = await res2.logs[2].args._apiHash;
        let resApiId2 = await res2.logs[2].args._apiId;
        let resSapi2 = await res2.logs[2].args._sapi;
        let valuePool2 = await oracle.getValuePoolAt(2);
        let apionQ2 = await res2.logs[1].args._apiOnQ;
        let ApiIdonQ2 = await res2.logs[1].args._apiId;
        let apiOnQPayout2 = await res2.logs[1].args._apiOnQPayout;
        assert(web3.utils.hexToNumberString(apiOnQPayout2) == 30, "2Current payout on Q should be 30");
        assert(web3.utils.hexToNumberString(apionQ2) == web3.utils.hexToNumberString(resApi2), "2api on Q should be apiId");
        assert(web3.utils.hexToNumberString(ApiIdonQ2) == web3.utils.hexToNumberString(resApiId2), "2timestamp on Q should be apiTimestamp");

        //balance check
        balance2 = await (oracle.balanceOf(accounts[4],{from:accounts[1]}));
        assert(web3.utils.hexToNumberString(balance1) - web3.utils.hexToNumberString(balance2) == 50, "balance should be down by 50")

        //add to value pool of request not on Q 
        let addvaluePool = await oracle.addToValuePool(1,20,{from:accounts[4]});
        getValuePool = await oracle.getValuePoolAt(1);
        balance3 = await (oracle.balanceOf(accounts[4],{from:accounts[0]}));
        assert(web3.utils.hexToNumberString(balance1) - web3.utils.hexToNumberString(balance3) == 70, "balance should be down by 70")
        
        //check request on Q updates via addToValuePool
        let vpApiOnQ = await addvaluePool.logs[1].args._apiOnQ;
        let vpApiIdonQ = await addvaluePool.logs[1].args._apiId;
        let vpapiOnQPayout = await addvaluePool.logs[1].args._apiOnQPayout;
        assert(web3.utils.hexToNumberString(vpapiOnQPayout) == 40, "Current payout on Q should be 40");
        assert(web3.utils.hexToNumberString(vpApiOnQ) == web3.utils.hexToNumberString(resApiHash), "api on Q should be apiId");
        assert(web3.utils.hexToNumberString(vpApiIdonQ) == web3.utils.hexToNumberString(resApiId), "timestamp on Q should be apiTimestamp");
          
/*       balances = [];
        for(var i = 0;i<6;i++){
            balances[i] = await oracle.balanceOf(accounts[i]);
            //console.log(i, balances[i]);
        }
        oracle2 = await new web3.eth.Contract(oracleAbi,oracle.address);
        await helper.advanceTime(86400 * 10);
        logMineWatcher = await promisifyLogWatch(oracle2, "NewValue");//or Event Mine?
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
 */
 }); 




});
 