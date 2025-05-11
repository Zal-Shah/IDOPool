# IDOPool Project

This repository implements a decentralized IDO (Initial DEX Offering) pool entirely on-chain, using user-defined ERC‑20 tokens for both sale and payment. It provides:

- **IDOPool.sol** — single-contract sale logic with soft cap, refund windows, admin-controlled refunds, and unsold-token withdrawal.
- **MyToken.sol**, **PaymentToken.sol** — simple OpenZeppelin ERC‑20 mocks for sale and payment tokens.
- **scripts/deploy.js** — a Hardhat deployment script for local and public test networks.
- **test/IDOPool.test.js** — a Hardhat test suite covering all major flows (purchase, refund, finalize, withdraw).
- **README.md** — this document, explaining how to deploy and test the contract.
- **(Optional)** **src/** — a minimal React front-end for interacting with the deployed pool.

---

## Prerequisites

- **Node.js** (v14 or later)
- **npm** or **yarn**
- **Hardhat** (installed via npm)
- **MetaMask** (for manual Remix testing or front-end)

---

## Installation

Clone and install dependencies:

```bash
git clone <your-repo-url>
cd <your-repo-dir>
npm install
```

---

## Compilation

Compile all Solidity contracts with Hardhat:

```bash
npx hardhat compile
```

You can also verify the contracts in Remix by opening `contracts/` and compiling with Solidity v0.8.x.

---

## Deployment

### 1. Local Hardhat Network

Start a local node:

```bash
npx hardhat node
```

In a separate terminal, deploy contracts:

```bash
npx hardhat run scripts/deploy.js --network localhost
```

The script will:

1. Deploy **PaymentToken** (mock stablecoin).
2. Deploy **MyToken** (sale token).
3. Deploy **IDOPool** with constructor arguments:
   - `saleToken.address`
   - `paymentToken.address`
   - `rate = 100`
   - `cap = 500` PTKN (in base units)
   - `softCap = 200` PTKN (in base units)
   - `start = 0` (timestamp)
   - `end = 600` (timestamp)
4. Fund the pool with 500 000 STKN.

Copy the deployed addresses printed in the console for manual testing or front-end integration.

### 2. Public Testnet (e.g., Goerli)

Configure your `hardhat.config.js` with an RPC URL and deployer private key. Then:

```bash
npx hardhat run scripts/deploy.js --network goerli
```

---

## Testing

Run the Hardhat test suite:

```bash
npx hardhat test
```

The tests cover:

- Token funding and sale initialization.
- Buyer purchase flow (`purchase`).
- Refund logic (pre- and post-sale, soft-cap conditions, admin overrides).
- Sale finalization for both success (soft cap met) and failure cases.
- Unsold-token withdrawal by the owner.
- Admin functions: changing caps, refund windows, immediate start/end.

---

## Manual Testing with Remix

1. Visit [Remix IDE](https://remix.ethereum.org).
2. Create a workspace and upload:
   - `contracts/PaymentToken.sol`
   - `contracts/MyToken.sol`
   - `contracts/IDOPool.sol`
3. Compile each contract under **Solidity Compiler** (version 0.8.x).
4. In **Deploy & Run**:
   - **Environment** → **JavaScript VM (Prague)**
   - Deploy **PaymentToken** with initial supply (e.g., `1000 * 10**18`).
   - Deploy **MyToken** with initial supply (e.g., `1_000_000 * 10**18`).
   - Deploy **IDOPool** with:
     ```text
     saleToken = MyToken.address
     paymentToken = PaymentToken.address
     rate = 100
     cap = 500 * 10**18
     softCap = 200 * 10**18
     start = 0
     end = 600
     ``` 
   - Fund the pool: **MyToken.transfer(poolAddress, 500_000*10**18)**.
5. Switch **Account** to **Account 1** for buyer actions:
   - **PaymentToken.transfer(buyer, 300*10**18)** (from Account 0)
   - **PaymentToken.approve(poolAddress, 100*10**18)** (as buyer)
   - **IDOPool.purchase(100*10**18)**
   - Test **refund()**, **enableGlobalRefund()**, **setRefundWindow()**, **finalize()**, **withdrawUnsoldTokens()** by switching accounts and advancing time in the VM.

---

## (Optional) Front-End Interface

A simple React app in `src/` demonstrates connecting with MetaMask, calling `purchase`, `refund`, and `finalize`. To run:

```bash
cd src
npm install
npm start
```

Configure the contract address in `App.jsx` and ensure MetaMask is pointed at the same network.

---

## License

MIT License