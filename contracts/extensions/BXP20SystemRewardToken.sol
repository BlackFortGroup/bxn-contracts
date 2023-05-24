// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../BXP/BXP20.sol";
import "../interfaces/IAccessControlHub.sol";
import "../interfaces/IBXP20SystemRewardToken.sol";
import "./SystemAccess.sol";


abstract contract BXP20SystemRewardToken is BXP20, IBXP20SystemRewardToken, SystemAccess {
    // uint256 private _totalSupply;

    mapping(address => uint256) private _mintedAmount;
    mapping(address => uint256) private _burntAmount;

    function mintedBy(address account) public view virtual override returns(uint256) {
        return _mintedAmount[account];
    }

    function burnedBy(address account) public view override returns(uint256) {
        return _burntAmount[account];
    }

    function balanceOf(address account) public view override(BXP20, IBXP20SystemRewardToken) returns(uint256) {
        return mintedBy(account) - burnedBy(account);
    }

    /*function totalSupply() public view override(BXP20, IBXP20) returns(uint256) {
        return _totalSupply;
    }*/

    /*function legacyBalanceOf(address account) public view returns(uint256) {
        return super.balanceOf(account);
    }*/

    function mint(address account, uint256 amount) public virtual override onlySystem {
        _increaseMintedAmountOf(account, amount);
        _mint(account, amount);
    }

    function burn(uint256 amount) external override {
        require(balanceOf(msg.sender) >= amount, "BXP20: burn amount exceeds balance");

        _burnAndPay(msg.sender, amount);
    }

    function transfer(address recipient, uint256 amount) public override(BXP20, IBXP20) returns(bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _burnAndPay(address account, uint256 amount) internal {
        _increaseBurntAmountOf(account, amount);
        _burn(address(0), amount);
        bool result = _getSystemContractInstance().transferTo(account, amount);
        require(result, "BXP20: failed to transfer tokens from System");
    }

    /*
    function _mint(address account, uint256 amount) internal override {
        require(account != address(0), "BXP20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _increaseMintedAmountOf(account, amount);
        _totalSupply += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }*/

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(sender != address(0), "BXP20: transfer from the zero address");
        require(recipient != address(0), "BXP20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        require(balanceOf(sender) >= amount, "BXP20: transfer amount exceeds balance");
        _increaseBurntAmountOf(sender, amount);
        _increaseMintedAmountOf(recipient, amount);

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /*function _burn(address account, uint256 amount) internal override {
        require(account != address(0), "BXP20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        require(balanceOf(account) >= amount, "BXP20: burn amount exceeds balance");

        _increaseBurntAmountOf(account, amount);
        _totalSupply -= amount;
        bool transferResult = _getSystemContractInstance().transferTo(account, amount);
        require(transferResult, "BXP20: failed to transfer tokens from System");

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }*/

    function _increaseBurntAmountOf(address account, uint256 amount) internal {
        _burntAmount[account] += amount;
    }

    function _decreaseBurntAmountOf(address account, uint256 amount) internal {
        _burntAmount[account] -= amount;
    }

    function _increaseMintedAmountOf(address account, uint256 amount) internal {
        _mintedAmount[account] += amount;
    }

    function _decreaseMintedAmountOf(address account, uint256 amount) internal {
        _mintedAmount[account] -= amount;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override transfersAvailable {}
}