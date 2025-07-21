// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SimpleSwap - A basic decentralized token swap contract with liquidity pools
/// @author Gabriel
/// @notice This contract allows users to add/remove liquidity and swap ERC20 tokens in pairs.
/// @dev Reserves and liquidity are stored per token pair, independent of token order.
contract SimpleSwap {

    /// @notice Struct to hold reserves for a token pair
    struct Reserve {
        /// @notice Reserve amount of token A
        uint256 tokenAReserve;
        /// @notice Reserve amount of token B
        uint256 tokenBReserve;
    }

    /// @notice Emitted when liquidity is added to the pool
    /// @param provider Address of the liquidity provider
    /// @param tokenA Address of token A in the pair
    /// @param tokenB Address of token B in the pair
    /// @param amountA Amount of token A added
    /// @param amountB Amount of token B added
    /// @param liquidityMinted Amount of liquidity tokens minted to provider
    event LiquidityAdded(
        address indexed provider,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidityMinted
    );

    /// @notice Emitted when liquidity is removed from the pool
    /// @param provider Address of the liquidity provider removing liquidity
    /// @param tokenA Address of token A in the pair
    /// @param tokenB Address of token B in the pair
    /// @param amountA Amount of token A removed
    /// @param amountB Amount of token B removed
    event LiquidityRemoved(
        address indexed provider,
        address indexed tokenA,
        address indexed tokenB,
        uint256 amountA,
        uint256 amountB
    );

    /// @notice Emitted when a token swap is executed
    /// @param user Address of the user performing the swap
    /// @param tokenIn Address of the input token
    /// @param tokenOut Address of the output token
    /// @param amountIn Amount of input token sent
    /// @param amountOut Amount of output token received
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
    /// @param to Address to receive the liquidity tokens
    /// @param deadline Latest timestamp the transaction can be executed
    /// @return amountA Actual amount of token A used
    /// @return amountB Actual amount of token B used
    /// @return liquidityMinted Amount of liquidity tokens minted to the user
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

        // Calculate optimal amounts considering current reserves and slippage limits
        (amountA, amountB) = _calculateLiquidityAmounts(
            amountADesired,
            amountBDesired,
            amountAMin,
            amountBMin,
            reserve.tokenAReserve,
            reserve.tokenBReserve
        );

        // Transfer tokens from sender to contract
        IERC20(tokenA).transferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).transferFrom(msg.sender, address(this), amountB);

        // Update reserves with new amounts
        uint256 updatedTokenAReserve = reserve.tokenAReserve + amountA;
        uint256 updatedTokenBReserve = reserve.tokenBReserve + amountB;

        reserve.tokenAReserve = updatedTokenAReserve;
        reserve.tokenBReserve = updatedTokenBReserve;

        // Calculate liquidity minted and update liquidity mapping
        liquidityMinted = amountA + amountB;
        liquidity[to][tokenA][tokenB] += liquidityMinted;

        emit LiquidityAdded(msg.sender, tokenA, tokenB, amountA, amountB, liquidityMinted);
    }

    /// @dev Internal function to calculate optimal liquidity amounts considering slippage
    /// @param amountADesired Desired amount of token A
    /// @param amountBDesired Desired amount of token B
    /// @param amountAMin Minimum acceptable amount of token A (slippage protection)
    /// @param amountBMin Minimum acceptable amount of token B (slippage protection)
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
        // If no reserves, return desired amounts
        if (reserveA == 0 && reserveB == 0) {
            return (amountADesired, amountBDesired);
        }

        // Calculate optimal amountB based on reserve ratio
        uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;

        // Check if optimal amountB fits desired amountB constraints
        if (amountBOptimal <= amountBDesired) {
            require(amountBOptimal >= amountBMin, "INSUFFICIENT_B_AMOUNT");
            return (amountADesired, amountBOptimal);
        }

        // Otherwise calculate optimal amountA based on reserve ratio
        uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
        require(amountAOptimal >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        return (amountAOptimal, amountBDesired);
    }

    /// @notice Removes liquidity from a token pair
    /// @param tokenA Address of token A
    /// @param tokenB Address of token B
    /// @param liquidityAmount Amount of liquidity tokens to withdraw
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

        // Total liquidity in the pool
        uint totalLiquidity = reserveA + reserveB;

        // Ensure user has enough liquidity to withdraw
        require(liquidity[msg.sender][tokenA][tokenB] >= liquidityAmount, "INSUFFICIENT_LIQUIDITY");

        // Calculate proportional token amounts to withdraw
        amountA = (liquidityAmount * reserveA) / totalLiquidity;
        amountB = (liquidityAmount * reserveB) / totalLiquidity;

        // Check slippage limits
        require(amountA >= amountAMin, "INSUFFICIENT_A_AMOUNT");
        require(amountB >= amountBMin, "INSUFFICIENT_B_AMOUNT");

        // Decrease liquidity balance for user
        liquidity[msg.sender][tokenA][tokenB] -= liquidityAmount;

        // Update reserves after withdrawal
        uint256 updatedTokenAReserve = reserveA - amountA;
        uint256 updatedTokenBReserve = reserveB - amountB;

        pairReserve.tokenAReserve = updatedTokenAReserve;
        pairReserve.tokenBReserve = updatedTokenBReserve;

        // Transfer tokens to user
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

        // Transfer tokenIn from sender to contract
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        // Calculate amountOut based on reserves and input
        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        // Update reserves after swap
        uint256 updatedReserveIn = reserveIn + amountIn;
        uint256 updatedReserveOut = reserveOut - amountOut;

        pairReserve.tokenAReserve = updatedReserveIn;
        pairReserve.tokenBReserve = updatedReserveOut;

        // Transfer tokenOut to recipient
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

        uint256 tokenAReserveLocal = pairReserve.tokenAReserve;
        uint256 tokenBReserveLocal = pairReserve.tokenBReserve;

        price = (tokenBReserveLocal * 1e18) / tokenAReserveLocal;
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
