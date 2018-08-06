var HDWalletProvider = require("truffle-hdwallet-provider");

var mnemonic = "nick lucian brenda kevin sam fiscal patch fly damp ocean produce wish";

//Public - 0xe010ac6e0248790e08f42d5f697160dedf97e024
//Private - 3a10b4bc1258e8bfefb95b498fb8c0f0cd6964a811eabca87df5630bcacd7216


var nick = "the ureau";
//public - 0xb204edaf0410675e00e6c8a7e448a9e8e2db69aa
// private -fe5f52e7e0381448fe7d4a99e409b6da987b31362125ccb7bca781949cf61710

module.exports = {
  networks: {
    development: {
      host: "localhost",
      port: 8545,
      network_id: "*" // Match any network id
    },
    dev2: {
      host: "localhost",
      port: 8546,
      network_id: "*" // Match any network id
    },
    poa:  {
      provider: new HDWalletProvider(mnemonic, "http://40.117.249.181:8545"),
      network_id:"*",
      gas: 4612388,
      gasPrice: 17e9
    },
    ropsten: {
      provider: new HDWalletProvider(mnemonic, "https://ropsten.infura.io"),
      network_id: 3,
      gas: 4612388
    },
      rinkeby: {
      provider: new HDWalletProvider(mnemonic, "https://rinkeby.infura.io/zkGX3Vf8njIXiHEGRueB"),
      network_id: 4,
      gas: 4700000,
      gasPrice: 17e9
    }
  }
};