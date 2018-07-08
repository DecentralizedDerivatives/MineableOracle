/*this contract tests the typical workflow from the dApp (user contract, cash out)*/
var oracleToken = artifacts.require("OracleToken");

contract('Base Tests', function(accounts) {
  let oracletoken;
  

  beforeEach('Setup contract for each test', async function () {
     oracletoken = await oracleToken.new();
  });

  it("Set difficulty", async function(){
    await oracletoken.setDifficulty(1);
    let variables = await oracletoken.getVariables(); 
    assert(variables = [0x0000000000000000000000000000000000000000000000000000000000000000,1] , "Diffiuculty= 1");
  });

  it("testAdd", async function(){
    await oracletoken.testAdd(1531008000,100);
    let data = await oracletoken.retrieveData(1531008000); 
    assert(data = 100 , "data=100");
  });

  it("Token Transfer", async function(){
    // balance2 = await (oracletoken.balanceOf(accounts[2]));
    // console.log(balance2);
    // await oracletoken.transfer(accounts[2], 5);
    // balance2x = await (oracletoken.balanceOf(accounts[2]));
    // console.log(balance2x);
    // assert(balance2-balance2x == 5 , "5");
  });


  it("Token Approval and Transfer", async function(){

  });
  it("Sample Mine Token", async function(){

  });
  it("Mine tokens and get 20 values", async function(){
    
  });

    it("proofOfWork", async function(){
    
/*  balance3 = await (oracletoken.balanceOf(accounts[3]));
    balance4 = await (oracletoken.balanceOf(accounts[4]));
    balance5 = await (oracletoken.balanceOf(accounts[5]));
    balance6 = await (oracletoken.balanceOf(accounts[6]));*/
    console.log("1 proof of work");
    await oracletoken.proofOfWork("1531005060", 100, {from: accounts[0]});
    await oracletoken.proofOfWork("1531005060", 100, {from: accounts[0]});
    await oracletoken.proofOfWork("1531005060", 100, {from: accounts[0]});
    await oracletoken.proofOfWork("1531005060", 100, {from: accounts[0]});
    let res = await oracletoken.proofOfWork("1531005060", 100, {from: accounts[0]});
    //  res = res.logs[0].args;

     res = res.logs[6].args._time
          console.log(res);
     let data = await oracletoken.retrieveData(res); 
    assert(data = 100 , "data=100");
    balance2x = await (oracletoken.balanceOf(accounts[0]));
    console.log(balance2x);

     console.log("2 proof of work");

/*    await oracletoken.setDifficulty(1,{from: accounts[1]});
     console.log("3");
    await oracletoken.proofOfWork(1531005120, 101, {from: accounts[3]});
     console.log("4");
    await oracletoken.setDifficulty(1,{from: accounts[1]});
     console.log("5");
    await oracletoken.proofOfWork(1531005180, 102, {from: accounts[4]});
     console.log("6");
    await oracletoken.setDifficulty(1,{from: accounts[1]});
     console.log("7");
    await oracletoken.proofOfWork(1531005240, 103, {from: accounts[5]});
     console.log("8");
    await oracletoken.setDifficulty(1,{from: accounts[1]});
     console.log("9");*/
/*    await oracletoken.proofOfWork(1531005300, 105, {from: accounts[6]});
    balance2x = await (oracletoken.balanceOf(accounts[2]));
    balance3x = await (oracletoken.balanceOf(accounts[3]));
    balance4x = await (oracletoken.balanceOf(accounts[4]));
    balance5x = await (oracletoken.balanceOf(accounts[5]));
    balance6x = await (oracletoken.balanceOf(accounts[6]));
    assert.equal(balance2-balance2x, 1, "balance should be one for acct2");
   assert.equal(balance6-balance6x, 1, "balance should be one for acct6");
    assert.equal(balance3-balance3x, 5, "balance should be 5 for acct3");
    assert.equal(balance5-balance5x, 5, "balance should be 5 for acct5");
    assert.equal(balance3-balance3x, 10, "balance should be one for acct3");
  */});


});
