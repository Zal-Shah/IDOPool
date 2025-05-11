const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("IDOPool", function () {
  let PaymentToken, MyToken, IDOPool;
  let payment, sale, pool;
  let owner, buyer, another;

  const RATE    = 100;
  const CAP     = ethers.parseUnits("500", 18);    // 500 PTKN
  const SOFTCAP = ethers.parseUnits("200", 18);    // 200 PTKN
  const START   = 0;
  const END     = 600;

  beforeEach(async () => {
    [owner, buyer, another] = await ethers.getSigners();

    // Deploy mock payment token and sale token
    PaymentToken = await ethers.getContractFactory("PaymentToken");
    payment = await PaymentToken.deploy(ethers.parseUnits("1000", 18));
    await payment.waitForDeployment();

    MyToken = await ethers.getContractFactory("MyToken");
    sale = await MyToken.deploy(ethers.parseUnits("1000000", 18));
    await sale.waitForDeployment();

    // Deploy IDO pool
    IDOPool = await ethers.getContractFactory("IDOPool");
    pool = await IDOPool.deploy(
      sale.target,
      payment.target,
      RATE,
      CAP,
      SOFTCAP,
      START,
      END
    );
    await pool.waitForDeployment();

    // Fund pool with sale tokens (500_000 STKN)
    await sale.transfer(pool.target, ethers.parseUnits("500000", 18));
  });

  it("allows a buyer to purchase tokens and receive saleToken", async () => {
    // seed buyer with payment tokens
    await payment.transfer(buyer.address, ethers.parseUnits("300", 18));
    // approve
    await payment.connect(buyer).approve(pool.target, ethers.parseUnits("100", 18));
    // purchase
    await expect(pool.connect(buyer).purchase(ethers.parseUnits("100", 18)))
      .to.emit(pool, 'Purchased')
      .withArgs(buyer.address, ethers.parseUnits("100", 18), ethers.parseUnits("10000", 18));

    // check contributions and balances
    expect(await pool.contributions(buyer.address)).to.equal(ethers.parseUnits("100", 18));
    expect(await sale.balanceOf(buyer.address)).to.equal(ethers.parseUnits("10000", 18));
  });

  it("allows user refund after admin enables global refund", async () => {
    // buy first
    await payment.transfer(buyer.address, ethers.parseUnits("50", 18));
    await payment.connect(buyer).approve(pool.target, ethers.parseUnits("50", 18));
    await pool.connect(buyer).purchase(ethers.parseUnits("50", 18));

    // owner enables refunds
    await pool.connect(owner).enableGlobalRefund();

    // user refunds
    await expect(pool.connect(buyer).refund())
      .to.emit(pool, 'Refunded')
      .withArgs(buyer.address, ethers.parseUnits("50", 18));

    // contributions reset
    expect(await pool.contributions(buyer.address)).to.equal(0);
  });

  it("allows user refund within a defined refund window", async () => {
    // buy first
    await payment.transfer(buyer.address, ethers.parseUnits("60", 18));
    await payment.connect(buyer).approve(pool.target, ethers.parseUnits("60", 18));
    await pool.connect(buyer).purchase(ethers.parseUnits("60", 18));

    // set refund window to cover current block timestamp
    const now = (await ethers.provider.getBlock()).timestamp;
    await pool.connect(owner).setRefundWindow(now - 10, now + 10);

    // user can refund
    await expect(pool.connect(buyer).refund())
      .to.emit(pool, 'Refunded')
      .withArgs(buyer.address, ethers.parseUnits("60", 18));
  });

  it("finalizes sale and distributes payment tokens to owner when softCap met", async () => {
    // meet soft cap
    await payment.transfer(buyer.address, ethers.parseUnits("200", 18));
    await payment.connect(buyer).approve(pool.target, ethers.parseUnits("200", 18));
    await pool.connect(buyer).purchase(ethers.parseUnits("200", 18));

    // fast-forward time past end
    await ethers.provider.send('evm_increaseTime', [END + 1]);
    await ethers.provider.send('evm_mine');

    // finalize
    await expect(pool.connect(owner).finalize())
      .to.emit(pool, 'SaleFinalized')
      .withArgs(ethers.parseUnits("200", 18));

    // owner receives funds
    expect(await payment.balanceOf(owner.address)).to.equal(ethers.parseUnits("800", 18));
    // (initial 1000 minted - 200 sold = 800)
  });

  it("withdraws unsold sale tokens to owner after successful sale", async () => {
    // meet soft cap by selling 300
    await payment.transfer(buyer.address, ethers.parseUnits("300", 18));
    await payment.connect(buyer).approve(pool.target, ethers.parseUnits("300", 18));
    await pool.connect(buyer).purchase(ethers.parseUnits("300", 18));

    // fast-forward
    await ethers.provider.send('evm_increaseTime', [END + 1]);
    await ethers.provider.send('evm_mine');

    // finalize
    await pool.connect(owner).finalize();

    // withdraw unsold
    const before = await sale.balanceOf(owner.address);
    await expect(pool.connect(owner).withdrawUnsoldTokens())
      .to.emit(pool, 'UnsoldWithdrawn');
    const after = await sale.balanceOf(owner.address);
    expect(after).to.be.gt(before);
  });
});
