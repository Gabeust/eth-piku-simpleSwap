// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SimpleSwap - A basic decentralized token swap contract with liquidity pools
/// @author Gabriel
/// @notice This contract allows users to add/remove liquidity and swap ERC20 tokens in pairs,
/// @dev Reserves and liquidity are stored per token pair, independent of token order.
contract SimpleSwap {

    /// @notice Struct to hold reserves for a token pairz
    struct Reserve {
        uint256 tokenAReserve;
        uint256 tokenBReserve;
    }
    /// @notice Reserves for each token pair: reserves[tokenA][tokenB]
    mapping(address => mapping(address => Reserve)) public reserves;
    /// @notice Liquidity mapping: liquidity[user][tokenA][tokenB]
    mapping(address => mapping(address => mapping(address => uint256))) public liquidity;

    /// @notice Adds liquidity to a token pair
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param amountADesired Desired amount of token A to deposit
    /// @param amountBDesired Desired amount of token B to deposit
    /// @param amountAMin Minimum acceptable amount of token A (slippage protection)
    /// @param amountBMin Minimum acceptable amount of token B (slippage protection)
    /// @param to Address to receive the liquidity
    /// @param deadline Latest timestamp the transaction can be executed
    /// @return amountA Actual amount of token A used
    /// @return amountB Actual amount of token B used
    /// @return liquidityMinted Amount of liquidity added to the user's balance
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidityMinted) {
        require(block.timestamp <= deadline, "EXPIRED");

        Reserve storage reserve = reserves[tokenA][tokenB];

        if (reserve.tokenAReserve == 0 && reserve.tokenBReserve == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            uint amountBOptimal = (amountADesired * reserve.tokenBReserve) / reserve.tokenAReserve;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "INSUFFICIENT_B_AMOUNT");
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint amountAOptimal = (amountBDesired * reserve.tokenAReserve) / reserve.tokenBReserve;
                require(amountAOptimal >= amountAMin, "INSUFFICIENT_A_AMOUNT");
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
        }

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        reserve.tokenAReserve += amountA;
        reserve.tokenBReserve += amountB;

        liquidity[to][tokenA][tokenB] += amountA + amountB;
        liquidityMinted = amountA + amountB;
    }
    /// @notice Removes liquidity from a token pair
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param liquidityAmount Amount of liquidity to withdraw
    /// @param amountAMin Minimum acceptable amount of token A (slippage protection)
    /// @param amountBMin Minimum acceptable amount of token B (slippage protection)
    /// @param to Address to receive withdrawn tokens
    /// @param deadline Latest timestamp the transaction can be executed
    /// @return amountA Amount of token A returned to the user
    /// @return amountB Amount of token B returned to the user
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidityAmount,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB) {
        require(block.timestamp <= deadline, "EXPIRED");

        Reserve storage reserve = reserves[tokenA][tokenB];
        uint userLiquidity = liquidity[msg.sender][tokenA][tokenB];
        require(userLiquidity >= liquidityAmount, "INSUFFICIENT_LIQUIDITY");

        uint totalLiquidity = reserve.tokenAReserve + reserve.tokenBReserve;
        amountA = (liquidityAmount * reserve.tokenAReserve) / totalLiquidity;
        amountB = (liquidityAmount * reserve.tokenBReserve) / totalLiquidity;

        require(amountA >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "INSUFFICIENT_B_AMOUNT");

        liquidity[msg.sender][tokenA][tokenB] -= liquidityAmount;
        reserve.tokenAReserve -= amountA;
        reserve.tokenBReserve -= amountB;

        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);
    }

    /// @notice Swaps a fixed amount of tokenIn for as much tokenOut as possible
    /// @param amountIn Exact amount of tokenIn to send
    /// @param amountOutMin Minimum acceptable amount of tokenOut (slippage protection)
    /// @param path Array of [tokenIn, tokenOut]
    /// @param to Address to receive tokenOut
    /// @param deadline Latest timestamp the transaction can be executed
    /// @return amountOut Amount of tokenOut sent to the user
     function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint amountOut) {
        require(block.timestamp <= deadline, "EXPIRED");
        require(path.length == 2, "ONLY_TWO_TOKENS_SUPPORTED");

        address tokenIn = path[0];
        address tokenOut = path[1];

        Reserve storage reserve = reserves[tokenIn][tokenOut];
        uint reserveIn = reserve.tokenAReserve;
        uint reserveOut = reserve.tokenBReserve;

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        reserve.tokenAReserve += amountIn;
        reserve.tokenBReserve -= amountOut;

        IERC20(tokenOut).transfer(to, amountOut);
    }
    /// @notice Returns the price of 1 tokenA in terms of tokenB
    /// @param tokenA Address of input token
    /// @param tokenB Address of output token
    /// @return price Price of 1 tokenA denominated in tokenB (scaled by 1e18)
    function getPrice(address tokenA, address tokenB) external view returns (uint price) {
        Reserve storage reserve = reserves[tokenA][tokenB];
        require(reserve.tokenAReserve > 0, "NO_LIQUIDITY");

        price = (reserve.tokenBReserve * 1e18) / reserve.tokenAReserve;
    }

    /// @notice Calculates output amount for a given input and reserves
    /// @param amountIn Amount of input tokens
    /// @param reserveIn Reserve of input tokens in the pool
    /// @param reserveOut Reserve of output tokens in the pool
    /// @return amountOut Calculated output token amount
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut) {
        uint amountInWithFee = amountIn * 997;
        uint numerator = amountInWithFee * reserveOut;
        uint denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }
}