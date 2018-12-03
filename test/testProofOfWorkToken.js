// /** This contract tests the ProofOfWorkToken functions
// */ 
// var oracleToken = artifacts.require("./OracleToken.sol");
// var proofOfWorkToken = artifacts.require("./ProofOfWorkToken.sol");

// var timeframe = (86400); //Daily
// var api = 'json(https://api.gdax.com/products/BTC-USD/ticker).price';
// var api2 = 'json(https://api.gdax.com/products/ETH-USD/ticker).price';

// async function expectThrow(promise){
//   try {
//     await promise;
//   } catch (error) {
//     // TODO: Check jump destination to destinguish between a throw
//     //       and an actual invalid jump.
//     const invalidOpcode = error.message.search('invalid opcode') >= 0;
//     // TODO: When we contract A calls contract B, and B throws, instead
//     //       of an 'invalid jump', we get an 'out of gas' error. How do
//     //       we distinguish this from an actual out of gas event? (The
//     //       testrpc log actually show an 'invalid jump' event.)
//     const outOfGas = error.message.search('out of gas') >= 0;
//     const revert = error.message.search('revert') >= 0;
//     assert(
//       invalidOpcode || outOfGas || revert,
//       'Expected throw, got \'' + error + '\' instead',
//     );
//     return;
//   }
//   assert.fail('Expected throw not received');
// };


// contract('PoW Token Tests', function(accounts) {
//   let oracletoken;
//   let proofofworktoken;
//   let logNewValueWatcher;
//     beforeEach('Setup contract for each test', async function () {
//         oracletoken = await oracleToken.new(accounts[0],1e18,(86400/60)/6,[1e18,5e18,10e18,5e18,1e18]);
//         proofofworktoken = await proofOfWorkToken.new(oracletoken.address);
//         balance0 = await (proofofworktoken.balanceOf(accounts[0],{from:accounts[0]}));
//         await proofofworktoken.transfer(accounts[4],100,{from:accounts[0]});
//         await proofofworktoken.transfer(accounts[5],100,{from:accounts[0]});
//         await proofofworktoken.transfer(accounts[6],100,{from:accounts[0]});
//         await proofofworktoken.transfer(accounts[7],100,{from:accounts[0]});
//         await proofofworktoken.transfer(accounts[8],100,{from:accounts[0]});
//         let res = await proofofworktoken.deployNewOracle(api,22,timeframe,[1e18,5e18,10e18,5e18,1e18], {from:accounts[0]});
//         res = res.logs[0].args._newOracle;
//         oracletoken = await oracleToken.at(res);   
//         let res2 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1e18,5e18,10e18,5e18,1e18], {from:accounts[0]});
//         res2 = res2.logs[0].args._newOracle;
//         oracletoken2 = await oracleToken.at(res2);
//     });

//     it("Token transfer", async function(){
//         balance4 = await proofofworktoken.balanceOf(accounts[4]);
//         await proofofworktoken.transfer(accounts[4],50,{from:accounts[6]});
//         balance4a = await proofofworktoken.balanceOf(accounts[4]);
//         balance6 = await proofofworktoken.balanceOf(accounts[6]);
//         assert.equal(balance4a, 150, "balance for acct 4 is 150");
//         assert.equal(balance6, 50, "balance for acct 6 is 50");
//     });

//     it("Approve and transferFrom", async function(){
//         await proofofworktoken.approve(accounts[1], 500);
//         balance0a = await (proofofworktoken.balanceOf(accounts[0],{from:accounts[1]}));
//         await proofofworktoken.transferFrom(accounts[0], accounts[5], 500, {from:accounts[1]}); 
//         balance5a = await (proofofworktoken.balanceOf(accounts[5]));
//         assert.equal(balance5a, 600, "balance for acct 5 is 600");
//     });

//     it("Allowance after approve and transferFrom", async function(){
//         await proofofworktoken.approve(accounts[1], 500);
//         balance0a = await (proofofworktoken.balanceOf(accounts[0],{from:accounts[1]}));
//         await proofofworktoken.transferFrom(accounts[0], accounts[5], 400, {from:accounts[1]}); 
//         balance5a = await (proofofworktoken.balanceOf(accounts[5]));
//         assert.equal(balance5a, 500, "balance for acct 5 is 600");
//         allow = await proofofworktoken.allowance(accounts[0], accounts[1]);
//         assert.equal(allow, 100, "Allowance shoudl be 100");
//     });

//     it("Total Supply", async function(){
//         supply = await proofofworktoken.totalSupply();
//         supply1 = supply.toNumber();
//         assert.equal(supply1,1000000,"Supply should be 1000000");
//         contra = await proofofworktoken.balanceOf(proofofworktoken.address);
//         contra1 = contra.toNumber();
//         contrabal= 2**256 - 1;
//         assert.equal(contra1,contrabal,"Contract balance should be max");

//     });

//     it("deploy 10 oracles", async function(){
//         let res3 = await proofofworktoken.deployNewOracle(api,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res3 = res3.logs[0].args._newOracle;
//         let res4 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res4 = res4.logs[0].args._newOracle;
//         let res5 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res5 = res5.logs[0].args._newOracle;
//         let res6 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res6 = res6.logs[0].args._newOracle;
//         let res7 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res7 = res7.logs[0].args._newOracle;
//         let res8 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res8 = res8.logs[0].args._newOracle;
//         let res9 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res9 = res9.logs[0].args._newOracle;
//         let res10 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res10 = res10.logs[0].args._newOracle;
//         let oracle_count = await proofofworktoken.getOracleCount();
//         let oracle_countn= oracle_count.toNumber();
//         assert.equal(oracle_countn, 10, "should be 10, index zero is initialized with constructor");
//     })

//         it("deploy 10 oracles, throw on 11", async function(){
//         let res3 = await proofofworktoken.deployNewOracle(api,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res3 = res3.logs[0].args._newOracle;
//         let res4 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res4 = res4.logs[0].args._newOracle;
//         let res5 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res5 = res5.logs[0].args._newOracle;
//         let res6 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res6 = res6.logs[0].args._newOracle;
//         let res7 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res7 = res7.logs[0].args._newOracle;
//         let res8 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res8 = res8.logs[0].args._newOracle;
//         let res9 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res9 = res9.logs[0].args._newOracle;
//         let res10 = await proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]});
//         res10 = res10.logs[0].args._newOracle;
//         await expectThrow(proofofworktoken.deployNewOracle(api2,22,timeframe,[1,5,10,5,1], {from:accounts[0]}));
//     })
//      it("Test GetOracleIndex", async function () {
//         let oracle_index = await proofofworktoken.getOracleIndex(oracletoken2.address);
//         let oracle_countn= oracle_index.toNumber();
//         assert.equal(oracle_countn, 2, "should be in index position 2");
//     });
// });
//  