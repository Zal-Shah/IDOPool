const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with account:", deployer.address);

  // 1. Deploy PaymentToken (mock stablecoin)
  const PaymentToken = await ethers.getContractFactory("PaymentToken");
  const payment = await PaymentToken.deploy(ethers.parseUnits("1000", 18));
  await payment.waitForDeployment();
  console.log("PaymentToken deployed to:", payment.target);

  // 2. Deploy MyToken (sale token)
  const MyToken = await ethers.getContractFactory("MyToken");
  const sale = await MyToken.deploy(ethers.parseUnits("1000000", 18));
  await sale.waitForDeployment();
  console.log("MyToken deployed to:", sale.target);

  // 3. Deploy IDOPool
  const IDOPool = await ethers.getContractFactory("IDOPool");
  const rate       = 100;
  const cap        = ethers.parseUnits("500", 18);
  const softCap    = ethers.parseUnits("200", 18);
  const startOffset = 0;    // sale starts immediately
  const endOffset   = 600;  // sale lasts 600 seconds

  const pool = await IDOPool.deploy(
    sale.target,
    payment.target,
    rate,
    cap,
    softCap,
    startOffset,
    endOffset
  );
  await pool.waitForDeployment();
  console.log("IDOPool deployed to:", pool.target);

  // 4. Fund the pool with sale tokens
  const fundAmount = ethers.parseUnits("500000", 18);
  await sale.transfer(pool.target, fundAmount);
  console.log(
    `Funded pool at ${pool.target} with ${fundAmount.toString()} sale tokens`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});