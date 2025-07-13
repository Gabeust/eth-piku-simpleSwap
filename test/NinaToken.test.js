const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NinaToken", function () {
  let ninaToken;
  let owner;
  let addr1, addr2;
  const parseEther = ethers.parseEther;
  const AddressZero = ethers.ZeroAddress || ethers.constants.AddressZero;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    const NinaToken = await ethers.getContractFactory("NinaToken");
    ninaToken = await NinaToken.deploy();
  });

  it("debería tener nombre y símbolo correctos", async function () {
    expect(await ninaToken.name()).to.equal("Nina token");
    expect(await ninaToken.symbol()).to.equal("NINX");
  });

  it("debería asignar el supply inicial al owner", async function () {
    const totalSupply = await ninaToken.totalSupply();
    const ownerBalance = await ninaToken.balanceOf(owner.address);
    expect(ownerBalance).to.equal(totalSupply);
    expect(totalSupply).to.equal(parseEther("1000000"));
  });

  it("debería permitir al owner mintear tokens", async function () {
    const amount = parseEther("1000");
    await expect(ninaToken.mint(addr1.address, amount))
      .to.emit(ninaToken, "Transfer")
      .withArgs(AddressZero, addr1.address, amount);

    expect(await ninaToken.balanceOf(addr1.address)).to.equal(amount);
  });

  it("debería revertir si un no-owner intenta mintear", async function () {
    const amount = parseEther("1000");
    await expect(
      ninaToken.connect(addr1).mint(addr1.address, amount)
    ).to.be.revertedWith("not the owner");
  });

  it("debería permitir transferencias entre cuentas", async function () {
    const amount = parseEther("500");

    await expect(ninaToken.transfer(addr1.address, amount))
      .to.emit(ninaToken, "Transfer")
      .withArgs(owner.address, addr1.address, amount);

    expect(await ninaToken.balanceOf(addr1.address)).to.equal(amount);
  });

  it("debería revertir si se transfiere más de lo que se posee", async function () {
    await expect(
      ninaToken.connect(addr1).transfer(owner.address, parseEther("1"))
    ).to.be.reverted;
  });

  it("debería permitir transferencias múltiples y actualizar balances correctamente", async function () {
    const amount = parseEther("1000");

    await ninaToken.transfer(addr1.address, amount);
    await ninaToken.connect(addr1).transfer(addr2.address, parseEther("300"));

    const balance1 = await ninaToken.balanceOf(addr1.address);
    const balance2 = await ninaToken.balanceOf(addr2.address);

    expect(balance1).to.equal(parseEther("700"));
    expect(balance2).to.equal(parseEther("300"));
  });
});
