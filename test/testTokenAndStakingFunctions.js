/** 
* This contract tests the Oracle functions
*To write - testing forks, adding only owner to forks?
*/ 

const Web3 = require('web3')
const web3 = new Web3(new Web3.providers.WebsocketProvider('ws://localhost:8545'));
const BN = require('bn.js');
const helper = require("./helpers/test_helpers");

const TellorStorage = artifacts.require("./TellorStorage.sol");
const Oracle = artifacts.require("./Tellor.sol"); // globally injected artifacts helper
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
        resolve(result);
    })
  });
}


function fallbackProxyCall(_contract,_function,_inputs,_callAddress){
    var obj = _contract.abi
    for(i in obj){
        if (obj[i].name == _function){
            console.log(web3.eth.abi.encodeFunctionCall(obj[i],_inputs))
            return web3.eth.call({to: _callAddress, data:web3.eth.abi.encodeFunctionCall(obj[i],_inputs)});
        }
    }
}

contract('Token and Staking Tests', function(accounts) {
  let oracle;
  let oracle2;
  let oracleBase;
  let reader;
  let logNewValueWatcher;
  let logMineWatcher;
  let res0;

    beforeEach('Setup contract for each test', async function () {
        oracleBase = await Oracle.new();
        oracle = await TellorStorage.new(oracleBase.address);
        oracle2 = await new web3.eth.Contract(oracleAbi,oracleBase.address);///will this instance work for logWatch? hopefully...
        await web3.eth.sendTransaction({to: oracle.address,from:accounts[0],gas:7000000, data: web3.utils.keccak256("initStake()")})
        await web3.eth.sendTransaction({to: oracle.address,from:accounts[0],gas:7000000,data:oracle2.methods.requestData(api,0,1000,0).encodeABI()})
        await helper.advanceTime(86400 * 8);
        await web3.eth.sendTransaction({to:oracle.address,from:accounts[2],gas:7000000,data:oracle2.methods.requestWithdraw().encodeABI()})
        //await web3.eth.sendTransaction({to: oracle.address,from:accounts[2],data:oracle2.methods.requestWithdraw().encodeABI()})
        await helper.advanceTime(86400 * 8);
        await web3.eth.sendTransaction({to:oracle.address,from:accounts[2],data:oracle2.methods.withdrawStake().encodeABI()})
   });  
    it("Token transfer", async function(){
        balance2 =  await web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[2]).encodeABI()})
        t = web3.utils.toWei('5', 'ether');
        await web3.eth.sendTransaction({to:oracle.address,from:accounts[2],gas:700000,data:oracle2.methods.transfer(accounts[5], t).encodeABI()})
        balance2a = await web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[2]).encodeABI()})
        balance5 = await web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[5]).encodeABI()})
        assert(web3.utils.fromWei(balance2a, 'ether') == 995, web3.utils.fromWei(balance2a, 'ether') + "should be 995");
        assert(web3.utils.fromWei(balance5) == 1005, "balance for acct 5 is 1005");
    });
   it("Approve and transferFrom", async function(){
    	t = web3.utils.toWei('7', 'ether');
         await web3.eth.sendTransaction({to:oracle.address,from:accounts[2],gas:700000,data:oracle2.methods.approve(accounts[1], t).encodeABI()})
        balance0a = await web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[2]).encodeABI()})
         await web3.eth.sendTransaction({to:oracle.address,from:accounts[1],gas:700000,data:oracle2.methods.transferFrom(accounts[2], accounts[5], t).encodeABI()})
        balance5a = await web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[5]).encodeABI()});
        assert(web3.utils.fromWei(balance5a) == 1007, "balance for acct 5 is 1007");
    });

    it("Allowance after approve and transferFrom", async function(){
    	t = web3.utils.toWei('7', 'ether');
    	t2 = web3.utils.toWei('6', 'ether');
         await web3.eth.sendTransaction({to:oracle.address,from:accounts[2],gas:700000,data:oracle2.methods.approve(accounts[1], t).encodeABI()})
        balance0a = await web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[2]).encodeABI()})
        await web3.eth.sendTransaction({to:oracle.address,from:accounts[1],gas:700000,data:oracle2.methods.transferFrom(accounts[2], accounts[5], t2).encodeABI()})
        balance5a = await web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[5]).encodeABI()});
        assert.equal(web3.utils.fromWei(balance5a), 1006, "balance for acct 5 is 1006");
        allow = await web3.eth.call({to:oracle.address,data:oracle2.methods.allowance(accounts[2],accounts[1]).encodeABI()});
        assert.equal(web3.utils.fromWei(allow, 'ether'), 1, "Allowance shoudl be 1 eth");
    });

   it("Total Supply", async function(){
        supply = await web3.eth.call({to:oracle.address,data:oracle2.methods.totalSupply().encodeABI()});
        assert.equal(web3.utils.fromWei(supply),5000,"Supply should be 10000");
    });

    it("re-Staking without withdraw ", async function(){
    	await helper.advanceTime(86400 * 10);
        let withdrawreq = await web3.eth.sendTransaction({to:oracle.address,from:accounts[1],gas:7000000,data:oracle2.methods.requestWithdraw().encodeABI()})
        let weSender =  await web3.eth.abi.decodeParameter('address',withdrawreq.logs[0].data);
        assert(weSender == accounts[1], "withdraw request by account 1");
        await helper.advanceTime(86400 * 10);
        assert(await web3.eth.call({to:oracle.address,data:oracle2.methods.isStaked(accounts[1]).encodeABI()}) == false, "is not Staked" );
        await web3.eth.sendTransaction({to:oracle.address,from:accounts[1],gas:7000000,data:oracle2.methods.depositStake().encodeABI()})
        assert(await web3.eth.call({to:oracle.address,data:oracle2.methods.isStaked(accounts[1]).encodeABI()}) == true, "Staked" );
    });    

    it("withdraw and re-stake", async function(){
    	await helper.advanceTime(86400 * 10);
        let withdrawreq = await web3.eth.sendTransaction({to:oracle.address,from:accounts[1],gas:7000000,data:oracle2.methods.requestWithdraw().encodeABI()})
        let weSender =  await web3.eth.abi.decodeParameter('address',withdrawreq.logs[0].data);
        assert(weSender == accounts[1], "withdraw request by account 1");
        await helper.advanceTime(86400 * 10);
        assert(await web3.eth.call({to:oracle.address,data:oracle2.methods.isStaked(accounts[1]).encodeABI()}) == false, "is not Staked" );
        await web3.eth.sendTransaction({to:oracle.address,from:accounts[1],gas:7000000,data:oracle2.methods.withdrawStake().encodeABI()})
        assert(await web3.eth.call({to:oracle.address,data:oracle2.methods.isStaked(accounts[1]).encodeABI()}) == false, " not Staked" );
        await web3.eth.sendTransaction({to:oracle.address,from:accounts[1],gas:7000000,data:oracle2.methods.depositStake().encodeABI()}) 
        assert(await web3.eth.call({to:oracle.address,data:oracle2.methods.isStaked(accounts[1]).encodeABI()}) == true, " Staked" );
    }); 
    it("Attempt to transfer more than balance - stake", async function(){
        var tokens = web3.utils.toWei('1', 'ether');
        var tokens2 = web3.utils.toWei('2', 'ether');
        await web3.eth.sendTransaction({to:oracle.address,from:accounts[2],gas:7000000,data:oracle2.methods.transfer(accounts[1],tokens).encodeABI()})
        balance1 = await web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[1]).encodeABI()});
        await helper.expectThrow(web3.eth.sendTransaction({to:oracle.address,from:accounts[1],gas:7000000,data:oracle2.methods.transfer(accounts[1],tokens2).encodeABI()}));
        balance1b = await web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[1]).encodeABI()});
        assert( web3.utils.fromWei(balance1b) == 1001, "Balance should == (1000 + tokens)");
    });

    it("Attempt to Allow and transferFrom more than balance - stake", async function(){
        var tokens = web3.utils.toWei('2', 'ether');
        var tokens2 = web3.utils.toWei('3', 'ether');
        await web3.eth.sendTransaction({to:oracle.address,from:accounts[2],gas:7000000,data:oracle2.methods.transfer(accounts[1],tokens).encodeABI()})
        balance1 = await web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[1]).encodeABI()});
        await helper.expectThrow(web3.eth.sendTransaction({to:oracle.address,from:accounts[1],gas:7000000,data:oracle2.methods.approve(accounts[6],tokens2).encodeABI()}));
        await helper.expectThrow(web3.eth.sendTransaction({to:oracle.address,from:accounts[6],gas:7000000,data:oracle2.methods.transferFrom(accounts[1], accounts[8],tokens2).encodeABI()}));
        balance1b = await web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[1]).encodeABI()}); 
        assert((1000 + web3.utils.fromWei(tokens)*1) == web3.utils.fromWei(balance1)*1, "Balance for acct 1 should == 1000 + transferred amt ");
    });

    it("Attempt to withdraw before stake time is up", async function(){ 
        balance1b = await ( web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[1]).encodeABI()}));
        await helper.expectThrow(web3.eth.sendTransaction({to:oracle.address,from:accounts[1],gas:7000000,data:oracle2.methods.withdrawStake().encodeABI()}) );
        assert(await web3.eth.call({to:oracle.address,data:oracle2.methods.isStaked(accounts[1]).encodeABI()}) == true, "still isStaked" );
        assert(web3.utils.fromWei(balance1b) == 1000, "Balance should equal transferred amt");
    });

    it("Staking, requestWithdraw, withdraw stake", async function(){
        let withdrawreq = await web3.eth.sendTransaction({to:oracle.address,from:accounts[1],gas:7000000,data:oracle2.methods.requestWithdraw().encodeABI()})
        let weSender =  await web3.eth.abi.decodeParameter('address',withdrawreq.logs[0].data);
        assert(weSender == accounts[1], "withdraw request by account 1");
        await helper.advanceTime(86400 * 8);
        assert(await web3.eth.call({to:oracle.address,data:oracle2.methods.isStaked(accounts[1]).encodeABI()}) == false, "is not Staked" );//should the requestWitdraw change the stakeState
        await web3.eth.sendTransaction({to:oracle.address,from:accounts[1],gas:7000000,data:oracle2.methods.withdrawStake().encodeABI()})
        assert(await web3.eth.call({to:oracle.address,data:oracle2.methods.isStaked(accounts[1]).encodeABI()}) == false, " not Staked" );
    });

    it("getVariables", async function(){
    	let res = await web3.eth.sendTransaction({to:oracle.address,from:accounts[2],gas:7000000,data:oracle2.methods.requestData(api,0,1000,20).encodeABI()}) 
        vars = await oracle.getVariables();
        let miningApiId =vars['1'];
        let difficulty = vars['2']
        let sapi = vars['3'];
        assert(miningApiId == 1, "miningApiId should be 1");
        assert(difficulty == 1, "Difficulty should be 1");
        assert.equal(sapi,api, "sapi = api");
        assert(vars['4'] ==1000)
    }); 

    it("Get apiId", async function () {
        balance1 = await web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[2]).encodeABI()})
        let res = await web3.eth.sendTransaction({to:oracle.address,from:accounts[2],gas:7000000,data:oracle2.methods.requestData(api,0,1000,20).encodeABI()}) 
        apiHash = await oracle.getApiHash(1)
        apiId = await oracle.getApiId(apiHash) 
        assert(apiId == 1, "apiId should be 1");
    });

    it("Get apiHash", async function () {
        balance1 = await web3.eth.call({to:oracle.address,data:oracle2.methods.balanceOf(accounts[2]).encodeABI()})
        let res = await web3.eth.sendTransaction({to:oracle.address,from:accounts[2],gas:7000000,data:oracle2.methods.requestData(api,0,1000, 20).encodeABI()}) 
        let resApiHash = await web3.eth.abi.decodeParameters(['uint256','string','bytes32','uint256'],res.logs[1].data);
        apiHash = await web3.eth.call({to:oracle.address,data:oracle2.methods.getApiHash(1).encodeABI()})
        assert(web3.utils.hexToNumberString(apiHash) == web3.utils.hexToNumberString(resApiHash['2']), "api on Q should be apiId");
    });
});
