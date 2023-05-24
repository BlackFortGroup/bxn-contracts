// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/IVoteHub.sol";
import "./extensions/SystemAccess.sol";
import "./BXP/BXP20.sol";


contract VoteHub is SystemAccess, BXP20, IVoteHub {

    modifier isAllowedToMint() {
        require(hasRole("VOTE_MINT_ROLE", msg.sender), "VoteHub: only vote manager has right to perform that");
        _;
    }

    modifier isAllowedToBurn() {
        require(hasRole("VOTE_BURN_ROLE", msg.sender), "VoteHub: only vote manager has right to perform that");
        _;
    }

    constructor(string memory name, string memory symbol) BXP20(name, symbol) {}

    function mint(address account, uint256 amount) external override isAllowedToMint returns(bool) {
        _mint(account, amount);
        return true;
    }

    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
    }

    function burn(address account, uint256 amount) external override isAllowedToBurn returns(bool) {
        _burn(account, amount);
        return _getSystemContractInstance().transferTo(account, amount);
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return (hasRole("VOTE_SPENDER_ROLE", spender)) ? balanceOf(owner) : super.allowance(owner, spender);
    }

    function balanceOf(address account) public view override(BXP20, IVoteHub) returns(uint256) {
        return super.balanceOf(account);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override(BXP20, IVoteHub) returns(bool) {
        return super.transferFrom(sender, recipient, amount);
    }
}
