// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "ds-test/test.sol";
import "./ICheatcodes.sol";
import "../contracts/PengolinNft.sol";

contract PengolinNftTest is DSTest {
    CheatCodes constant cheats = CheatCodes(HEVM_ADDRESS);

    string baseUri = "https://static.pengolincoin.xyz/arts/jsons/";
    uint96 feeNumerator = 1000; // royalty is 10%
    uint256 maxSupply = 5000;
    address ownerAddress = 0x817A04162a35c1B63Ddb3c5E9eA015ffeA469de7;
    PengolinNft pengolinNft;

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
    }

    function testControllers() public {
        cheats.prank(ownerAddress);
        pengolinNft.addController(address(this));
        assertEq(pengolinNft.controllers(address(this)) ? 1 : 0, 1);
        cheats.prank(ownerAddress);
        pengolinNft.removeController(address(this));
        assertEq(pengolinNft.controllers(address(this)) ? 1 : 0, 0);
    }

    function testMint() public {
        address to = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        cheats.deal(to, 100 ether);

        cheats.prank(to);
        pengolinNft.mint{value: 0.5 ether}(5);

        // verify the result is correct
        assertEq(pengolinNft.balanceOf(to), 5);
    }
}
