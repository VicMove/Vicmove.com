// SPDX-License-Identifier: MIT
//.
pragma solidity ^0.8.0;
import "./ERC721Enumerable.sol";

contract ShoesNFT is ERC721Enumerable {
    constructor() ERC721("ShoesNFT", "ShoesNFT") {
        
    }
    function burn(uint256 tokenId) external {
        _burn(tokenId);
    }
    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to,tokenId);
    }
    function _baseURI() override internal view virtual returns (string memory) {
        return "https://vicmove.com/api/nft/shoesnft/";
    }
    function tokensOfOwner(address owner) external view returns (uint256[] memory) {
        return _tokensOfOwner(owner);
    }
}