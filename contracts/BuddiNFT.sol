// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./utils/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract BuddiNFT is
    Context,
    ERC721Enumerable,
    Ownable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using Strings for uint256;
    using ECDSA for bytes32;

    // currentSupply
    uint256 private currentSupply;

    // Provenance hash
    string public PROVENANCE_HASH;

    // Base URI
    string private _buddiBaseURI;

    // Starting Index
    uint256 public startingIndex;

    // Max number of NFTs
    uint256 public constant MAX_SUPPLY = 10000;
    uint256 public constant MAX_PER_TRANSACTION = 50;
    uint256 public constant MAX_SUPPLY_PER_DNA = 2000;

    bool public saleIsActive;
    bool public signatureClaimIsActive;
    bool public metadataRevealed;
    bool public metadataFinalised;

    // Royalty info
    address public signerAddress;
    address public royaltyAddress;
    uint256 public ROYALTY_SIZE = 750;
    uint256 public ROYALTY_DENOMINATOR = 10000;
    mapping(uint256 => address) private _royaltyReceivers;

    // Mint pass contracts
    IERC1155 public BuddiCollection;

    // Stores the number of minted tokens through mintpasses
    mapping(address => mapping(uint => uint256)) public _mintPassesUsed;
    mapping(uint => uint256) public _mintPassesUsedByDnaType; // total nfts by types
    mapping(address => uint256) public _usedNonces;

    //   bytes32 internal keyHash;
    uint256 internal fee;

    event TokensMinted(address indexed mintedBy, uint256 indexed tokensNumber);

    event startingIndexFinalized(uint256 indexed startingIndex);

    event baseUriUpdated(string oldBaseUri, string newBaseUri);

    constructor(
        address _royaltyAddress,
        address _signerAddress,
        address _buddiCollection,
        string memory _baseURI
    ) ERC721("Buddi Runner", "BUD") {
        royaltyAddress = _royaltyAddress;
        signerAddress = _signerAddress;

        BuddiCollection = IERC1155(_buddiCollection);

        // keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10**18;

        _buddiBaseURI = _baseURI;
    }

    function mintPassPurchase(uint256 [] memory tokensToMint)
        public
        nonReentrant
    {
        if (_msgSender() != owner())
            require(saleIsActive, "The mint has not started yet");

        require(tokensToMint.length == 5, "Wrong Purchase Request");

        uint256 totalMintCount = 0;

        for (uint dnaType = 0; dnaType < 5; dnaType++ ) {
            totalMintCount += tokensToMint[dnaType];
        }
        require(
            totalMintCount <= MAX_PER_TRANSACTION,
            "You can mint max 50 tokens per transaction"
        );
        require(
            totalSupply().add(totalMintCount) <= MAX_SUPPLY,
            "Mint more Buddi that allowed"
        );

        for (uint dnaType = 0; dnaType < 5; dnaType++) {
            uint256 passesLeft = BuddiCollection
                .balanceOf(_msgSender(), dnaType)
                .sub(_mintPassesUsed[_msgSender()][dnaType]);

            require(
                tokensToMint[dnaType] <= passesLeft,
                "Not enough passes"
            );

            uint256 mintStartTokenId = MAX_SUPPLY_PER_DNA * dnaType + _mintPassesUsedByDnaType[dnaType];
            _mintPassesUsed[_msgSender()][dnaType] += tokensToMint[dnaType];
            for (uint256 i = 0; i < tokensToMint[dnaType]; i++) {
                _safeMint(_msgSender(), mintStartTokenId + i );
            }
            _mintPassesUsedByDnaType[dnaType] += tokensToMint[dnaType];
        }

        emit TokensMinted(_msgSender(), totalMintCount);
    }

    function signatureClaim(
        uint256 tokensToMint,
        uint256 nonce,
        bytes calldata signature
    ) public nonReentrant {
        if (_msgSender() != owner())
            require(signatureClaimIsActive, "The mint has not started yet");
        require(
            tokensToMint <= MAX_PER_TRANSACTION,
            "You can mint max 50 tokens per transaction"
        );
        require(
            totalSupply().add(tokensToMint) <= MAX_SUPPLY,
            "Mint more creepz that allowed"
        );

        require(
            _validateSignature(signature, tokensToMint, nonce, _msgSender()),
            "Wrong data passed into the contract"
        );
        require(_usedNonces[_msgSender()] < nonce, "Already claimed");

        _usedNonces[_msgSender()] = nonce;
        for (uint256 i = 0; i < tokensToMint; i++) {
            _safeMint(_msgSender(), totalSupply());
        }

        emit TokensMinted(_msgSender(), tokensToMint);
    }

    function _validateSignature(
        bytes calldata signature,
        uint256 tokensToMint,
        uint256 nonce,
        address caller
    ) internal view returns (bool) {
        bytes32 dataHash = keccak256(
            abi.encodePacked(tokensToMint, nonce, caller)
        );
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

        address receivedAddress = ECDSA.recover(message, signature);
        return (receivedAddress != address(0) &&
            receivedAddress == signerAddress);
    }

    function emergencyMint(uint256 tokensToMint) public onlyOwner {
        require(
            totalSupply().add(tokensToMint) <= MAX_SUPPLY,
            "Mint more creepz that allowed"
        );

        for (uint256 i = 0; i < tokensToMint; i++) {
            _safeMint(_msgSender(), totalSupply());
        }

        emit TokensMinted(_msgSender(), tokensToMint);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        uint256 amount = _salePrice.mul(ROYALTY_SIZE).div(ROYALTY_DENOMINATOR);
        address royaltyReceiver = _royaltyReceivers[_tokenId] != address(0)
            ? _royaltyReceivers[_tokenId]
            : royaltyAddress;
        return (royaltyReceiver, amount);
    }

    function addRoyaltyReceiverForTokenId(address receiver, uint256 tokenId)
        public
        onlyOwner
    {
        _royaltyReceivers[tokenId] = receiver;
    }

    function updateSaleStatus(bool status) public onlyOwner {
        saleIsActive = status;
    }

    function updateSignatureClaimStatus(bool status) public onlyOwner {
        signatureClaimIsActive = status;
    }

    // function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    //     require(
    //         bytes(PROVENANCE_HASH).length == 0,
    //         "Provenance hash has already been set"
    //     );
    //     PROVENANCE_HASH = provenanceHash;
    // }

    function setBaseURI(string memory newBaseURI) public onlyOwner {
        require(!metadataFinalised, "Metadata already revealed");

        string memory currentURI = _buddiBaseURI;
        _buddiBaseURI = newBaseURI;
        emit baseUriUpdated(currentURI, newBaseURI);
    }

    // function finalizeStartingIndex() public onlyOwner returns (bytes32 requestId) {
    //   require(startingIndex == 0, 'startingIndex already set');

    //   require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
    //   return requestRandomness(keyHash, fee);
    // }

    // /**
    //  * Callback function used by VRF Coordinator
    //  */
    // function fulfillRandomness(bytes32, uint256 randomness) internal override {
    //     startingIndex = (randomness % MAX_SUPPLY);
    //     emit startingIndexFinalized(startingIndex);
    // }

    function tokenURI(uint256 tokenId)
        external
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (!metadataRevealed) return _buddiBaseURI;
        return string(abi.encodePacked(_buddiBaseURI, tokenId.toString()));
    }

    function revealMetadata() public onlyOwner {
        require(!metadataRevealed, "Metadata already revealed");
        metadataRevealed = true;
    }

    function finalizeMetadata() public onlyOwner {
        require(!metadataFinalised, "Metadata already finalised");
        metadataFinalised = true;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }
}
