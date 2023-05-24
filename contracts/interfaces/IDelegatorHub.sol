// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


interface IDelegatorHub {
    function delegatedAmountOf(address validatorAccount) external view returns(uint256);
    function increaseDelegatedAmountFor(address validatorAccount, uint256 tokenId) external;
    function decreaseDelegatedAmountFor(address validatorAccount, uint256 tokenId) external;
    function mint(address validatorAccount, uint256 amount) external;
    function burnExtraFor(uint256 tokenId) external;
}
