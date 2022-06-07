require('dotenv').config();

const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",     
      port: 8545,            
      network_id: "*",       
    },
    main: {
      provider: function() {
        return new HDWalletProvider(
          //private keys array
          process.env.MNEMONIC,
          //url to ethereum node
          process.env.MAIN_WEB3_PROVIDER_ADDRESS
        )
      },
      network_id: 1,
      gas: process.env.GAS,
      gasPrice: process.env.GAS_PRICE,
      confirmations: 2,
      websockets: true
    },
    ropsten: {
      networkCheckTimeout: 10000, 
      provider: function() {
        return new HDWalletProvider(
          //private keys array
          process.env.MNEMONIC,
          //url to ethereum node
          process.env.ROPSTEN_WEB3_PROVIDER_ADDRESS
        )
      },
      network_id: 3,
      gas: 4000000,
      gasPrice: 50000000000,
      confirmations: 2,
      websockets: true
    },
  },
  compilers: {
    solc: {
      version: "0.8.7",
    }
  },
  plugins: [
    'truffle-plugin-verify'
  ],
  api_keys: {
    etherscan: process.env.ETHERSCAN_API
  }
};