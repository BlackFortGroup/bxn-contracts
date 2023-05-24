// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./interfaces/IAccessControlHub.sol";


contract AccessControlHub is IAccessControlHub, AccessControl {
    address private constant DEFAULT_ADMIN_ROLE_ADDRESS = address(0x50E7Ad751BA952f5b5b1Ef8bdBB83E4e49B94B8F);
    bool private _initialized = false;

    mapping(address => bool) private _transferAllowed;

    event TransfersEnabled(address account);
    event TransfersDisabled(address account);
    event Initialized();

    modifier whenTransfersEnabled(address account) {
        require(transfersAvailable(account), "AccessControlHub: transfers are disabled");
        _;
    }

    modifier whenTransfersDisabled(address account) {
        require(!transfersAvailable(account), "AccessControlHub: transfers are enabled");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function init() external {
        require(DEFAULT_ADMIN_ROLE_ADDRESS == msg.sender, "AccessControlHub: not allowed");
        require(!_initialized, "AccessControlHub: already initialized");

        _initialized = true;
        _setupRole(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE_ADDRESS);

        emit Initialized();
    }

    function transfersAvailable(address account) public view override returns (bool) {
        require(account != address(0), "AccessControlHub: request to the zero address");

        return _transferAllowed[account];
    }

    function hasStringRole(string memory stringRole, address account) public view override returns(bool) {
        return hasRole(keccak256(bytes(stringRole)), account);
    }

    function enableTransfers(address account) external whenTransfersDisabled(account) {
        require(hasStringRole("ACCESS_CONTROL_MANAGER_ROLE", _msgSender()), "AccessControlHub: must have access control manager role to pause transfers");

        _transferAllowed[account] = true;
        emit TransfersEnabled(account);
    }

    function disableTransfers(address account) external whenTransfersEnabled(account) {
        require(hasStringRole("ACCESS_CONTROL_MANAGER_ROLE", _msgSender()), "AccessControlHub: must have access control manager role to unpause transfers");
        _transferAllowed[account] = false;
        emit TransfersDisabled(account);
    }
}