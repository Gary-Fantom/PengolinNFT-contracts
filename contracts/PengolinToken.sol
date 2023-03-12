// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title PengolinToken
/// @author Bounyavong
/// @dev PengolinToken is a simple ERC20Burnable token
contract PengolinToken is ERC20Burnable, Ownable {
    // limit of total supply
    uint256 public constant LIMIT_SUPPLY = 1000000 ether;

    // a mapping from an address to whether or not it can mint
    mapping(address => bool) public controllers;

    /**
     * @dev Event that is emitted when tokens are minted
     * @param caller Address of the _msgSender()
     * @param to Address which receives ERC20 tokens
     * @param amount Amount of the ERC20
     */
    event Minted(
        address indexed caller,
        address indexed to,
        uint256 indexed amount
    );

    /**
     * @dev Event that is emitted when a controller is added or removed
     * @param controller Address of the controller
     * @param isController Flag whether it's a controller or not
     */
    event SetController(address indexed controller, bool indexed isController);

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        controllers[_msgSender()] = true;
    }

    /** CONTROLLER */

    /**
     * @dev mint PGO token by owner
     * @param to Address which receives ERC20 tokens
     * @param amount the amount of PGO to mint
     */
    function mint(address to, uint256 amount) external onlyController {
        require(totalSupply() + amount <= LIMIT_SUPPLY, "OUT_OF_LIMIT");
        _mint(to, amount);
        emit Minted(_msgSender(), to, amount);
    }

    /** ADMIN */

    /**
     * @dev enables an address to mint
     * @param _controller the address to enable
     */
    function addController(address _controller) external onlyOwner {
        controllers[_controller] = true;
        emit SetController(_controller, true);
    }

    /**
     * @dev disables an address from minting
     * @param _controller the address to disbale
     */
    function removeController(address _controller) external onlyOwner {
        delete controllers[_controller];
        emit SetController(_controller, false);
    }

    /** MODIFIER */

    modifier onlyController() {
        require(controllers[_msgSender()] == true, "ONLY_CONTROLLER");
        _;
    }
}
