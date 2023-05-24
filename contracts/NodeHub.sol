// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./BXP/BXP721Enumerable.sol";
import "./interfaces/IAccessControlHub.sol";
import "./interfaces/IDelegatorHub.sol";
import "./interfaces/INodeHub.sol";
import "./interfaces/ISlashingHub.sol";
import "./interfaces/IVoteHub.sol";
import "./extensions/SystemAccess.sol";


contract NodeHub is INodeHub, SystemAccess, BXP721Enumerable, ReentrancyGuard {
    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;

    string private _baseTokenURI;

    Counters.Counter private _tokenIdTracker;

    mapping(uint256 => uint256) private _nodeType;
    mapping(uint256 => address) private _delegators;
    mapping(uint256 => uint256) private _mintedAtBlock;
    mapping(uint256 => bool) private _isLocked;

    mapping(address => uint256) private _depositedAmount;
    mapping(address => uint256) private _burntAmount;

    NodeType[] public nodeTypes;

    uint256 public constant DEPOSIT_LIMIT = 5000000 ether;
    uint256 public constant VALID_TILL_BLOCKS = 60000000;
    uint256 public constant REWARD_HALVING_AFTER_BLOCKS = 6000000;
    bool private _initialized = false;

    event BaseTokenURISet(string indexed uri);
    event NodeLocked(uint256 tokenId);
    event NodeUnlocked(uint256 tokenId);

    modifier onlyOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "NodeHub: transfer of foreign token is not allowed");
        _;
    }

    modifier tokenNotLocked(uint256 tokenId) {
        require(!_isLocked[tokenId], "NodeHub: not allowed, token is locked");
        _;
    }

    modifier isInitialized() {
        require(_initialized, "NodeHub: not yet initialized");
        _;
    }

    constructor(string memory name, string memory symbol) BXP721(name, symbol) { init(); }

    receive() external payable {
        mint(msg.sender);
    }

    function init() public {
        require(!_initialized, "NodeHub: already initialized");
        _initialized = true;

        nodeTypes.push(NodeType(500, 2500000 ether,  624_775_519_297_067_000, "Chillon"));
        nodeTypes.push(NodeType(1000, 1000000 ether, 245_010_007_567_477_000, "Landskron"));
        nodeTypes.push(NodeType(2500, 500000 ether,  120_102_944_886_018_000, "Malbork"));
        nodeTypes.push(NodeType(10000, 250000 ether, 58_873_992_591_185_400, "Kronborg"));
        nodeTypes.push(NodeType(15000, 100000 ether, 23_087_840_231_837_400, "Trogir"));
        nodeTypes.push(NodeType(25000, 50000 ether,  11_317_568_741_096_800, "Trakai"));
        nodeTypes.push(NodeType(100000, 10000 ether, 2_219_131_125_705_250, "Vianden"));
        nodeTypes.push(NodeType(150000, 5000 ether,  1_087_809_375_345_710, "Hever"));
    }

    function setBaseTokenURI(string memory baseTokenURI) public {
        require(hasRole("NODE_MANAGER_ROLE", msg.sender), "NodeHub: not allowed");

        _baseTokenURI = baseTokenURI;

        emit BaseTokenURISet(baseTokenURI);
    }

    function balanceOf(address owner) public view override(INodeHub, BXP721) returns(uint256) {
        return super.balanceOf(owner);
    }

    function ownerOf(uint256 tokenId) public view override(INodeHub, BXP721) returns(address) {
        return super.ownerOf(tokenId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override(INodeHub, BXP721Enumerable) returns(uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    function isLocked(uint256 tokenId) public view override returns(bool) {
        return _isLocked[tokenId];
    }

    function mintedWith(uint256 tokenId) public view returns(uint256) {
        if (isLocked(tokenId)) {
            return 0;
        }
        uint256 blockDiff = Math.min(block.number - _mintedAtBlock[tokenId], VALID_TILL_BLOCKS);
        uint256 blockReward = typeOf(tokenId).rewardShare;
        uint256 reward = 0;
        while (blockDiff >= REWARD_HALVING_AFTER_BLOCKS) {
            reward += blockReward * REWARD_HALVING_AFTER_BLOCKS;
            blockReward /= 2;
            blockDiff -= REWARD_HALVING_AFTER_BLOCKS;
        }
        return reward + blockReward * blockDiff;
    }

    function mintedBy(address owner) public view override returns(uint256) {
        uint256 totalReward = 0;
        for (uint256 i = 0; i < balanceOf(owner); i++) {
            totalReward += mintedWith(tokenOfOwnerByIndex(owner, i));
        }
        return totalReward;
    }

    function burnedBy(address owner) public view override returns(uint256) {
        return _burntAmount[owner];
    }

    function availableBalanceOf(address owner) public view returns(uint256) {
        require(owner != address(0), "NodeHub: balance query for the zero address");
        return mintedBy(owner) - burnedBy(owner);
    }

    function typeOf(uint256 tokenId) public view returns(NodeType memory) {
        return nodeTypes[_nodeType[tokenId]];
    }

    function delegatedTo(uint256 tokenId) public view override returns(address) {
        return _delegators[tokenId];
    }

    function mint(address owner) public payable override isInitialized {
        require(hasRole("NODE_MANAGER_ROLE", msg.sender), "NodeHub: only node manager has right to perform that");
        require(owner != address(0), "NodeHub: mint to the zero address");

        uint256 amount = msg.value;
        uint256 refund = 0 ether;
        uint256 alreadyDeposited = _depositedAmount[owner];

        if (alreadyDeposited + amount > DEPOSIT_LIMIT) {
            refund = alreadyDeposited + amount - DEPOSIT_LIMIT;
            amount = DEPOSIT_LIMIT - alreadyDeposited;
        }

        for (uint256 i = 0; i < nodeTypes.length; i++) {
            uint256 nodePrice = nodeTypes[i].price;
            while (amount >= nodePrice && nodeTypes[i].quantity > 0) {
                uint256 tokenId = _tokenIdTracker.current();

                _mint(owner, tokenId);

                _delegators[tokenId] = address(0);
                _mintedAtBlock[tokenId] = block.number;
                _nodeType[tokenId] = i;

                nodeTypes[i].quantity -= 1;
                _depositedAmount[owner] += nodePrice;
                amount -= nodePrice;

                _tokenIdTracker.increment();

            }
        }

        refund += amount;
        if (refund > 0) {
            (bool result,) = msg.sender.call{value:refund}("");
            require(result, "NodeHub: failed to send the refund amount");
        }

        if (hasRole("VOTE_MINT_ROLE", address(this))) {
            IVoteHub VoteHub = IVoteHub(_getAddressOf("VOTE_HUB"));
            bool mintResult = VoteHub.mint(owner, (_depositedAmount[owner] - alreadyDeposited) / 100);
            require(mintResult, "NodeHub: failed to mint VOTE token");
        }
    }

    function lock(uint256 tokenId) external override {
        require(hasRole("NODE_MANAGER_ROLE", msg.sender), "NodeHub: only node manager has right to perform that");
        require(_exists(tokenId), "NodeHub: invalid token ID");
        require(!isLocked(tokenId), "NodeHub: token already locked");

        _isLocked[tokenId] = true;

        emit NodeLocked(tokenId);
    }

    function unlock(uint256 tokenId) external override {
        require(hasRole("NODE_MANAGER_ROLE", msg.sender), "NodeHub: only node manager has right to perform that");
        require(_exists(tokenId), "NodeHub: invalid token ID");
        require(isLocked(tokenId), "NodeHub: token already unlocked");

        _isLocked[tokenId] = false;

        emit NodeUnlocked(tokenId);
    }

    function burn(uint256 amount) external override isInitialized {
        _burnFrom(msg.sender, amount);
    }

    function delegate(address validatorAddress, uint256 tokenId) public isInitialized onlyOwner(tokenId) {
        IDelegatorHub DelegatorHub = IDelegatorHub(_getAddressOf("DELEGATOR_HUB"));

        DelegatorHub.burnExtraFor(tokenId);

        address currentValidator = _delegators[tokenId];
        if (currentValidator != address(0)) {
            _delegators[tokenId] = address(0);
            DelegatorHub.decreaseDelegatedAmountFor(currentValidator, tokenId);
        }
        if (validatorAddress != address(0)) {
            _delegators[tokenId] = validatorAddress;
            ISlashingHub SlashingHub = ISlashingHub(_getAddressOf("SLASHING_HUB"));
            require(!SlashingHub.isSlashed(validatorAddress), "NodeHub: you can't delegate node to slashed validator");

            DelegatorHub.increaseDelegatedAmountFor(validatorAddress, tokenId);
        }
    }

    function _burnFrom(address owner, uint256 amount) internal returns(bool) {
        require(availableBalanceOf(owner) >= amount, "NodeHub: insufficient available balance");

        _burntAmount[owner] += amount;

        bool result = _getSystemContractInstance().transferTo(owner, amount);
        require(result, "NodeHub: failed to burn given amount for owner");
        return result;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override isInitialized transfersAvailable tokenNotLocked(tokenId) nonReentrant {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            return;
        }

        uint256 reward = mintedWith(tokenId);
        uint256 burnedByFrom = burnedBy(from);

        delegate(address(0), tokenId);

        if (reward > burnedByFrom) {
            _burnFrom(from, reward - burnedByFrom);
        }

        _burntAmount[from] -= reward;
        _burntAmount[to] += reward;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}