/** 
* This contract tests the Oracle functions
*/ 
var Oracle = artifacts.require("./Oracle.sol");


var timeframe = (86400); //Daily
var api = 'json(https://api.gdax.com/products/BTC-USD/ticker).price';
var api2 = 'json(https://api.gdax.com/products/ETH-USD/ticker).price';

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

/*
contract('PoW Token Tests', function(accounts) {
  let oracle;
    beforeEach('Setup contract for each test', async function () {
        oracle = await Oracle.new(10,[1e18,5e18,10e18,5e18,1e18]);
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

    it("Total Supply", async function(){
        supply = await oracle.totalSupply();
        supply1 = supply.toNumber();
        assert.equal(supply1,10000000000000000000000,"Supply should be 10000");
        contra = await oracle.balanceOf(oracle.address);
        contra1 = contra.toNumber();
        contrabal= 2**256 -  10000000000000000000000;
        assert.equal(contra1,contrabal,"Contract balance should be max");

    });


});
 */