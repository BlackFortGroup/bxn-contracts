// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @title BXP721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from BXP721 asset contracts.
 */
interface IBXP721Receiver {
    /**
     * @dev Whenever an {IBXP721} `tokenId` token is transferred to this contract via {IBXP721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IBXP721Receiver.onBXP721Received.selector`.
     */
    function onBXP721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
