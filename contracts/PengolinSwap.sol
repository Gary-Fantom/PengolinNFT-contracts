// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interface/IPengolinToken.sol";

/**
 * @title PengolinSwap
 * @author Bounyavong
 * @dev PengolinSwap is a contract that mints PGO ERC20 tokens to the caller who is verified to have sent
 * the appropriate amount of old PGO coin to the developer's wallet.
 */
contract PengolinSwap is Ownable, Pausable, ReentrancyGuard {
    /**
     * @dev Mapping of a hashed message to a boolean value indicating whether the hashed message has already been used
     */
    mapping(bytes32 => bool) public msgAlreadyUsed;

    /**
     * @dev Address of the PengolinToken ERC20 contract
     */
    address public PGO_TOKEN;

    /** EVENTS */

    /**
     * @dev Event that is emitted when a user gets PGO ERC20 tokens minted by offering the correct signature
     * that provided by the developer.
     * @param hashedMessage Hashed value of the string ({txID}-{txAmount})
     * @param callerAddress Adress to which the tokens were sent
     * @param amount Amount of the new PGO ERC20 token
     */
    event Swapped(
        bytes32 indexed hashedMessage,
        address indexed callerAddress,
        uint256 indexed amount
    );

    /**
     * @dev Initializes the contract by setting the PGO ERC20 contract address
     * @param _addressPGO PGO ERC20 contract address
     */
    constructor(address _addressPGO) {
        PGO_TOKEN = _addressPGO;
    }

    /** ADMIN */

    /**
     * @dev Pause or unpause the contract features
     */
    function setPause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    /** USER */

    /**
     * @dev Mints PGO ERC20 tokens to the caller's address
     * @param txId Transaction ID of the original PGO coin
     * @param amount PGO ERC20 token amount that is swapped as 100:1 ratio
     * @param _v V of signature
     * @param _r R of signature
     * @param _s S of signature
     */
    function swap(
        string calldata txId,
        uint256 amount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external whenNotPaused {
        bytes32 _hashedMessage = getMessageHash(txId, amount);
        require(msgAlreadyUsed[_hashedMessage] == false, "ALREADY_USED");
        msgAlreadyUsed[_hashedMessage] = true;
        require(
            recoverSigner(_hashedMessage, _v, _r, _s) == owner(),
            "WRONG_SIGNATURE"
        );

        IPengolinToken(PGO_TOKEN).mint(_msgSender(), amount);

        emit Swapped(_hashedMessage, _msgSender(), amount);
    }

    /**
     * @dev Returns hashed bytes of the message of txId and amount
     * @param txId Transaction ID of the original PGO coin
     * @param amount PGO ERC20 token amount that is swapped as 100:1 ratio
     * @return A bytes32 of hashed message
     */
    function getMessageHash(string calldata txId, uint256 amount)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(txId, amount));
    }

    /**
     * @dev Recovers the address of signer from the signature
     * @param _hashedMessage A hashed bytes of the message of txId and amount
     * @param _v V of signature
     * @param _r R of signature
     * @param _s S of signature
     * @return Address of the signer
     */
    function recoverSigner(
        bytes32 _hashedMessage,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHashMessage = keccak256(
            abi.encodePacked(prefix, _hashedMessage)
        );
        return ecrecover(prefixedHashMessage, _v, _r, _s);
    }
}
