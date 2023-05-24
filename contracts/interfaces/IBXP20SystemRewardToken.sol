// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../BXP/interfaces/IBXP20Metadata.sol";


interface IBXP20SystemRewardToken is IBXP20Metadata {
    function mintedBy(address account) external view returns(uint256);
    function burnedBy(address account) external view returns(uint256);
    function balanceOf(address account) external view returns(uint256);
    function burn(uint256 amount) external;
    function mint(address account, uint256 amount) external;
}
