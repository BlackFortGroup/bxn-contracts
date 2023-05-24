// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


interface IValidatorHub {
    function commissionOf(address account) external returns(uint256);
    function selfBondedAmountOf(address account) external returns(uint256);
    function isValidator(address account) external returns(bool);
    function mint(address account, uint256 amount) external;
    function join(address account) external payable returns(bool);
}