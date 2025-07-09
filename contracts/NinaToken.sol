// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title NinaToken - ERC20 token with owner-controlled minting
/// @author Gabriel
/// @notice This contract implements an ERC20 token named "Nina token" with symbol "NINX".
///         The contract owner has exclusive rights to mint new tokens.
/// @dev Inherits from OpenZeppelin ERC20. Access control is managed via the onlyOwner modifier.
contract NinaToken is ERC20 {

    /// @notice Address of the contract owner with exclusive permissions
    address public owner;

    /// @notice Modifier to restrict function calls to the owner only
    modifier onlyOwner() {
        require(owner == msg.sender, "not the owner");
        _;
    }

    /// @notice Constructor that sets token name, symbol and mints initial supply to the deployer
    /// @dev Initial supply of 1,000,000 tokens (with 18 decimals) minted to contract deployer
    constructor() ERC20("Nina token", "NINX") {
        owner = msg.sender;
        _mint(msg.sender, 1_000_000 ether);
    }

    /// @notice Mint new tokens to a specified address, callable only by the owner
    /// @param recipient Address to receive minted tokens
    /// @param amount Number of tokens to mint (including decimals)
    function mint(address recipient, uint amount) public onlyOwner {
        _mint(recipient, amount);
    }
}
