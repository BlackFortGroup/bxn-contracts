// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


interface IAccessControlHub {
    function transfersAvailable(address account) external view returns(bool);
    function hasStringRole(string memory stringRole, address account) external view returns(bool);
}