// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IValidatorHub.sol";
import "./interfaces/INodeHub.sol";
import "./interfaces/IDelegatorHub.sol";
import "./interfaces/ISystem.sol";
import "./interfaces/IVoteHub.sol";
import "./extensions/SystemAccess.sol";


contract System is SystemAccess, ISystem {
    mapping (address => uint256) _approvedAmount;
    mapping (address => uint256) _spentAmount;
    mapping (string => address) _accounts;

    modifier isApproved(uint256 amount) {
        require(amount <= address(this).balance, "System: insufficient funds");
        require(spentAmountOf(msg.sender) + amount <= approvedAmountOf(msg.sender), "System: exceeding of approved amount");
        _;
    }

    constructor(address name) payable {
        string memory ACCESS_CONTROL_HUB = "ACCESS_CONTROL_HUB";
        _accounts[ACCESS_CONTROL_HUB] = name;
    }

    function setMapping(address account, string memory name) external {
        require(hasRole("SYSTEM_MANAGER_ROLE", msg.sender), "System: only system manager has right to perform that");
        require(account != address(0), "System: mapping to the zero");
        require(bytes(name).length != 0, "System: empty name string");

        _accounts[name] = account;
        emit Mapping(account, name);
    }

    function approve(address account, uint256 amount) external {
        require(hasRole("SYSTEM_MANAGER_ROLE", msg.sender), "System: only system manager has right to perform that");
        require(account != address(0), "System: approve to the zero");

        _approvedAmount[account] = amount;
        emit ApprovedAmount(account, amount);
    }

    function approvedAmountOf(address account) public view returns(uint256) {
        return _approvedAmount[account];
    }

    function spentAmountOf(address account) public view returns(uint256) {
        return _spentAmount[account];
    }

    function getAddressOf(string memory name) public view override returns(address) {
        return _accounts[name];
    }

    receive() external payable {
        uint256 amount = msg.value;
        address validator = msg.sender;

        IValidatorHub ValidatorHub = IValidatorHub(getAddressOf("VALIDATOR_HUB"));
        IDelegatorHub DelegatorHub = IDelegatorHub(getAddressOf("DELEGATOR_HUB"));

        if (!ValidatorHub.isValidator(validator)) {
            return;
        }

        uint256 validatorCommission = ValidatorHub.commissionOf(validator);
        uint256 selfBonded = ValidatorHub.selfBondedAmountOf(validator);
        uint256 delegated = DelegatorHub.delegatedAmountOf(validator);

        uint256 validatorBondedReward = amount * selfBonded / (selfBonded + delegated);
        uint256 restOfReward = amount - validatorBondedReward;
        uint256 commission = restOfReward * validatorCommission / 10000;
        uint256 validatorReward = validatorBondedReward + commission;
        uint256 distributedRewardForDelegators = restOfReward - commission;

        if (DelegatorHub.delegatedAmountOf(validator) > 0) {
            DelegatorHub.mint(validator, distributedRewardForDelegators);
        }
        ValidatorHub.mint(validator, validatorReward);
    }

    function transferTo(address account, uint256 amount) external override isApproved(amount) transfersAvailable returns(bool) {
        require(account != address(0), "System: transfer to the zero address");

        _spentAmount[msg.sender] += amount;

        if (hasRole("VOTE_MINT_ROLE", msg.sender)) {
            IVoteHub VoteHub = IVoteHub(getAddressOf("VOTE_HUB"));
            bool mintResult = VoteHub.mint(account, amount / 10000);
            require(mintResult, "NodeHub: failed to mint VOTE token");
        }

        (bool result,) = account.call{value:amount}("");
        require(result, "System: failed to transfer tokens from System");

        emit Transfer(address(this), account, amount);
        return result;
    }
}
