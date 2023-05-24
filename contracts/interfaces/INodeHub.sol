// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


interface INodeHub {
    struct NodeType {
        uint256 quantity;
        uint256 price;
        uint256 rewardShare;
        string name;
    }

    function mintedBy(address owner) external view returns(uint256);
    function burnedBy(address owner) external view returns(uint256);
    function typeOf(uint256 tokenId) external view returns(NodeType memory);
    function delegatedTo(uint256 tokenId) external view returns(address);

    function isLocked(uint256 tokenId) external view returns(bool);
    function lock(uint256 tokenId) external;
    function unlock(uint256 tokenId) external;

    function burn(uint256 amount) external;
    function mint(address owner) external payable;

    function ownerOf(uint256 tokenId) external view returns(address);
    function balanceOf(address owner) external view returns(uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns(uint256);
}

