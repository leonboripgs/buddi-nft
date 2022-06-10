// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/*
░██████╗███╗░░██╗██████╗░░█████╗░██████╗░██╗░░░██╗██████╗░████████╗░█████╗░░██████╗
██╔════╝████╗░██║██╔══██╗██╔══██╗██╔══██╗╚██╗░██╔╝██╔══██╗╚══██╔══╝██╔══██╗██╔════╝
╚█████╗░██╔██╗██║██████╔╝██║░░╚═╝██████╔╝░╚████╔╝░██████╔╝░░░██║░░░██║░░██║╚█████╗░
░╚═══██╗██║╚████║██╔══██╗██║░░██╗██╔══██╗░░╚██╔╝░░██╔═══╝░░░░██║░░░██║░░██║░╚═══██╗
██████╔╝██║░╚███║██║░░██║╚█████╔╝██║░░██║░░░██║░░░██║░░░░░░░░██║░░░╚█████╔╝██████╔╝
╚═════╝░╚═╝░░╚══╝╚═╝░░╚═╝░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░░░░░░░░╚═╝░░░░╚════╝░╚═════╝░

██████╗░██╗░░░██╗██████╗░██████╗░██╗  ░██████╗░░█████╗░███╗░░░███╗███████╗░██████╗
██╔══██╗██║░░░██║██╔══██╗██╔══██╗██║  ██╔════╝░██╔══██╗████╗░████║██╔════╝██╔════╝
██████╦╝██║░░░██║██║░░██║██║░░██║██║  ██║░░██╗░███████║██╔████╔██║█████╗░░╚█████╗░
██╔══██╗██║░░░██║██║░░██║██║░░██║██║  ██║░░╚██╗██╔══██║██║╚██╔╝██║██╔══╝░░░╚═══██╗
██████╦╝╚██████╔╝██████╔╝██████╔╝██║  ╚██████╔╝██║░░██║██║░╚═╝░██║███████╗██████╔╝
╚═════╝░░╚═════╝░╚═════╝░╚═════╝░╚═╝  ░╚═════╝░╚═╝░░╚═╝╚═╝░░░░░╚═╝╚══════╝╚═════╝░
*/

contract BuddiCollection is ERC1155Supply, Ownable {
    using ECDSA for bytes32;

    // BUDDI RUNNER DNA TOKEN IDs
    uint256 public constant DNA_WHALE = 0;
    uint256 public constant DNA_SPIDER = 1;
    uint256 public constant DNA_SLOTH = 2;
    uint256 public constant DNA_ARMADILLO = 3;
    uint256 public constant DNA_CROCODILE = 4;

    uint256 public constant MAX_SUPPLY = 2000;
    uint256 public constant PER_WALLET_LIMIT = 10;

    uint256 public tokenPrice;
    bool public saleIsActive;
    bool public isPaused;

    string private name_;
    string private symbol_; 

    address public signerAddress;

    address public royaltyAddress;
    uint256 public ROYALTY_SIZE = 500; // 5%
    uint256 public ROYALTY_DENOMINATOR = 10000;

    mapping(uint256 => address) private _royaltyReceivers;
    mapping (address => uint256) private _mintedPerAddress;

    event TokensMinted(
      address mintedBy,
      uint256 tokensNumber
    );

    constructor(
      string memory _name,
      string memory _symbol,
      string memory _uri,
      address _royalty
    ) ERC1155(_uri) {
      name_ = _name;
      symbol_ = _symbol;
      royaltyAddress = _royalty;

      tokenPrice = 0.05 ether;
    }
    
    function name() public view returns (string memory) {
      return name_;
    }

    function symbol() public view returns (string memory) {
      return symbol_;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) external view returns (address receiver, uint256 royaltyAmount) {
      uint256 amount = _salePrice * ROYALTY_SIZE / ROYALTY_DENOMINATOR;
      address royaltyReceiver = _royaltyReceivers[_tokenId] != address(0) ? _royaltyReceivers[_tokenId] : royaltyAddress;
      return (royaltyReceiver, amount);
    }

    function addRoyaltyReceiverForTokenId(address receiver, uint256 tokenId) public onlyOwner {
      _royaltyReceivers[tokenId] = receiver;
    }

    // function purchase(uint256 [] memory tokensToMint, bytes calldata signature) public payable {
    function purchase(uint256 [] memory tokensToMint) public payable {
      require(saleIsActive, "The mint has not started yet");
      require(tokensToMint.length == 5, "Wrong Purchase Request");

      uint256 totalPurchaseCount = 0;

      for (uint256 dnaType = 0; dnaType < 5; dnaType++) {
        totalPurchaseCount += tokensToMint[dnaType];
        require(totalSupply(dnaType) + tokensToMint[dnaType] <= MAX_SUPPLY, "You tried to mint more than the max allowed");
      }

      require(totalPurchaseCount > 0, "Wrong amount requested");

      if (_msgSender() != owner()) {
        require(_mintedPerAddress[_msgSender()] + totalPurchaseCount <= PER_WALLET_LIMIT, "You have hit the max tokens per wallet");
        require(totalPurchaseCount * tokenPrice == msg.value,
          "You have not sent enough ETH"
        );
        _mintedPerAddress[_msgSender()] += totalPurchaseCount;
      }

      for (uint256 dnaType = 0; dnaType < 5; dnaType++) {
        _mint(_msgSender(), dnaType, tokensToMint[dnaType], "");
      }

      emit TokensMinted(_msgSender(), totalPurchaseCount);
    }

    function updateSaleStatus(bool status) public onlyOwner {
      require(tokenPrice != 0, "Price is not set");
      saleIsActive = status;
    }
    
    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
      require(!saleIsActive, "Price cannot be changed while sale is active");
      tokenPrice = _tokenPrice;
    }

    function withdraw() external onlyOwner {
      uint256 balance = address(this).balance;
      payable(owner()).transfer(balance);
    }

    function pause(bool _isPaused) external onlyOwner {
      isPaused = _isPaused;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        require(!isPaused, "ERC1155Pausable: token transfer while paused");
    }
}