// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "erc721a/contracts/ERC721A.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface AvatizersMetadataManager {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract AvatizersNFT is ERC721A("Avatizers", "AVA"), Ownable {
    uint256 public maxSupply = 999;
    uint256 public maxPerWallet = 2;
    
    bool public saleStarted;
    
    bytes32 public merkleRoot;

    mapping(uint256 => bytes32) public tokenDNA;
    mapping(uint256 => bytes) public pausedTokenGenes;

    AvatizersMetadataManager metadataManager = AvatizersMetadataManager(address(0)); //placeholder

    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        require(_maxSupply > 0 && _totalMinted() < _maxSupply, "Invalid max supply");
        maxSupply = _maxSupply;
    }
    
    function setMaxPerWallet(uint256 _maxPerWallet) external onlyOwner {
        maxPerWallet = _maxPerWallet;
    }

    function setSaleStarted(bool _saleStarted) external onlyOwner {
        saleStarted = _saleStarted;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

    function setMetadataManager(address _metadataManager) external onlyOwner {
        metadataManager = AvatizersMetadataManager(_metadataManager);
    }

    function isWhitelisted(address user, bytes32[] calldata _merkleProof) public view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(user));
        return MerkleProof.verify(_merkleProof, merkleRoot, leaf);
    }

    function getTokenGenes(uint256 tokenId) public view returns (bytes memory) {
        if (pausedTokenGenes[tokenId].length == 0) {
            return abi.encodePacked(tokenDNA[tokenId], (block.timestamp + 61200)/86400);
        } else {
            return pausedTokenGenes[tokenId];
        }
    }

    function pauseDNAGeneration(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only the token owner can pause token DNA");
        require(pausedTokenGenes[tokenId].length == 0, "Token DNA is already paused");
        pausedTokenGenes[tokenId] = abi.encodePacked(tokenDNA[tokenId], (block.timestamp + 61200)/86400);
    }

    function unpauseDNAGeneration(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Only the token owner can unpause token DNA");
        require(pausedTokenGenes[tokenId].length > 0, "Token DNA is already unpaused");
        delete pausedTokenGenes[tokenId];
    }

    function mint(uint64 amount, bytes32[] calldata _merkleProof) external {
        require(saleStarted, "Sale has not started yet");
        require(_totalMinted() + amount <= maxSupply, "Max Supply Exceeded");
        require(isWhitelisted(msg.sender, _merkleProof), "Address not whitelisted");
        uint64 numMinted = _getAux(msg.sender) + amount;
        require(numMinted <= maxPerWallet, "Address cannot mint more tokens");
        unchecked {
            _setAux(msg.sender, numMinted);
            uint256 startToken = _nextTokenId();
            for (uint256 i = 0; i < amount; i++) {
                tokenDNA[startToken + i] = keccak256(abi.encodePacked(msg.sender, startToken + i));
            }
        }
        _safeMint(msg.sender, amount);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        return metadataManager.tokenURI(tokenId);
    }
}