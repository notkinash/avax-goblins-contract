// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "erc721a/contracts/extensions/ERC721ABurnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract AvaxGoblins is ERC721AQueryable, ERC721ABurnable, Ownable, ReentrancyGuard, Pausable {
    uint256 public mintPrice;

    // Limits

    uint256 public collectionSize;

    // Controls

    bool public mintAvailable;

    bool public publicSale;

    string private _defaultBaseURI;

    mapping(address => bool) public whitelist;

    // Royalties

    address public royaltiesReceiver;

    uint96 public royaltiesFraction;

    uint96 private constant _feeDenominator = 10000; // 10k; this represents 100%

    // Constructor
    
    constructor(
        uint256 _mintPrice,
        uint256 _collectionSize,
        address _royaltiesReceiver,
        uint96 _royaltiesFraction,
        string memory _metadataURI
    ) ERC721A("Avax Goblins", "GBLN") {
        mintPrice = _mintPrice;
        collectionSize = _collectionSize;
        royaltiesReceiver = _royaltiesReceiver;
        royaltiesFraction = _royaltiesFraction;
        _defaultBaseURI = _metadataURI;
    }

    // Minting functions

    function mint(uint256 quantity) external payable {
        // Check if mint is available
        require(mintAvailable, "Mint isn't available yet");

        // Check if minter is whitelisted or is public sale
        require(whitelisted(msg.sender) || publicSale, "Not whitelisted or not public sale");

        // Check if there is enough tokens available
        uint256 nextTotalMinted = _totalMinted() + quantity;
        require(nextTotalMinted <= collectionSize, "Sold out");

        // Check if minter is paying the correct price
        uint256 price = quantity * mintPrice;
        require(msg.value == price, "Wrong given price");

        _mint(msg.sender, quantity);
    }

    function give(address to, uint256 quantity) external onlyOwner {
        // Check if there is enough tokens available
        uint256 nextTotalMinted = _totalMinted() + quantity;
        require(nextTotalMinted <= collectionSize, "Sold out");

        _mint(to, quantity);
    }

    // Whitelist functions

    function whitelisted(address target) public view returns (bool) {
        return whitelist[target];
    }

    function whitelistAdd(address target) external onlyOwner {
        whitelist[target] = true;
    }

    function whitelistMulti(address[] calldata targets) external onlyOwner {
        for (uint256 i = 0; i < targets.length; i++) {
            whitelist[targets[i]] = true;
        }
    }

    function whitelistRemove(address target) external onlyOwner {
        whitelist[target] = false;
    }

    // Control functions

    function toggleMint() external onlyOwner {
        mintAvailable = !mintAvailable;
    }

    function togglePublicSale() external onlyOwner {
        publicSale = !publicSale;
    }

    function togglePause() external onlyOwner {
        paused() ? _unpause() : _pause();
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
    }

    function setCollectionSize(uint256 newSize) external onlyOwner {
        collectionSize = newSize;
    }

    function setBaseURI(string calldata newURI) external onlyOwner {
        _defaultBaseURI = newURI;
    }

    function setRoyaltiesReceiver(address to) external onlyOwner {
        royaltiesReceiver = to;
    }

    function setRoyaltiesFraction(uint96 newFraction) external onlyOwner {
        require(newFraction <= _feeDenominator, "Royalties percentage cannot be higher than 100%");
        royaltiesFraction = newFraction;
    }

    // Special functions

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "Withdraw failed");
    }

    function royaltyInfo(uint256, uint256 salePrice) external view returns (address, uint256) {
        uint256 royaltyAmount = (salePrice * royaltiesFraction) / _feeDenominator;
        return (royaltiesReceiver, royaltyAmount);
    }

    // Override functions

    function supportsInterface(bytes4 interfaceId) public view override(IERC721A, ERC721A) returns (bool) {
        return 
            interfaceId == 0x2a55205a || // ERC165 interface ID for ERC2981.
            super.supportsInterface(interfaceId);
    }

    function tokenURI(uint256 tokenId) public view override(IERC721A, ERC721A) returns (string memory) {
        return string(abi.encodePacked(_defaultBaseURI, _toString(tokenId), ".json"));
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        require(!paused(), "Token transfers paused");
    }
}