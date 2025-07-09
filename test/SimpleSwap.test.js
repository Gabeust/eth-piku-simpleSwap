const { expect } = require("chai");
const { ethers } = require("hardhat");

/**
 * Test suite for the SimpleSwap contract, testing liquidity management and token swaps.
 */
describe("SimpleSwap", function () {
    let eros, nina, swap;
    let owner, user;
    const parseEther = ethers.parseEther;
    const deadline = () => Math.floor(Date.now() / 1000) + 3600;

    /**
     * Deploys ErosToken, NinaToken and SimpleSwap contracts.
     * Adds initial liquidity to the pool.
     */
    beforeEach(async function () {
        [owner, user] = await ethers.getSigners();

        const ErosToken = await ethers.getContractFactory("ErosToken");
        eros = await ErosToken.deploy();

        const NinaToken = await ethers.getContractFactory("NinaToken");
        nina = await NinaToken.deploy();

        const SimpleSwap = await ethers.getContractFactory("SimpleSwap");
        swap = await SimpleSwap.deploy();

        await eros.approve(swap.target, parseEther("500"));
        await nina.approve(swap.target, parseEther("500"));

        await swap.addLiquidity(
            eros.target,
            nina.target,
            parseEther("500"),
            parseEther("500"),
            parseEther("490"),
            parseEther("490"),
            owner.address,
            deadline()
        );
    });

    /**
     * Checks that liquidity was added correctly by verifying the reserves.
     */
    it("should add liquidity correctly", async function () {
        const reserves = await swap.reserves(eros.target, nina.target);
        expect(reserves.tokenAReserve).to.equal(parseEther("500"));
        expect(reserves.tokenBReserve).to.equal(parseEther("500"));
    });

    /**
     * Removes all liquidity and checks that the pool reserves become zero.
     */
    it("should remove liquidity correctly", async function () {
        const liquidity = await swap.liquidity(owner.address, eros.target, nina.target);
        await swap.removeLiquidity(
            eros.target,
            nina.target,
            liquidity,
            parseEther("1"),
            parseEther("1"),
            owner.address,
            deadline()
        );

        const reserves = await swap.reserves(eros.target, nina.target);
        expect(reserves.tokenAReserve).to.equal(0);
        expect(reserves.tokenBReserve).to.equal(0);
    });

    /**
     * Tests swapping ERX tokens to NINX tokens and checks that user's NINX balance increases.
     */
    it("should perform swap from ERX to NINX", async function () {
        const amountIn = parseEther("10");

        await eros.transfer(user.address, amountIn);
        await eros.connect(user).approve(swap.target, amountIn);

        const balanceAntes = await nina.balanceOf(user.address);

        await swap.connect(user).swapExactTokensForTokens(
            amountIn,
            0,
            [eros.target, nina.target],
            user.address,
            deadline()
        );

        const balanceDespues = await nina.balanceOf(user.address);

        expect(balanceDespues).to.be.gt(balanceAntes);
    });

    /**
     * Fetches current price of ERX token in terms of NINX token and verifies it's positive.
     */
    it("should return current price of ERX in NINX", async function () {
        const price = await swap.getPrice(eros.target, nina.target);
        expect(price).to.be.gt(0);
    });

    /**
     * Verifies getAmountOut returns the expected output amount based on reserves and input amount.
     * Takes into account integer division rounding by allowing a small tolerance.
     */
    it("should calculate correct output amount with getAmountOut", async function () {
        const amountIn = parseEther("10");
        const reserveIn = parseEther("500");
        const reserveOut = parseEther("500");

        const numerator = amountIn * reserveOut;
        const denominator = reserveIn + amountIn;
        const expected = numerator / denominator;

        const amountOut = await swap.getAmountOut(amountIn, reserveIn, reserveOut);

        expect(amountOut).to.be.closeTo(expected, parseEther("0.03"));
    });

    /**
     * Checks that swap reverts when the deadline is expired.
     */
    it("should revert if swap is expired", async function () {
        const amountIn = parseEther("10");
        await eros.transfer(user.address, amountIn);
        await eros.connect(user).approve(swap.target, amountIn);

        await expect(
            swap.connect(user).swapExactTokensForTokens(
                amountIn,
                0,
                [eros.target, nina.target],
                user.address,
                Math.floor(Date.now() / 1000) - 60
            )
        ).to.be.revertedWith("EXPIRED");
    });

    /**
     * Checks that swap reverts if the output amount is less than the minimum specified (slippage protection).
     */
    it("should revert if output amount is less than minimum accepted", async function () {
        const amountIn = parseEther("10");
        await eros.transfer(user.address, amountIn);
        await eros.connect(user).approve(swap.target, amountIn);

        await expect(
            swap.connect(user).swapExactTokensForTokens(
                amountIn,
                parseEther("50"), // very high slippage
                [eros.target, nina.target],
                user.address,
                deadline()
            )
        ).to.be.revertedWith("INSUFFICIENT_OUTPUT_AMOUNT");
    });

    /**
     * Checks that adding liquidity fails if the optimal amount of token B is less than minimum allowed.
     */
    it("should revert if optimal amount B is less than minimum allowed", async function () {
        await expect(
            swap.addLiquidity(
                eros.target,
                nina.target,
                parseEther("100"),
                parseEther("100"),
                parseEther("90"),
                parseEther("200"), // forcing slippage failure
                owner.address,
                deadline()
            )
        ).to.be.revertedWith("INSUFFICIENT_B_AMOUNT");
    });

    /**
     * Checks that getting the price from a pool without liquidity reverts.
     */
    it("should revert when getting price from a pool with no liquidity", async function () {
        await expect(swap.getPrice(nina.target, eros.target)).to.be.revertedWith("NO_LIQUIDITY");
    });
        /**
     * Checks that adding liquidity fails if the optimal amount of token A is less than minimum allowed.
     */
    it("should revert if optimal amount A is less than minimum allowed", async function () {
        // Setup amounts to force the branch where amountAOptimal < amountAMin
        const amountADesired = parseEther("50");
        const amountBDesired = parseEther("10");
        const amountAMin = parseEther("60"); // deliberately higher than optimal
        const amountBMin = parseEther("1");

        await expect(
            swap.addLiquidity(
                eros.target,
                nina.target,
                amountADesired,
                amountBDesired,
                amountAMin,
                amountBMin,
                owner.address,
                deadline()
            )
        ).to.be.revertedWith("INSUFFICIENT_A_AMOUNT");
    });

    /**
     * Checks that swap reverts if output amount is less than amountOutMin.
     */
    it("should revert if output amount is less than amountOutMin in swapExactTokensForTokens", async function () {
        const amountIn = parseEther("10");
        await eros.transfer(user.address, amountIn);
        await eros.connect(user).approve(swap.target, amountIn);

        await expect(
            swap.connect(user).swapExactTokensForTokens(
                amountIn,
                parseEther("1000"), // very high minimum output to force revert
                [eros.target, nina.target],
                user.address,
                deadline()
            )
        ).to.be.revertedWith("INSUFFICIENT_OUTPUT_AMOUNT");
    });

    /**
     * Checks that getAmountOut reverts when amountIn is zero.
     */
    it("should revert if amountIn is zero in getAmountOut", async function () {
        await expect(swap.getAmountOut(0, parseEther("100"), parseEther("100"))).to.be.revertedWith(
            "SimpleSwap: INSUFFICIENT_INPUT_AMOUNT"
        );
    });

    /**
     * Checks that getAmountOut reverts when reserves are zero.
     */
    it("should revert if reserves are zero in getAmountOut", async function () {
        await expect(swap.getAmountOut(parseEther("10"), 0, parseEther("100"))).to.be.revertedWith(
            "SimpleSwap: INSUFFICIENT_LIQUIDITY"
        );
        await expect(swap.getAmountOut(parseEther("10"), parseEther("100"), 0)).to.be.revertedWith(
            "SimpleSwap: INSUFFICIENT_LIQUIDITY"
        );
    });

});
