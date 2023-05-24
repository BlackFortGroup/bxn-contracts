// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/IDelegatorHub.sol";
import "./interfaces/IValidatorHub.sol";
import "./interfaces/ISystem.sol";
import "./interfaces/INodeHub.sol";
import "./extensions/BXP20SystemRewardToken.sol";
import "./extensions/SystemAccess.sol";


contract DelegatorHub is IDelegatorHub, BXP20SystemRewardToken {
    uint256 constant LOSS_REDUCE_VALUE = 2 ** 64;
    uint256 constant SHARE_MULTIPLIER = 5000000;

    mapping (address => uint256) private _baseValues;
    mapping (address => uint256) private _delegatedAmount;

    event DelegatorAmountIncreased(address indexed validatorAccount, uint256 indexed tokenId);
    event DelegatorAmountDecreased(address indexed validatorAccount, uint256 indexed tokenId);

    modifier onlyValidatorAccount(address account) {
        bool result = IValidatorHub(_getAddressOf("VALIDATOR_HUB")).isValidator(account);
        require(result, "DelegatorHub: validator address is not valid");
        _;
    }

    constructor(string memory name, string memory symbol) BXP20(name, symbol) {}

    function increaseDelegatedAmountFor(address validatorAccount, uint256 tokenId) external override onlyContract("NODE_HUB") onlyValidatorAccount(validatorAccount) {
        INodeHub NodeHub = INodeHub(_getAddressOf("NODE_HUB"));

        address delegatorAccount = NodeHub.ownerOf(tokenId);
        uint256 rewardShareAmount = NodeHub.typeOf(tokenId).rewardShare * SHARE_MULTIPLIER;

        _delegatedAmount[validatorAccount] += rewardShareAmount;
        _increaseBurntAmountOf(delegatorAccount, _baseValues[validatorAccount] * rewardShareAmount / LOSS_REDUCE_VALUE);

        emit DelegatorAmountIncreased(validatorAccount, tokenId);
    }

    function decreaseDelegatedAmountFor(address validatorAccount, uint256 tokenId) external override onlyContract("NODE_HUB") onlyValidatorAccount(validatorAccount) {
        INodeHub NodeHub = INodeHub(_getAddressOf("NODE_HUB"));

        address delegatorAccount = NodeHub.ownerOf(tokenId);
        uint256 rewardShareAmount = NodeHub.typeOf(tokenId).rewardShare * SHARE_MULTIPLIER;

        rewardShareAmount = Math.min(rewardShareAmount, _delegatedAmount[validatorAccount]);
        _decreaseBurntAmountOf(delegatorAccount, mintedWith(tokenId));
        _delegatedAmount[validatorAccount] -= rewardShareAmount;

        emit DelegatorAmountDecreased(validatorAccount, tokenId);
    }

    function delegatedAmountOf(address validatorAccount) public view override returns(uint256) {
        return _delegatedAmount[validatorAccount];
    }

    function mintedWith(uint256 tokenId) public view returns(uint256) {
        INodeHub NodeHub = INodeHub(_getAddressOf("NODE_HUB"));

        address delegatedTo = NodeHub.delegatedTo(tokenId);
        uint256 rewardShare = NodeHub.typeOf(tokenId).rewardShare * SHARE_MULTIPLIER;
        return _baseValues[delegatedTo] * rewardShare / LOSS_REDUCE_VALUE;
    }

    function mintedBy(address account) public view override returns(uint256) {
        INodeHub NodeHub = INodeHub(_getAddressOf("NODE_HUB"));

        uint256 totalReward = super.mintedBy(account);
        uint256 amountOfOwnedTokens = NodeHub.balanceOf(account);
        for (uint256 i = 0; i < amountOfOwnedTokens; i++) {
            totalReward += mintedWith(NodeHub.tokenOfOwnerByIndex(account, i));
        }
        return totalReward;
    }

    function mint(address validatorAccount, uint256 amount) public override(BXP20SystemRewardToken, IDelegatorHub) onlyValidatorAccount(validatorAccount) {
        super.mint(validatorAccount, amount);
        _decreaseMintedAmountOf(validatorAccount, amount);
        uint256 delegated = _delegatedAmount[validatorAccount];
        _baseValues[validatorAccount] += (delegated == 0) ? 0 : (amount * LOSS_REDUCE_VALUE / delegated);
    }

    function burnExtraFor(uint256 tokenId) external override onlyContract("NODE_HUB") {
        INodeHub NodeHub = INodeHub(_getAddressOf("NODE_HUB"));

        address delegatorAccount = NodeHub.ownerOf(tokenId);
        uint256 burntAmount = burnedBy(delegatorAccount);
        uint256 minted = mintedWith(tokenId);
        if (minted > burntAmount) {
            _burnAndPay(delegatorAccount, minted - burntAmount);
        }
    }
}
