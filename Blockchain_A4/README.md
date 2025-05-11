# IDOPool Assignment

**Authors:**
- Zalan Wiqar Shah (21i-0672)
- Umair Khan (21i-2556)
- Zayn Saleem (21i-0389)

This repository implements a decentralized IDO (Initial DEX Offering) pool entirely on-chain, using user-defined ERC‑20 tokens for both sale and payment. It includes:

- **contracts/IDOPool.sol** — single-contract sale logic with soft cap, refund windows, admin-controlled refunds, and unsold-token withdrawal.
- **contracts/MyToken.sol** — simple OpenZeppelin ERC‑20 mock for the sale token.
- **contracts/PaymentToken.sol** — simple OpenZeppelin ERC‑20 mock for the payment token.
- **scripts/deploy.js** — Hardhat deployment script for local and public networks.
- **test/IDOPool.test.js** — Hardhat test suite covering purchase, refunds, finalization, and unsold-token withdrawal.
-- **README.md** — this document, explaining how to install, deploy, and test the contracts.

---

## Prerequisites

- Node.js (v14 or later)
- npm or yarn
- Hardhat (installed via npm)
- MetaMask (for manual testing in Remix or front-end)

---

## Installation

Clone the repository and install dependencies:

```bash
git clone <your-repo-url>
cd <your-repo-dir>
npm install
```

---

## Compilation

Compile all contracts with Hardhat:

```bash
npm run compile
```

Or, in Remix, open the `contracts/` folder and compile each `.sol` file with Solidity v0.8.x.

---

## Deployment

### 1. Local Hardhat Network

Start a local node:

```bash
npx hardhat node
```

In a second terminal, deploy contracts:

```bash
npm run deploy:localhost
```

This runs `scripts/deploy.js` and will:

1. Deploy **PaymentToken** (mints 1 000 PTKN to deployer).
2. Deploy **MyToken** (mints 1 000 000 STKN to deployer).
3. Deploy **IDOPool** with parameters:
   - `saleToken`: MyToken address
   - `paymentToken`: PaymentToken address
   - `rate = 100`
   - `cap = 500 PTKN` (in base units)
   - `softCap = 200 PTKN` (in base units)
   - `startOffset = 0` (sale starts immediately)
   - `endOffset = 600` (sale lasts 600 s)
4. Funds the pool with 500 000 STKN.

Copy the printed addresses for manual testing or front-end.

### 2. Public Testnet (e.g., Goerli)

Configure your API key and deployer key in `hardhat.config.js`, then:

```bash
npm run deploy:goerli
```

---

## Testing

Run the full Hardhat test suite:

```bash
npm test
```

Tests cover:

- Buyer purchase and token issuance.
- User refunds via admin flag and refund window.
- Sale finalization for both success and failure scenarios.
- Unsold-token withdrawal by the owner.
- Admin controls (`setCap`, `setSoftCap`, `startSale`, `endSale`, `setRefundWindow`, `enableGlobalRefund`).

---

## Manual Testing with Remix

1. Open [Remix IDE](https://remix.ethereum.org).
2. Upload the contracts from `contracts/`.
3. Compile with Solidity v0.8.x.
4. In **Deploy & Run** using **JavaScript VM**:
   - Deploy **PaymentToken** with supply `1000 * 10**18`.
   - Deploy **MyToken** with supply `1_000_000 * 10**18`.
   - Deploy **IDOPool** with:
     ```text
     saleToken = MyToken.address
     paymentToken = PaymentToken.address
     rate = 100
     cap = 500 * 10**18
     softCap = 200 * 10**18
     startOffset = 0
     endOffset = 600
     ```
   - Fund the pool: `MyToken.transfer(poolAddress, 500_000 * 10**18)`.
5. Switch accounts to simulate buyer and owner flows:
   - Transfer PTKN to buyer, approve, and call `purchase()`.
   - Test `refund()`, `enableGlobalRefund()`, `setRefundWindow()`, `finalize()`, and `withdrawUnsoldTokens()` by switching accounts and advancing time.


## License

MIT License