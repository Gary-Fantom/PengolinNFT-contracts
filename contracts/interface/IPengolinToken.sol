// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title IPengolinToken
/// @author Bounyavong
/// @dev IPengolinToken is an interface to the PengolinToken
interface IPengolinToken {
    /**
     * @dev mint PGO token by owner
     * @param to Address which receives ERC20 tokens
     * @param amount the amount of PGO to mint
     */
    function mint(address to, uint256 amount) external;
}
