// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


interface ISystem {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event ApprovedAmount(address indexed name, uint256 amount);
    event Mapping(address indexed account, string indexed name);
    function transferTo(address account, uint256 amount) external returns(bool);
    function getAddressOf(string memory name) external view returns(address);
}