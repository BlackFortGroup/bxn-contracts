// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/IValidatorHub.sol";
import "./extensions/SystemAccess.sol";


contract CandidateHub is SystemAccess {
    mapping (address => uint256) private _candidatesBonds;

    uint256 public requiredAmount = 10000 ether;

    event CandidateAccepted(address account);
    event CandidateRejected(address account);
    event CandidateRequiredAmountSet(uint256 amount);

    modifier isCandidate(address account) {
        require(_candidatesBonds[account] != 0, "CandidateHub: no such candidate");
        _;
    }

    receive() external payable {
        address account = msg.sender;
        uint256 amount = msg.value;
        IValidatorHub ValidatorHub = IValidatorHub(_getAddressOf("VALIDATOR_HUB"));

        require(!ValidatorHub.isValidator(msg.sender), "CandidateHub: you're already a validator");
        require(_candidatesBonds[account] == 0, "CandidateHub: you're already a candidate");
        require(amount >= requiredAmount, "CandidateHub: you don't have enough amount of tokens to become a candidate");

        _candidatesBonds[account] += amount;
    }

    function accept(address account) external isCandidate(account) returns(bool) {
        require(hasRole("VALIDATOR_MANAGER_ROLE", msg.sender), "CandidateHub: only validator manager has right to perform that");

        IValidatorHub ValidatorHub = IValidatorHub(_getAddressOf("VALIDATOR_HUB"));
        uint256 amount = selfBondedAmountOf(account);

        _candidatesBonds[account] -= amount;
        bool result = ValidatorHub.join{value:amount}(account);

        emit CandidateAccepted(account);
        return result;
    }

    function reject(address account) external isCandidate(account) {
        require(hasRole("VALIDATOR_MANAGER_ROLE", msg.sender), "CandidateHub: only validator manager has right to perform that");
        require(account != address(0), "CandidateHub: request to the zero address");

        uint256 amount = selfBondedAmountOf(account);
        _candidatesBonds[account] -= amount;

        (bool result,) = account.call{value:amount}("");
        require(result, "CandidateHub: failed to send tokens to address");

        emit CandidateRejected(account);
    }

    function selfBondedAmountOf(address account) public view returns(uint256) {
        return _candidatesBonds[account];
    }

    function setRequiredAmount(uint256 amount) external {
        require(hasRole("VALIDATOR_MANAGER_ROLE", msg.sender), "CandidateHub: only validator manager has right to perform that");
        require(amount >= 1 ether, "CandidateHub: amount must be greater than 1 BXN");

        requiredAmount = amount;

        emit CandidateRequiredAmountSet(amount);
    }
}
