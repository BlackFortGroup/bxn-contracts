// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/IValidatorHub.sol";
import "./interfaces/ISlashingHub.sol";
import "./interfaces/ISystem.sol";
import "./extensions/BXP20SystemRewardToken.sol";


contract ValidatorHub is IValidatorHub, BXP20SystemRewardToken {
    mapping (address => uint256) private _selfBondedAmount;
    mapping (address => uint256) private _commissions;
    mapping (address => string) private _names;

    event ValidatorJoined(address account);
    event ValidatorKicked(address account);

    constructor(string memory name, string memory symbol) BXP20(name, symbol) {}

    modifier onlyValidator() {
        require(isValidator(msg.sender), "ValidatorHub: only validators allowed to call this method");
        _;
    }

    modifier onlyValidatorAccount(address account) {
        require(isValidator(account), "ValidatorHub: only validators allowed to call this method");
        _;
    }

    receive() external payable onlyValidator {
        ISlashingHub SlashingHub = ISlashingHub(_getAddressOf("SLASHING_HUB"));
        require(!SlashingHub.isSlashed(msg.sender), "ValidatorHub: you're not allowed to do this while being slashed");

        _selfBondedAmount[msg.sender] += msg.value;
    }

    function isValidator(address account) public view override returns(bool) {
        return selfBondedAmountOf(account) != 0;
    }

    function commissionOf(address account) external view override returns(uint256) {
        ISlashingHub SlashingHub = ISlashingHub(_getAddressOf("SLASHING_HUB"));

        uint256 commission = _commissions[account];
        if (SlashingHub.isSlashed(account)) {
            commission /= SlashingHub.timesSlashed(account);
        }
        return commission;
    }

    function nameOf(address account) public view returns(string memory) {
        return _names[account];
    }

    function setCommission(uint256 percent) external onlyValidator {
        ISlashingHub SlashingHub = ISlashingHub(_getAddressOf("SLASHING_HUB"));
        require(!SlashingHub.isSlashed(msg.sender), "ValidatorHub: you're not allowed to do this while being slashed");
        require(0 < percent && percent < 5000, "ValidatorHub: only integer values in range (0, 5000) are allowed");

        _commissions[msg.sender] = percent;
    }

    function setName(string memory name) public onlyValidator {
        require(bytes(name).length != 0, "ValidatorHub: set empty name for validator");

        _names[msg.sender] = name;
    }

    function selfBondedAmountOf(address account) public view override returns(uint256) {
        return _selfBondedAmount[account];
    }

    function mint(address account, uint256 amount) public override(BXP20SystemRewardToken, IValidatorHub) onlyValidatorAccount(account) {
        super.mint(account, amount);
    }

    function join(address account) external payable onlyContract("CANDIDATE_HUB") returns(bool) {
        _selfBondedAmount[account] += msg.value;
        _commissions[account] = 1000;

        emit ValidatorJoined(account);
        return true;
    }

    function kick(address account) external onlyValidatorAccount(account) returns(bool) {
        require(hasRole("VALIDATOR_MANAGER_ROLE", msg.sender), "ValidatorHub: only validator manager has right to perform that");
        require(account != address(0), "ValidatorHub: request to the zero address");

        uint256 amount = _selfBondedAmount[account];
        _selfBondedAmount[account] -= amount;

        (bool result,) = account.call{value:amount}("");
        require(result, "ValidatorHub: failed to send tokens to account");
        emit ValidatorKicked(account);
        return result;
    }
}
