// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title ErosToken - ERC20 token with owner-controlled minting
/// @author Gabriel
/// @notice This contract implements an ERC20 token named "Eros token" with symbol "ERX".
///         The contract owner has the exclusive ability to mint additional tokens.
/// @dev Inherits from OpenZeppelin ERC20 and includes an onlyOwner modifier for access control.
contract ErosToken is ERC20 {

    /// @notice Address of the contract owner with exclusive permissions
    address public owner;

    /// @notice Modifier to restrict function access to the owner only
    modifier onlyOwner() {
        require(owner == msg.sender, "not the owner");
        _;
    }

    /// @notice Constructor that initializes the token and mints the initial supply to the deployer
    /// @dev Mints 1,000,000 tokens (with 18 decimals) to the owner (msg.sender)
    constructor() ERC20("Eros token", "ERX") {
        owner = msg.sender;
        _mint(msg.sender, 1_000_000 ether);
    }

    /// @notice Allows the owner to mint new tokens to a specified address
    /// @param recipient The address to receive the newly minted tokens
    /// @param amount The amount of tokens to mint (considering decimals)
    /// @dev Only callable by the owner
    function mint(address recipient, uint amount) public onlyOwner {
        _mint(recipient, amount);
    }

}
