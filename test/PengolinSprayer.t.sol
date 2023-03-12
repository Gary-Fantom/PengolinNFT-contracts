// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "./ICheatcodes.sol";
import "../contracts/PengolinNft.sol";
import "../contracts/PengolinToken.sol";
import "../contracts/PengolinSprayer.sol";

contract PengolinSprayerTest is DSTest {
    CheatCodes constant cheats = CheatCodes(HEVM_ADDRESS);

    string baseUri = "https://static.pengolincoin.xyz/arts/jsons/";
    uint96 feeNumerator = 1000; // royalty is 10%
    uint256 maxSupply = 5000;
    PengolinNft pengolinNft;
    PengolinToken pengolinToken;
    PengolinSprayer pengolinSprayer;
    uint256 betAmount = 10;
    uint256 feePercent = 1000;
    uint256 playerCountOfRoom = 4;
    address ownerAddress = 0x817A04162a35c1B63Ddb3c5E9eA015ffeA469de7;
    address[] userAddresses;

    function setUp() public {
        cheats.deal(ownerAddress, 100 ether);
        cheats.prank(ownerAddress);
        pengolinNft = new PengolinNft(
            "PengolinNft",
            "PGN",
            baseUri,
            maxSupply,
            ownerAddress,
            feeNumerator
        );
        pengolinToken = new PengolinToken("PengolinToken", "PGO");
        pengolinSprayer = new PengolinSprayer(
            address(pengolinNft),
            address(pengolinToken),
            betAmount,
            feePercent,
            playerCountOfRoom
        );

        userAddresses = new address[](5);
        userAddresses[0] = 0xF31070b090D7375ee47078Ee5AE877F880f7ed11;
        userAddresses[1] = 0x2D84A7f59e2530A6B3C6065394D2FA36b61f42FE;
        userAddresses[2] = 0xF9416452a1f5dA51b535D5e45Ee8a8e1023B5e10;
        userAddresses[3] = 0xcb16C9D71227fa3916895586298E733103404D58;
        userAddresses[4] = 0x3ad739315eb4Ea20caeBe66C1Dc27D94BFd87eEE;
    }

    function testControllers() public {
        cheats.prank(ownerAddress);
        pengolinNft.addController(address(this));
        assertEq(pengolinNft.controllers(address(this)) ? 1 : 0, 1);
        cheats.prank(ownerAddress);
        pengolinNft.removeController(address(this));
        assertEq(pengolinNft.controllers(address(this)) ? 1 : 0, 0);
    }

    function testEnterRoom() public {
        for (uint256 i = 0; i < 5; i++) {
            cheats.deal(userAddresses[i], 100 ether);
            pengolinToken.transfer(userAddresses[i], 100 ether);
        }

        uint256 roomId = 1;
        uint32 tokenId = 0;
        uint256 itemOption = 1;

        cheats.prank(userAddresses[0]);
        pengolinNft.mint{value: 0.1 ether}(1);

        // verify the player is owner of an NFT
        cheats.prank(userAddresses[1]);
        cheats.expectRevert(bytes("PLAYER_NOT_OWNER_OF_NFT"));
        pengolinSprayer.enterRoom(roomId, tokenId, itemOption);

        assertEq(pengolinToken.balanceOf(userAddresses[1]), 100 ether);
        
        // verify the result is correct
        cheats.prank(userAddresses[0]);
        pengolinSprayer.enterRoom(roomId, tokenId, itemOption);
        // assertEq(pengolinSprayer.mapRoomInfo(roomId).countPlayers, 1);
    }
}
