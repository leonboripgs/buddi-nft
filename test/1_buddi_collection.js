const BuddiCollection = artifacts.require("BuddiCollection");
const BuddiNFT = artifacts.require("BuddiNFT");

const truffleAssert = require('truffle-assertions');
const assert = require('assert');

const { ethers } = require('ethers');

contract('Buddi Collection Contract', async (accounts) => {
    let buddiCollection;
    let buddiNFT;
    beforeEach(async () => {
        buddiCollection = await BuddiCollection.deployed();
        buddiNFT = await BuddiNFT.deployed();
    });

    it("[BuddiCollection] sale not started yet", async () => {
        await truffleAssert.fails(
            buddiCollection.purchase([3, 0, 1, 1, 2], {from: accounts[1], value: ethers.utils.parseEther("0.1")}),
            truffleAssert.ErrorType.REVERT,
            "The mint has not started yet"
        );
    });
    it("[BuddiCollection] sale start", async () => {
        await truffleAssert.passes(
            buddiCollection.updateSaleStatus(true),
            'ERROR: updating sales status failed'
        );
        let saleIsActive = await buddiCollection.saleIsActive();
        assert.equal(saleIsActive, true);
    });
    it("[BuddiCollection] try to purchase with not enough eth", async () => {
        await truffleAssert.fails(
            buddiCollection.purchase([3, 0, 1, 1, 2], {from: accounts[1], value: ethers.utils.parseEther("0.1")}),
            truffleAssert.ErrorType.REVERT,
            "You have not sent enough ETH"
        );
    });
    it("[BuddiCollection] try to purchase with enough eth", async () => {
        var prevEthBalance = await web3.eth.getBalance(accounts[1]);
        await truffleAssert.passes(
            buddiCollection.purchase([3, 0, 1, 1, 2], {from: accounts[1], value: ethers.utils.parseEther("0.35")}),
            "ERROR: minting with enough eth",
        );
        var buddiCollectionBalance = await web3.eth.getBalance(buddiCollection.address);
        var curEthBalance = await web3.eth.getBalance(accounts[1]);

        assert.notEqual(prevEthBalance, curEthBalance, 'buyer balance should be changed');
        assert.equal(ethers.utils.parseEther("0.35"), buddiCollectionBalance, 'buddi balance should be changed');

        // check minted NFT count
        var nftBalance0 = await buddiCollection.balanceOf(accounts[1], 0);
        var nftBalance1 = await buddiCollection.balanceOf(accounts[1], 1);
        var nftBalance2 = await buddiCollection.balanceOf(accounts[1], 2);
        var nftBalance3 = await buddiCollection.balanceOf(accounts[1], 3);
        var nftBalance4 = await buddiCollection.balanceOf(accounts[1], 4);
        assert.equal(nftBalance0, 3, "type 0 minted incorrectly");
        assert.equal(nftBalance1, 0, "type 1 minted incorrectly");
        assert.equal(nftBalance2, 1, "type 2 minted incorrectly");
        assert.equal(nftBalance3, 1, "type 3 minted incorrectly");
        assert.equal(nftBalance4, 2, "type 4 minted incorrectly");
    });

    it("[BuddiNFT] sale not started yet", async () => {
        await truffleAssert.fails(
            buddiNFT.mintPassPurchase([3, 0, 1, 1, 2], {from: accounts[1]}),
            truffleAssert.ErrorType.REVERT,
            "The mint has not started yet"
        );
    });
    it("[BuddiNFT] sale start", async () => {
        await truffleAssert.passes(
            buddiNFT.updateSaleStatus(true),
            'ERROR: updating sales status failed'
        );
        let saleIsActive = await buddiNFT.saleIsActive();
        assert.equal(saleIsActive, true);
    });
    it("[BuddiNFT] mintpass - fail with not enough passes", async () => {
        // currently type 0 nft only passes 3 but let's try with 4
        await truffleAssert.fails(
            buddiNFT.mintPassPurchase([4, 0, 1, 1, 2], {from: accounts[1]}),
            truffleAssert.ErrorType.REVERT,
            "Not enough passes"
        );
    });
    it("[BuddiNFT] mintpass - success with enough passes", async () => {
        await truffleAssert.passes(
            buddiNFT.mintPassPurchase([3, 0, 1, 1, 2], {from: accounts[1]})
        );
        var buddiCnt = await buddiNFT.balanceOf(accounts[1]);
        assert.equal(buddiCnt, 7);
        var tokenId = await buddiNFT.tokenOfOwnerByIndex(accounts[1], 0);
        assert.equal(tokenId, 0);
        tokenId = await buddiNFT.tokenOfOwnerByIndex(accounts[1], 1);
        assert.equal(tokenId, 1);
        tokenId = await buddiNFT.tokenOfOwnerByIndex(accounts[1], 2);
        assert.equal(tokenId, 2);
        tokenId = await buddiNFT.tokenOfOwnerByIndex(accounts[1], 3);
        assert.equal(tokenId, 4000);
        tokenId = await buddiNFT.tokenOfOwnerByIndex(accounts[1], 4);
        assert.equal(tokenId, 6000);
        tokenId = await buddiNFT.tokenOfOwnerByIndex(accounts[1], 5);
        assert.equal(tokenId, 8000);
        tokenId = await buddiNFT.tokenOfOwnerByIndex(accounts[1], 6);
        assert.equal(tokenId, 8001);
    });
})