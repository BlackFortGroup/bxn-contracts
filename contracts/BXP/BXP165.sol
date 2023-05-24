// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./interfaces/IBXP165.sol";

/**
 * @dev Implementation of the {IBXP165} interface.
 *
 * Contracts that want to implement BXP165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {BXP165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract BXP165 is IBXP165 {
    /**
     * @dev See {IBXP165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IBXP165).interfaceId;
    }
}
