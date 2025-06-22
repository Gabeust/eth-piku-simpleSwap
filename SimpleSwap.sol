// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SimpleSwap - A basic decentralized token swap contract with liquidity pools
/// @author Gabriel
/// @notice This contract allows users to add/remove liquidity and swap ERC20 tokens in pairs,
///         following a Uniswap-like automated market maker (AMM) model with a 0.3% fee.
/// @dev Reserves and liquidity are stored per token pair, independent of token order.

contract SimpleSwap {

    /// @notice Struct to store reserves of two tokens in a pair
    struct Reserve {
        uint256 reserveA;
        uint256 reserveB;
    }

    /// @notice Mapping from pair key (hash of token addresses) to their reserves
    mapping(bytes32 => Reserve) public reserves;

    /// @notice Mapping from user address and pair key to user's liquidity balance
    mapping(address => mapping(bytes32 => uint256)) public liquidity;

    /// @notice Internal helper to generate a unique key for a token pair (order-independent)
    /// @param tokenA Address of first token
    /// @param tokenB Address of second token
    /// @return pairKey Unique key representing the token pair
    function _pairKey(address tokenA, address tokenB) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            tokenA < tokenB ? tokenA : tokenB,
            tokenA < tokenB ? tokenB : tokenA
        ));
    }

    /// @notice Adds liquidity to a token pair pool
    /// @param tokenA Address of first token
    /// @param tokenB Address of second token
    /// @param amountADesired Desired amount of tokenA to add
    /// @param amountBDesired Desired amount of tokenB to add
    /// @param amountAMin Minimum amount of tokenA to add (slippage protection)
    /// @param amountBMin Minimum amount of tokenB to add (slippage protection)
    /// @param to Address to receive liquidity tokens
    /// @param deadline Timestamp after which the transaction is invalid
    /// @return amountA Actual amount of tokenA added
    /// @return amountB Actual amount of tokenB added
    /// @return liquidityMinted Amount of liquidity tokens minted to `to`
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
        bytes32 pairKey = _pairKey(tokenA, tokenB);
        Reserve storage r = reserves[pairKey];

        if (r.reserveA == 0 && r.reserveB == 0) {
            amountA = amountADesired;
            amountB = amountBDesired;
        } else {
            uint amountBOptimal = (amountADesired * r.reserveB) / r.reserveA;
            if (amountBOptimal <= amountBDesired) {
                require(amountBOptimal >= amountBMin, "INSUFFICIENT_B_AMOUNT");
                amountA = amountADesired;
                amountB = amountBOptimal;
            } else {
                uint amountAOptimal = (amountBDesired * r.reserveA) / r.reserveB;
                require(amountAOptimal >= amountAMin, "INSUFFICIENT_A_AMOUNT");
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }
        }

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        r.reserveA += amountA;
        r.reserveB += amountB;

        liquidity[to][pairKey] += amountA + amountB;
        liquidityMinted = amountA + amountB;
    }

    /// @notice Removes liquidity from a token pair pool
    /// @param tokenA Address of first token
    /// @param tokenB Address of second token
    /// @param liquidityAmount Amount of liquidity tokens to burn
    /// @param amountAMin Minimum amount of tokenA to receive (slippage protection)
    /// @param amountBMin Minimum amount of tokenB to receive (slippage protection)
    /// @param to Address to receive tokens
    /// @param deadline Timestamp after which the transaction is invalid
    /// @return amountA Amount of tokenA withdrawn
    /// @return amountB Amount of tokenB withdrawn
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
        bytes32 pairKey = _pairKey(tokenA, tokenB);

        uint userLiquidity = liquidity[msg.sender][pairKey];
        require(userLiquidity >= liquidityAmount, "NOT_ENOUGH_LIQUIDITY");

        Reserve storage r = reserves[pairKey];
        uint totalLiquidity = r.reserveA + r.reserveB;

        amountA = (liquidityAmount * r.reserveA) / totalLiquidity;
        amountB = (liquidityAmount * r.reserveB) / totalLiquidity;

        require(amountA >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "INSUFFICIENT_B_AMOUNT");

        liquidity[msg.sender][pairKey] -= liquidityAmount;
        r.reserveA -= amountA;
        r.reserveB -= amountB;

        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);
    }

    /// @notice Swaps an exact amount of input tokens for output tokens
    /// @param amountIn Amount of input tokens to send
    /// @param amountOutMin Minimum amount of output tokens to receive
    /// @param path Array of token addresses (only 2 tokens supported)
    /// @param to Recipient address of output tokens
    /// @param deadline Timestamp after which the transaction is invalid
    /// @return amounts Array containing input and output amounts
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts) {
        require(path.length == 2, "ONLY_DIRECT_SWAPS");
        require(block.timestamp <= deadline, "EXPIRED");

        address tokenIn = path[0];
        address tokenOut = path[1];

        bytes32 pairKey = _pairKey(tokenIn, tokenOut);
        Reserve storage r = reserves[pairKey];

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        (uint reserveIn, uint reserveOut) = tokenIn < tokenOut ? (r.reserveA, r.reserveB) : (r.reserveB, r.reserveA);

        uint amountInWithFee = amountIn * 997;
        uint amountOut = (amountInWithFee * reserveOut) / (reserveIn * 1000 + amountInWithFee);

        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        if (tokenIn < tokenOut) {
            r.reserveA += amountIn;
            r.reserveB -= amountOut;
        } else {
            r.reserveB += amountIn;
            r.reserveA -= amountOut;
        }

        IERC20(tokenOut).transfer(to, amountOut);

        amounts = new uint[](2) ;
        amounts[0] = amountIn;
        amounts[1] = amountOut;
        return amounts;
    }

    /// @notice Returns the price of tokenA in terms of tokenB
    /// @param tokenA Address of tokenA
    /// @param tokenB Address of tokenB
    /// @return price Price scaled by 1e18 (tokenB per tokenA)
    function getPrice(address tokenA, address tokenB) external view returns (uint price) {
        bytes32 pairKey = _pairKey(tokenA, tokenB);
        Reserve storage r = reserves[pairKey];

        (uint reserveIn, uint reserveOut) = tokenA < tokenB ? (r.reserveA, r.reserveB) : (r.reserveB, r.reserveA);
        require(reserveIn > 0, "NO_LIQUIDITY");

        price = (reserveOut * 1e18) / reserveIn;
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
