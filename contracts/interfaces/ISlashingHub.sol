// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

interface ISlashingHub {
    function isSlashed(address account) external view returns(bool);
    function timesSlashed(address account) external view returns(uint256);
}
