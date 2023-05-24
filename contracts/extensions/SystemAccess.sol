// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../interfaces/IAccessControlHub.sol";
import "../interfaces/ISystem.sol";


contract SystemAccess {
    address public SYSTEM_CONTRACT_ADDRESS = address(0x0000000000000000000000000000000000001000);

    modifier onlySystem() {
        require(msg.sender == SYSTEM_CONTRACT_ADDRESS, "SystemAccess: only SYSTEM allowed to execute call");
        _;
    }

    modifier onlyContract(string memory contractName) {
        require(msg.sender == _getAddressOf(contractName), string(abi.encodePacked("SystemAccess: only ", contractName, " allowed to execute call")));
        _;
    }

    modifier transfersAvailable() {
        IAccessControlHub AccessControlHub = IAccessControlHub(_getAddressOf("ACCESS_CONTROL_HUB"));

        require(AccessControlHub.transfersAvailable(address(this)), "SystemAccess: token can't be transferred while transfers are paused");
        _;
    }

    /**
     * @dev Development method
     *
     * WARNING: DO NOT USE IN PRODUCTION
     */

    /*function setSystemContractAddress(address name) public {
        SYSTEM_CONTRACT_ADDRESS = name;
    }*/


    function _getSystemContractInstance() internal view returns(ISystem) {
        return ISystem(SYSTEM_CONTRACT_ADDRESS);
    }

    function _getAddressOf(string memory name) internal view returns(address) {
        ISystem System = _getSystemContractInstance();
        return System.getAddressOf(name);
    }

    function hasRole(string memory role, address account) public view returns(bool) {
        IAccessControlHub AccessControlHub = IAccessControlHub(_getAddressOf("ACCESS_CONTROL_HUB"));
        return AccessControlHub.hasStringRole(role, account);
    }
}
