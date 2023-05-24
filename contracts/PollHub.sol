// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./BXP/BXP721Enumerable.sol";
import "./extensions/SystemAccess.sol";
import "./interfaces/IVoteHub.sol";


contract PollHub is SystemAccess, BXP721Enumerable {
    using Address for address;
    using Strings for string;
    using Counters for Counters.Counter;

    string private _baseTokenURI;

    Counters.Counter private _tokenIdTracker;

    mapping(uint256 => string) private _pollTitles;
    mapping(uint256 => string[]) private _pollOptions;
    mapping(uint256 => uint256) private _pollDeadline;
    mapping(uint256 => uint256) private _pollTotalVoteAmount;
    mapping(uint256 => uint256[]) private _pollVoteAmount;

    uint256 public requiredAmountOfBXN = 10000 ether;
    uint256 public requiredAmountOfVote = 10000 ether;
    uint256 public pollPrice = 10000 ether;
    uint256 public pollCreatorFee = 1000;

    event Vote(address indexed account, uint256 indexed tokenId, uint256 optionId, uint256 amountOfVote);
    event PollStarted(uint256 tokenId, uint256 deadlineBlock);
    event PollDeadlineBlockUpdated(uint256 tokenId, uint256 newDeadlineBlock);
    event BaseTokenURISet(string indexed uri);
    event RequiredAmountOfVoteSet(uint256 amount);
    event RequiredAmountOfBXNSet(uint256 amount);
    event PollPriceSet(uint256 amount);
    event PollCreatorFeeSet(uint256 amount);
    event PollOptionAdded(uint256 indexed tokenId, string option);
    event PollOptionUpdated(uint256 indexed tokenId, uint256 optionId, string option);
    event PollOptionRemoved(uint256 indexed tokenId, uint256 optionId);
    event PollTitleUpdated(uint256 indexed tokenId, string title);
    event PollCreated(uint256 indexed tokenId, string title);

    modifier onlyOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == msg.sender, "PollHub: token doesn't belong to you");
        _;
    }

    modifier pollNotOpened(uint256 tokenId) {
        require(_pollDeadline[tokenId] == 0, "PollHub: poll is either opened or closed");
        _;
    }

    modifier pollOpen(uint256 tokenId) {
        require(_pollDeadline[tokenId] > block.number, "PollHub: poll is either not opened or closed");
        _;
    }

    modifier hasAmountOfVote(uint256 amount) {
        IVoteHub VoteHub = IVoteHub(_getAddressOf("VOTE_HUB"));
        require(VoteHub.balanceOf(msg.sender) >= amount, "PollHub: you don't have enough Vote token");
        _;
    }

    modifier pollExists(uint256 tokenId) {
        require(_exists(tokenId), "PollHub: no poll with such id");
        _;
    }

    modifier optionExists(uint256 tokenId, uint256 optionId) {
        require(optionId < optionsCountOf(tokenId), "PollHub: no option with such id");
        _;
    }

    constructor(string memory name, string memory symbol) BXP721(name, symbol) {}

    function setBaseTokenURI(string memory baseTokenURI) public {
        require(hasRole("POLL_MANAGER_ROLE", msg.sender), "PollHub: not allowed");

        _baseTokenURI = baseTokenURI;

        emit BaseTokenURISet(baseTokenURI);
    }

    function setRequiredAmountOfVote(uint256 amount) external {
        require(hasRole("POLL_MANAGER_ROLE", msg.sender), "PollHub: only poll manager has right to perform that");
        require(amount >= 1 ether, "PollHub: amount must be greater than 1 BXN");

        requiredAmountOfVote = amount;

        emit RequiredAmountOfVoteSet(amount);
    }

    function setRequiredAmountOfBXN(uint256 amount) external {
        require(hasRole("POLL_MANAGER_ROLE", msg.sender), "PollHub: only poll manager has right to perform that");
        require(amount >= 1 ether, "PollHub: amount must be greater than 1 BXN");

        requiredAmountOfBXN = amount;

        emit RequiredAmountOfBXNSet(amount);
    }

    function setPollPrice(uint256 amount) external {
        require(hasRole("POLL_MANAGER_ROLE", msg.sender), "PollHub: only poll manager has right to perform that");
        require(amount >= 1 ether, "PollHub: amount must be greater than 1 BXN");

        pollPrice = amount;

        emit PollPriceSet(amount);
    }

    function setPollCreatorFee(uint256 value) external {
        require(hasRole("POLL_MANAGER_ROLE", msg.sender), "PollHub: only poll manager has right to perform that");
        require(0 < value && value < 5000, "PollHub: only integer values in range (0, 5000) are allowed");

        pollCreatorFee = value;

        emit PollCreatorFeeSet(value);
    }

    function mint(string memory title) external hasAmountOfVote(requiredAmountOfVote) {
        require(msg.sender.balance >= requiredAmountOfBXN);
        uint256 curId = _tokenIdTracker.current();

        _pollTitles[curId] = title;

        _mint(msg.sender, curId);
        _tokenIdTracker.increment();

        emit PollCreated(curId, title);
    }

    function burn(uint256 tokenId) external onlyOwner(tokenId) pollNotOpened(tokenId) {
        super._burn(tokenId);
    }

    function titleOf(uint256 tokenId) public view pollExists(tokenId) returns(string memory) {
        return _pollTitles[tokenId];
    }

    function updateTitle(uint256 tokenId, string memory title) public onlyOwner(tokenId) pollNotOpened(tokenId) {
        _pollTitles[tokenId] = title;

        emit PollTitleUpdated(tokenId, title);
    }

    function optionOfPollByIndex(uint256 tokenId, uint256 optionId) public view optionExists(tokenId, optionId) returns(string memory) {
        return _pollOptions[tokenId][optionId];
    }

    function optionsCountOf(uint256 tokenId) public view pollExists(tokenId) returns(uint256) {
        return _pollOptions[tokenId].length;
    }

    function addOption(uint256 tokenId, string memory option) external onlyOwner(tokenId) pollNotOpened(tokenId) {
        _pollOptions[tokenId].push(option);
        _pollVoteAmount[tokenId].push();

        emit PollOptionAdded(tokenId, option);
    }

    function removeOption(uint256 tokenId, uint256 optionId) external onlyOwner(tokenId) pollNotOpened(tokenId) optionExists(tokenId, optionId) {
        for(uint i = optionId; i < optionsCountOf(tokenId) - 1; i++){
            _pollOptions[tokenId][i] = _pollOptions[tokenId][i + 1];
        }
        _pollOptions[tokenId].pop();
        _pollVoteAmount[tokenId].pop();

        emit PollOptionRemoved(tokenId, optionId);
    }

    function updateOption(uint256 tokenId, uint256 optionId, string memory option) public onlyOwner(tokenId) pollNotOpened(tokenId) optionExists(tokenId, optionId) {
        _pollOptions[tokenId][optionId] = option;

        emit PollOptionUpdated(tokenId, optionId, option);
    }

    function start(uint256 tokenId, uint256 blockDeadline) external payable onlyOwner(tokenId) pollNotOpened(tokenId) {
        require(msg.value == pollPrice, "PollHub: insufficient amount paid");
        require(blockDeadline > block.number, "PollHub: deadline block number must be in future");

        _pollDeadline[tokenId] = blockDeadline;

        (bool systemResult,) = SYSTEM_CONTRACT_ADDRESS.call{value:pollPrice}("");
        require(systemResult, "PollHub: failed to send tokens to System");
        emit PollStarted(tokenId, blockDeadline);
    }

    function deadlineBlockOf(uint256 tokenId) public view returns(uint256) {
        return _pollDeadline[tokenId];
    }

    function updateDeadlineBlock(uint256 tokenId, uint256 newBlockDeadline) external onlyOwner(tokenId) pollOpen(tokenId) {
        require(newBlockDeadline > _pollDeadline[tokenId], "PollHub: new deadline block must be greater than current one");

        _pollDeadline[tokenId] = newBlockDeadline;

        emit PollDeadlineBlockUpdated(tokenId, newBlockDeadline);
    }

    function vote(uint256 tokenId, uint256 optionId, uint256 amountOfVote) external pollOpen(tokenId) optionExists(tokenId, optionId) hasAmountOfVote(amountOfVote) {
        IVoteHub VoteHub = IVoteHub(_getAddressOf("VOTE_HUB"));

        _pollVoteAmount[tokenId][optionId] += amountOfVote;
        _pollTotalVoteAmount[tokenId] += amountOfVote;

        uint256 fee = amountOfVote * pollCreatorFee / 10000;

        VoteHub.burn(msg.sender, amountOfVote - fee);
        VoteHub.transferFrom(msg.sender, ownerOf(tokenId), fee);
        VoteHub.burn(ownerOf(tokenId), fee);

        emit Vote(msg.sender, tokenId, optionId, amountOfVote);
    }

    function votesByOptionOf(uint256 tokenId, uint256 optionId) public view returns(uint256) {
        return _pollVoteAmount[tokenId][optionId];
    }
    
    function totalVotesOf(uint256 tokenId) public view returns(uint256) {
        return _pollTotalVoteAmount[tokenId];
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
}