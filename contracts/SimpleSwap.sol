// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SimpleSwap - A basic decentralized token swap contract with liquidity pools
/// @author Gabriel
/// @notice This contract allows users to add/remove liquidity and swap ERC20 tokens in pairs,
/// @dev Reserves and liquidity are stored per token pair, independent of token order.
contract SimpleSwap {

    /// @notice Struct to hold reserves for a token pair
    struct Reserve {
        uint256 tokenAReserve;
        uint256 tokenBReserve;
    }

    /// @notice Emitted when liquidity is added to the pool
    event LiquidityAdded(
        address indexed provider,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidityMinted
    );

    /// @notice Emitted when liquidity is removed from the pool
    event LiquidityRemoved(
        address indexed provider,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );

    /// @notice Emitted when a token swap is executed
    event SwapExecuted(
        address indexed user,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

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
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidityMinted) {
        require(block.timestamp <= deadline, "EXPIRED");

        Reserve storage reserve = reserves[tokenA][tokenB];
        (amountA, amountB) = _calculateLiquidityAmounts(
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            reserve.tokenAReserve,
            reserve.tokenBReserve
        );

        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        reserve.tokenAReserve += amountA;
        reserve.tokenBReserve += amountB;

        liquidityMinted = amountA + amountB;
        liquidity[to][tokenA][tokenB] += liquidityMinted;

        emit LiquidityAdded(msg.sender, tokenA, tokenB, amountA, amountB, liquidityMinted);
    }

    /// @dev Internal function to calculate optimal liquidity amounts considering slippage
    /// @param amountADesired Desired amount of token A
    /// @param amountBDesired Desired amount of token B
    /// @param amountAMin Minimum amount of token A accepted
    /// @param amountBMin Minimum amount of token B accepted
    /// @param reserveA Current reserve of token A
    /// @param reserveB Current reserve of token B
    /// @return amountA Final amount of token A to deposit
    /// @return amountB Final amount of token B to deposit
    function _calculateLiquidityAmounts(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountA, uint256 amountB) {
        if (reserveA == 0 && reserveB == 0) {
            return (amountADesired, amountBDesired);
        }

        uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;
        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal >= amountBMin, "INSUFFICIENT_B_AMOUNT");
            return (amountADesired, amountBOptimal);
        }

        uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
        require(amountAOptimal >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        return (amountAOptimal, amountBDesired);
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

        Reserve storage pairReserve = reserves[tokenA][tokenB];
        uint256 reserveA = pairReserve.tokenAReserve;
        uint256 reserveB = pairReserve.tokenBReserve;

        uint totalLiquidity = reserveA + reserveB;

        require(liquidity[msg.sender][tokenA][tokenB] >= liquidityAmount, "INSUFFICIENT_LIQUIDITY");

        amountA = (liquidityAmount * reserveA) / totalLiquidity;
        amountB = (liquidityAmount * reserveB) / totalLiquidity;

        require(amountA >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "INSUFFICIENT_B_AMOUNT");

        liquidity[msg.sender][tokenA][tokenB] -= liquidityAmount;

        pairReserve.tokenAReserve = reserveA - amountA;
        pairReserve.tokenBReserve = reserveB - amountB;


        IERC20(tokenA).transfer(to, amountA);
        IERC20(tokenB).transfer(to, amountB);

        emit LiquidityRemoved(msg.sender, tokenA, tokenB, amountA, amountB);
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

        Reserve storage pairReserve = reserves[tokenIn][tokenOut];
        uint256 reserveIn = pairReserve.tokenAReserve;
        uint256 reserveOut = pairReserve.tokenBReserve;

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        pairReserve.tokenAReserve += amountIn;
        pairReserve.tokenBReserve -= amountOut;

        IERC20(tokenOut).transfer(to, amountOut);

        emit SwapExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
    }

    /// @notice Returns the price of 1 tokenA in terms of tokenB
    /// @param tokenA Address of input token
    /// @param tokenB Address of output token
    /// @return price Price of 1 tokenA denominated in tokenB (scaled by 1e18)
    function getPrice(address tokenA, address tokenB) external view returns (uint price) {
        Reserve storage pairReserve = reserves[tokenA][tokenB];
        require(pairReserve.tokenAReserve > 0, "NO_LIQUIDITY");

        price = (pairReserve.tokenBReserve * 1e18) / pairReserve.tokenAReserve;
    }

   /// @notice Calculates output amount for a given input and reserves
   /// @param amountIn Amount of input tokens
   /// @param reserveIn Reserve of input tokens in the pool
   /// @param reserveOut Reserve of output tokens in the pool
   /// @return amountOut Calculated output token amount
   function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut) {
        require(amountIn > 0, "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "SimpleSwap: INSUFFICIENT_LIQUIDITY");

        uint numerator = amountIn * reserveOut;
        uint denominator = reserveIn + amountIn;
        amountOut = numerator / denominator;
    }
}
