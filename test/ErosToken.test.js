const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ErosToken", function () {
  let erosToken;
  let owner;
  let addr1, addr2;
  const parseEther = ethers.parseEther;
  const AddressZero = ethers.ZeroAddress || ethers.constants.AddressZero;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    const ErosToken = await ethers.getContractFactory("ErosToken");
    erosToken = await ErosToken.deploy();
  });

  it("debería tener nombre y símbolo correctos", async function () {
    expect(await erosToken.name()).to.equal("Eros token");
    expect(await erosToken.symbol()).to.equal("ERX");
  });

  it("debería asignar el supply inicial al owner", async function () {
    const totalSupply = await erosToken.totalSupply();
    const ownerBalance = await erosToken.balanceOf(owner.address);
    expect(ownerBalance).to.equal(totalSupply);
    expect(totalSupply).to.equal(parseEther("1000000"));
  });

  it("debería permitir al owner mintear tokens", async function () {
    const amount = parseEther("1000");
    await expect(erosToken.mint(addr1.address, amount))
      .to.emit(erosToken, "Transfer")
      .withArgs(AddressZero, addr1.address, amount);

    expect(await erosToken.balanceOf(addr1.address)).to.equal(amount);
  });

  it("debería revertir si un no-owner intenta mintear", async function () {
    const amount = parseEther("1000");
    await expect(
      erosToken.connect(addr1).mint(addr1.address, amount)
    ).to.be.revertedWith("not the owner");
  });

  it("debería permitir transferencias entre cuentas", async function () {
    const amount = parseEther("500");

    await expect(erosToken.transfer(addr1.address, amount))
      .to.emit(erosToken, "Transfer")
      .withArgs(owner.address, addr1.address, amount);

    expect(await erosToken.balanceOf(addr1.address)).to.equal(amount);
  });

  it("debería revertir si se transfiere más de lo que se posee", async function () {
    await expect(
      erosToken.connect(addr1).transfer(owner.address, parseEther("1"))
    ).to.be.reverted;
  });

  it("debería permitir transferencias múltiples y actualizar balances correctamente", async function () {
    const amount = parseEther("1000");

    await erosToken.transfer(addr1.address, amount);
    await erosToken.connect(addr1).transfer(addr2.address, parseEther("300"));

    const balance1 = await erosToken.balanceOf(addr1.address);
    const balance2 = await erosToken.balanceOf(addr2.address);

    expect(balance1).to.equal(parseEther("700"));
    expect(balance2).to.equal(parseEther("300"));
  });
});
