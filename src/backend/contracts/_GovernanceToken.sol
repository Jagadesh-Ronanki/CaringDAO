// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/draft-ERC721Votes.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

interface IUserRegistry {
    struct User {
        string name;
        string profileCID;
        uint256 level;
        bool registered;
        uint256 appreciationBalance;
        uint256 contributionBalance;
        uint256 appreciationsTaken;
        uint256 appreciationsGiven;
        uint256 takenAmt;
        uint256 givenAmt;
        uint256 tokenId;
        bool tokenHolder;
    }
    function getUserDetails(address user) external view returns (User memory);
    function setTokenId(address _user, uint256 _tokenId) external;
}

interface IVariables {
    function retriveLevelToGovern() external view returns (uint256);
}

contract GovernanceToken is ERC721, ERC721Enumerable, ERC721URIStorage, Ownable, EIP712, ERC721Votes {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    IUserRegistry userRegistry;
    IVariables variables;

    constructor() ERC721("CaringPower", "cp") EIP712("CaringPower", "1") {
      _tokenIdCounter._value = 1;
    }

    modifier onlyActiveParticipator(address to) {
      require( !userRegistry.getUserDetails(to).tokenHolder, "~ You are already a token holder");
      require(userRegistry.getUserDetails(to).level >= variables.retriveLevelToGovern(), "Reach threshold level to mint");
      _;
    }

    function setUserRegistry(address _userRegistry) external onlyOwner {
        userRegistry = IUserRegistry(_userRegistry);
    }
    
    function setVariables(address _variables) external onlyOwner {
        variables = IVariables(_variables);
    }

    function safeMint(address to, string memory uri) public onlyActiveParticipator(to) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
        _setTokenURI(tokenId, uri);
        delegate(to);
        userRegistry.setTokenId(to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _afterTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Votes)
    {
        super._afterTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}