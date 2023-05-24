// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface IVoteHub {
    function mint(address account, uint256 amount) external returns(bool);
    function burn(address account, uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns(uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool);
}
