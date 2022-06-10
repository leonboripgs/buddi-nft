var fs = require('fs');

const BuddiNFT = artifacts.require("BuddiNFT");
const BuddiCollection = artifacts.require("BuddiCollection");

module.exports = async function (deployer) {
  try {
    let contracts = {};

    const royaltyAddress = process.env.ROYALTY_ADDRESS;

    await deployer.deploy(
      BuddiCollection, "BuddiCollection", "BUDC", "", royaltyAddress);
    contracts['BuddiCollection - Contract'] = BuddiCollection.address;

    await deployer.deploy(
      BuddiNFT, royaltyAddress, BuddiCollection.address, "");
    contracts['BuddiNFT - Contract'] = BuddiCollection.address;

    await fs.promises.writeFile('contracts.json', JSON.stringify(contracts));
  } catch (error) {
    console.log(error);
  }
};
