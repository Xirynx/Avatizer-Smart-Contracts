// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SignedMath.sol";
import "./AvatizerSVGRenderer.sol";

interface AvatizersNFT {
    function getTokenGenes(uint256 tokenId) external view returns (bytes memory);
}

contract AvatizersMetadataManager is Ownable {
    using Strings for uint256;

    string specialImage;

    AvatizersNFT nftContract = AvatizersNFT(address(0));

    function setNFTContract(address _nftContract) external onlyOwner {
        nftContract = AvatizersNFT(_nftContract);
    }

    function setSpecialImage(string memory svg) external onlyOwner {
        specialImage = svg;
    }

    function generateImage(bytes memory seed) public pure returns (string memory svg) {
        {
            svg = string.concat(
                '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" viewBox="-65 0 730 850">',
                AvatizersSVGRenderer.genStyleSheet(seed, AvatizersSVGRenderer.genColourPalette(15, seed)),
                '<g transform="translate(-65 0)"><rect id="Background" class="st0" width="100%" height="100%"/></g>',
                AvatizersSVGRenderer.genShards(seed),
                AvatizersSVGRenderer.genNeck(seed),
                '<path id="Head" class="st4" d="M130.7,291.2l66,237.9l84.6,60.6L330,595l56.6-47.3l42.7-167.3l-14-152l-50.6-51.3l-94.6-20l-113.3,48.7L130.7,291.2z"/>',
                AvatizersSVGRenderer.genDimples(seed)
            );
        }
        {
            svg = string.concat(
                svg,
                AvatizersSVGRenderer.genCheekbones(seed),
                AvatizersSVGRenderer.genEyes(seed),
                AvatizersSVGRenderer.genEyebrows(seed),
                AvatizersSVGRenderer.genNose(seed),
                AvatizersSVGRenderer.genLips(seed),
                AvatizersSVGRenderer.genHair(seed),
                AvatizersSVGRenderer.genStreaks(seed),
                '</svg>'
            );
        }
        return string.concat(
            'data:image/svg+xml;base64,',
            Base64.encode(bytes(svg))
        );
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        string memory image;
        if (tokenId != 0) {
            image = generateImage(nftContract.getTokenGenes(tokenId));
        } else {
            image = specialImage;
        }
        return string.concat(
            "data:application/json;base64,",
            Base64.encode(abi.encodePacked(
                '{"name":"Avatizers #', tokenId.toString(), '",',
                '"image":"', image, '",',
                '"attributes":[',
                '{"trait_type":"Type",',
                '"value":', (tokenId == 0)? '"Regular"' : '"Special"',
                '}]}'
            ))
        );
    }
}