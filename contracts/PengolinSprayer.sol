// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interface/IPengolinToken.sol";

/**
 * @title PengolinSprayer
 * @author Bounyavong
 * @dev PengolinSprayer is a contract for the PengolinSprayer game which players deposit tokens to play the game
  and a winner receive the reward by admin side
 */
contract PengolinSprayer is Ownable, Pausable, ReentrancyGuard {
    // controllers
    mapping(address => bool) public controllers;

    // struct for game information
    struct GameInfo {
        address addressPengolinNFT; // the address of the ERC721 PengolinNFT
        address addressPengolinToken; // the address of the ERC20 PengolinToken
        uint16 betAmount; // deposit amount for each player before entering the game by PGO unit
        uint16 feePercent; // percent of the fee, 10,000 is 100%
        uint16 playerCountOfRoom; /* count of the players in a room, it must be constant 
                                 because the game will start only with this number of players */
    }
    GameInfo public gameInfo;

    // struct for game room information
    struct RoomInfo {
        uint16 countPlayers;
        uint256 totalBetAmount;
        mapping(address => uint256) mapPlayerBetAmount;
    }
    // mapping from roomId to RoomInfo structure
    mapping(uint256 => RoomInfo) public mapRoomInfo;

    // total fee amount
    uint256 TOTAL_FEE_AMOUNT;

    /** EVENTS */

    // emit when a player enters a room
    event PlayerEntered(
        uint256 indexed roomId,
        address indexed playerAddress,
        uint256 indexed tokenId
    );
    // emit when a player leaves a room before the match starts
    event PlayerLeft(
        uint256 indexed roomId,
        address indexed playerAddress,
        uint256 indexed tokenId
    );
    // emit when a winner get paid after end of the game
    event WinnerPaid(
        uint256 indexed roomId,
        address indexed winnerAddress,
        uint256 indexed paidAmount
    );

    constructor(
        address _addressPengolinNFT,
        address _addressPengolinToken,
        uint256 _betAmount,
        uint256 _feePercent,
        uint256 _playerCountOfRoom
    ) {
        gameInfo = GameInfo(
            _addressPengolinNFT,
            _addressPengolinToken,
            uint16(_betAmount),
            uint16(_feePercent),
            uint16(_playerCountOfRoom)
        );
        controllers[_msgSender()] = true;
    }

    /** USER */

    /**
     * @dev a player enters a room
     * @param roomId is the room uuid coming from the game server
     * @param tokenId is the tokenId of the PengolinNFT token that the player owns
     * @param itemOption is the option how many items you buy when you play the game
     */
    function enterRoom(
        uint256 roomId,
        uint32 tokenId,
        uint256 itemOption
    ) external nonReentrant {
        require(
            mapRoomInfo[roomId].countPlayers < gameInfo.playerCountOfRoom,
            "ROOM_IS_FULL"
        );
        require(
            IERC721(gameInfo.addressPengolinNFT).ownerOf(tokenId) ==
                _msgSender(),
            "PLAYER_NOT_OWNER_OF_NFT"
        );
        require(
            mapRoomInfo[roomId].mapPlayerBetAmount[_msgSender()] == 0,
            "ALREADY_ENTERED"
        );

        uint256 _betAmount = (gameInfo.betAmount + itemOption) * (1 ether);
        IERC20(gameInfo.addressPengolinToken).transferFrom(
            _msgSender(),
            address(this),
            _betAmount
        );
        mapRoomInfo[roomId].countPlayers++;
        mapRoomInfo[roomId].mapPlayerBetAmount[_msgSender()] = _betAmount;
        mapRoomInfo[roomId].totalBetAmount += _betAmount;
        emit PlayerEntered(roomId, _msgSender(), tokenId);
    }

    /**
     * @dev a player leaves a room
     * @param roomId is the room uuid coming from the game server
     * @param tokenId is the tokenId of the PengolinNFT token that the player owns
     */
    function leaveRoom(uint256 roomId, uint32 tokenId) external nonReentrant {
        require(
            mapRoomInfo[roomId].countPlayers < gameInfo.playerCountOfRoom,
            "GAME_STARTED_ALREADY"
        );
        require(
            IERC721(gameInfo.addressPengolinNFT).ownerOf(tokenId) ==
                _msgSender(),
            "PLAYER_NOT_OWNER_OF_NFT"
        );
        uint256 _betAmount = mapRoomInfo[roomId].mapPlayerBetAmount[
            _msgSender()
        ];
        require(_betAmount > 0, "NOT_ENTERED_PLAYER");
        delete mapRoomInfo[roomId].mapPlayerBetAmount[_msgSender()];
        mapRoomInfo[roomId].totalBetAmount -= _betAmount;
        IERC20(gameInfo.addressPengolinToken).transferFrom(
            address(this),
            _msgSender(),
            _betAmount
        );
        mapRoomInfo[roomId].countPlayers--;

        emit PlayerLeft(roomId, _msgSender(), tokenId);
    }

    /** CONTROLLER */

    /**
     * @dev pay the winner of the game
     * @param roomId is the room uuid coming from the game server
     * @param winnerAddress is the winner address of the game
     */
    function payWinner(uint256 roomId, address winnerAddress)
        external
        onlyController
        nonReentrant
    {
        require(
            mapRoomInfo[roomId].countPlayers == gameInfo.playerCountOfRoom,
            "GAME_NOT_STARTED"
        );
        uint256 _betAmount = mapRoomInfo[roomId].totalBetAmount;
        require(_betAmount > 0, "ALREADY_PAID");
        mapRoomInfo[roomId].totalBetAmount = 0;

        uint256 _winnerPrize = (gameInfo.betAmount *
            (1 ether) *
            gameInfo.playerCountOfRoom *
            (10000 - gameInfo.feePercent)) / 10000;
        uint256 _feeAmount = _betAmount - _winnerPrize;
        TOTAL_FEE_AMOUNT += _feeAmount;
        IERC20(gameInfo.addressPengolinToken).transferFrom(
            address(this),
            winnerAddress,
            _winnerPrize
        );

        delete mapRoomInfo[roomId];
        emit WinnerPaid(roomId, winnerAddress, _winnerPrize);
    }

    /** ADMIN */

    /**
     * @dev enables an address to mint
     * @param _controller the address to enable
     */
    function addController(address _controller) external onlyOwner {
        controllers[_controller] = true;
    }

    /**
     * @dev disables an address from minting
     * @param _controller the address to disbale
     */
    function removeController(address _controller) external onlyOwner {
        delete controllers[_controller];
    }

    /**
     * @dev set game info by owner
     * @param _gameInfo new game info struct
     */
    function setGameInfo(GameInfo memory _gameInfo) external onlyOwner {
        gameInfo = _gameInfo;
    }

    /** MODIFIER */

    modifier onlyController() {
        require(controllers[_msgSender()] == true, "ONLY_CONTROLLER");
        _;
    }
}
