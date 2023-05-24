// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/ISlashingHub.sol";
import "./interfaces/IValidatorHub.sol";
import "./extensions/SystemAccess.sol";


contract SlashingHub is SystemAccess, ISlashingHub {
    mapping (address => uint256) private _slashedBy;
    mapping (address => uint256) private _timesSlashed;

    event ValidatorSlashed(address indexed account, uint256 byBlock);
    event ValidatorSlashReduced(address indexed account);
    event ValidatorUnslashed(address indexed account);

    function isSlashed(address account) public view override returns(bool) {
        return _slashedBy[account] > block.number;
    }

    function slashedByBlock(address account) public view returns(uint256) {
        return isSlashed(account) ? _slashedBy[account] : 0;
    }

    function timesSlashed(address account) public view override returns(uint256) {
        return _timesSlashed[account];
    }

    function slash(address account, uint256 byBlock) external {
        require(hasRole("VALIDATOR_MANAGER_ROLE", msg.sender), "SlashingHub: only validator manager has right to perform that");
        require(
            IValidatorHub(_getAddressOf("VALIDATOR_HUB")).isValidator(account),
            "SlashingHub: validator address is not valid"
        );
        require(byBlock > block.number, "SlashingHub: setting slash time in the  past");

        if (_slashedBy[account] > block.number) {
            _slashedBy[account] = byBlock;
            return;
        }
        _slashedBy[account] = byBlock;
        if (_timesSlashed[account] == 0) {
            _timesSlashed[account] = 1;
        }
        _timesSlashed[account] *= 2;

        emit ValidatorSlashed(account, byBlock);
    }

    function reduceTimesSlashed(address account) external {
        require(hasRole("VALIDATOR_MANAGER_ROLE", msg.sender), "SlashingHub: only validator manager has right to perform that");
        require(
            IValidatorHub(_getAddressOf("VALIDATOR_HUB")).isValidator(account),
            "SlashingHub: validator address is not valid"
        );
        require(_timesSlashed[account] > 1, "SlashingHub: cannot reduce anymore");

        _timesSlashed[account] /= 2;

        emit ValidatorSlashReduced(account);
    }

    function unslash(address account) external {
        require(hasRole("VALIDATOR_MANAGER_ROLE", msg.sender), "SlashingHub: only validator manager has right to perform that");
        require(
            IValidatorHub(_getAddressOf("VALIDATOR_HUB")).isValidator(account),
            "SlashingHub: validator address is not valid"
        );
        require(isSlashed(account), "SlashingHub: account is not slashed");

        _slashedBy[account] = block.number;

        emit ValidatorUnslashed(account);
    }
}
