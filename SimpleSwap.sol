// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SimpleSwap - Intercambio básico de tokens con liquidez
/// @author Gabriel
contract SimpleSwap {
    struct Reserve {
        uint256 tokenAReserve;
        uint256 tokenBReserve;
    }

    mapping(address => mapping(address => Reserve)) public reserves;
    mapping(address => mapping(address => mapping(address => uint256))) public liquidity;

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

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address tokenIn,
        address tokenOut,
        address to,
        uint deadline
    ) external returns (uint amountOut) {
        require(block.timestamp <= deadline, "EXPIRED");

        Reserve storage reserve = reserves[tokenIn][tokenOut];

        (uint reserveIn, uint reserveOut) = (reserve.tokenAReserve, reserve.tokenBReserve);

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        amountOut = (amountIn * reserveOut) / (reserveIn + amountIn);
        require(amountOut >= amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        reserve.tokenAReserve += amountIn;
        reserve.tokenBReserve -= amountOut;

        IERC20(tokenOut).transfer(to, amountOut);
    }

    function getPrice(address tokenA, address tokenB) external view returns (uint price) {
        Reserve storage reserve = reserves[tokenA][tokenB];
        require(reserve.tokenAReserve > 0, "NO_LIQUIDITY");

        price = (reserve.tokenBReserve * 1e18) / reserve.tokenAReserve;
    }
}
