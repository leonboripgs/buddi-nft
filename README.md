# BUDDI RUNNER NFT Contracts 🍉

This repository contains the Buddi solidity contracts.


## Setup Environment Variables

    Please copy .env.example file to .env file. And then put the following.

    MNEMONIC = YOUR PRIVATE KEY
    
    ROPSTEN_WEB3_PROVIDER_ADDRESS = https://ropsten.infura.io/v3/
    
    WEB3_PROVIDER_ADDRESS = https://mainnet.infura.io/v3/

    ETHERSCAN_API = API


## Installation

Install Node.js

```bash
sudo curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash 

nvm install 16

node -v
```
Install Truffle
```bash
npm install truffle -g
```
    
## Deployment

### Commands
#### 1.  Install necessarily Node.js packages.
    npm install     
#### 2. Deploy smart contracts to the Ethereum blockchain.
    npm run mainnet-all
#### 3. Deploy smart contracts to the Ropsten blockchain.
    npm run ropsten-all
#### 4. Truffle can test your smart contracts.
    npm run test