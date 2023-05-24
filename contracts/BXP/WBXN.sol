// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./BXP20.sol";


contract WBXN is BXP20("Wrapped BXN", "WBXN") {
    receive() external payable {
        _mint(msg.sender, msg.value);
    }

    function mint() external payable {
        _mint(msg.sender, msg.value);
    }

    function burn(uint256 amount) external returns(bool) {
        _burn(msg.sender, amount);
        (bool result,) = msg.sender.call{value:amount}("");
        require(result, "WBXN: failed to send out BXN");
        return result;
    }
}
