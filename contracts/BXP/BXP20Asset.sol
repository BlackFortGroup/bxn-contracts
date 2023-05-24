// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./BXP20.sol";
import "../extensions/SystemAccess.sol";


abstract contract BlackList is BXP20, SystemAccess {
    mapping (address => bool) private _blackList;

    event AddedToBlackList(address indexed account);
    event RemovedFromBlackList(address indexed account);
    event DestroyedFunds(address indexed account, uint256 amount);

    modifier notInBlackList(address account) {
        require(!isInBlackList(account), "BlackList: account is in black list");
        _;
    }

    modifier inBlackList(address account) {
        require(isInBlackList(account), "BlackList: account is in black list");
        _;
    }

    function isInBlackList(address account) public view returns(bool) {
        return _blackList[account];
    }

    function addToBlackList(address account) external notInBlackList(account) {
        require(hasRole("ASSET_BLACKLIST_MANAGER_ROLE", msg.sender), "BXP20: only asset black list manager is allowed to do that");

        _blackList[account] = true;
        emit AddedToBlackList(account);
    }

    function removeFromBlackList(address account) external inBlackList(account) {
        require(hasRole("ASSET_BLACKLIST_MANAGER_ROLE", msg.sender), "BXP20: only asset black list manager is allowed to do that");

        _blackList[account] = false;
        emit RemovedFromBlackList(account);
    }

    function destroyFunds(address account) external inBlackList(account) {
        require(hasRole("ASSET_BLACKLIST_MANAGER_ROLE", msg.sender), "BXP20: only asset black list manager is allowed to do that");

        uint256 balance = balanceOf(account);
        _burn(account, balance);
        emit DestroyedFunds(account, balance);
    }
}


abstract contract Manageable is BXP20, SystemAccess {

    function mint(address account, uint256 amount) public virtual {
        require(hasRole("ASSET_MANAGER_ROLE", msg.sender), "BXP20: only asset manager is allowed to mint");

        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public virtual {
        require(hasRole("ASSET_MANAGER_ROLE", msg.sender), "BXP20: only asset manager is allowed to burn");

        _burn(account, amount);
    }
}


contract BXP20Asset is Manageable, BlackList {
    constructor(string memory name_, string memory symbol_) BXP20(name_, symbol_) {}

    function mint(address account, uint256 amount) public override {
        super.mint(account, amount);
    }

    function burn(address account, uint256 amount) public override {
        super.burn(account, amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override notInBlackList(from) notInBlackList(to) transfersAvailable {
        super._beforeTokenTransfer(from, to, amount);
    }
}
