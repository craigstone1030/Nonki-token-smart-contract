// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Counters.sol";
import "./ERC721Pausable.sol";
import "./NonkiToken.sol";

contract NONKISHIBA is ERC721Enumerable, Ownable, ERC721Burnable, ERC721Pausable {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdTracker;

    uint256 public MAX_NFT = 777;
    uint256 public PRICE = 5 * 10**16;
    uint256 public MAX_BY_MINT = 15;
    
    address public creatorAddress;
    string public baseTokenURI;

    struct Holder {
        uint256 rewardAmount;
        uint256 startDate;
    }

    mapping(address => Holder) public holders;

    NonkiToken public nonkitoken;
    
    event CreateNonkiShiba(uint256 indexed id);
    
    constructor(string memory baseURI, address payable creator, NonkiToken _nonkitoken) ERC721("Nonki Shiba", "NONKISHIBA") {
        setBaseURI(baseURI);
        creatorAddress = creator;
        nonkitoken = _nonkitoken;
        pause(true);
    }
    
    modifier saleIsOpen {
        require(_totalSupply() <= MAX_NFT, "Sale end");
        if (_msgSender() != owner() && !isWhiteListed[_msgSender()]) {
            require(!paused(), "Pausable: paused");
        }
        _;
    }
    
    function _totalSupply() internal view returns (uint) {
        return _tokenIdTracker.current();
    }
    
    function totalMint() public view returns (uint256) {
        return _totalSupply();
    }
    
    function mint(address _to, uint256 _count) public payable saleIsOpen{
        uint256 total = _totalSupply();
        uint256 tokenCount = balanceOf(_to);
        require(total + _count <= MAX_NFT, "Max limit");
        require(total <= MAX_NFT, "Sale end");
        require(_count <= MAX_BY_MINT, "Exceeds number");
        require(tokenCount + _count <= MAX_HOLDING_NFT, "Max limit per address");
        require(msg.value >= PRICE.mul(_count), "Value below price");
        //Airdrop and Reward
        harvest(address(_to));
        nonkitoken.mint(address(_to), 100 * _count * 10**18);
        holders[address(_to)].rewardAmount = holders[address(_to)].rewardAmount.add(100 * _count * 10**18);
        for (uint256 i = 0; i < _count; i++) {
            _mintAnElement(_to);
        }
    }

    function harvest(address _to) public{
        if (holders[address(_to)].startDate != 0 && holders[address(_to)].startDate < block.timestamp) {
            uint256 diff = block.timestamp.sub(holders[address(_to)].startDate).div(86400);
            nonkitoken.mint(address(_to), balanceOf(_to) * 10 * diff * 10**18);
            holders[address(_to)].rewardAmount = holders[address(_to)].rewardAmount.add(balanceOf(_to) * 10 * diff * 10**18);
        }
        holders[address(_to)].startDate = block.timestamp;
    }
    
    function _mintAnElement(address _to) private {
        uint id = _totalSupply();
        _tokenIdTracker.increment();
        _safeMint(_to, id);
        emit CreateNonkiShiba(id);
    }

    function setCreatorAddress(address payable creator) public onlyOwner {
        creatorAddress = creator;
    }
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function walletOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function pause(bool val) public onlyOwner {
        if (val == true) {
            _pause();
            return;
        }
        _unpause();
    }

    function withdrawAll() public onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0);
        _widthdraw(creatorAddress, address(this).balance);
    }

    function _widthdraw(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        require(success, "Transfer failed.");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
    
    function updateMaxNFT(uint256 newLimit) public onlyOwner{
        MAX_NFT = newLimit;
    }

    function updateMaxMintLimit(uint256 newLimit) public onlyOwner{
       MAX_BY_MINT = newLimit;
    }
    
    function updateHoldingLimit(uint256 newLimit) public onlyOwner{
        MAX_HOLDING_NFT = newLimit;
    }

    function updatePrice(uint256 newPrice) public onlyOwner{
        PRICE = newPrice;
    }
}