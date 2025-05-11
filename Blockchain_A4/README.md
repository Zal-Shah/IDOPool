# IDOPool Assignment

**Authors:**
- Zalan Wiqar Shah (21i-0672)
- Umair Khan (21i-2556)
- Zayn Saleem (21i-0389)

This repository implements a decentralized IDO (Initial DEX Offering) pool entirely on-chain, using user-defined ERC-20 tokens for both sale and payment. It includes:

- **contracts/IDOPool.sol** — single-contract sale logic with soft cap, refund windows, admin-controlled refunds, and unsold-token withdrawal.
- **contracts/MyToken.sol** — simple OpenZeppelin ERC-20 mock for the sale token.
- **contracts/PaymentToken.sol** — simple OpenZeppelin ERC-20 mock for the payment token.
- **scripts/deploy.js** — Hardhat deployment script for local and public networks.
- **test/IDOPool.test.js** — Hardhat test suite covering purchase, refunds, finalization, and unsold-token withdrawal.
- **README.md** — this document, explaining how to install, deploy, and test the contracts.

---

## Prerequisites

- Node.js (v14 or later)
- npm or yarn
- Hardhat (installed via npm)

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

Compile all Solidity contracts with Hardhat:

```bash
npm run compile
```

You can also verify in Remix by opening the `contracts/` folder and compiling each `.sol` file with Solidity v0.8.x.

---

## Deployment

### 1. Local Hardhat Network

Start a local node:

```bash
npx hardhat node
```

In a second terminal, deploy contracts and fund the pool:

```bash
npx hardhat run scripts/deploy.js --network localhost
```

This runs `scripts/deploy.js` and will:

1. Deploy **PaymentToken** (mints 1,000 PTKN to deployer).
2. Deploy **MyToken** (mints 1,000,000 STKN to deployer).
3. Deploy **IDOPool** with parameters:
   - `saleToken`: MyToken address
   - `paymentToken`: PaymentToken address
   - `rate = 100`
   - `cap = 500 PTKN` (in base units)
   - `softCap = 200 PTKN` (in base units)
   - `startOffset = 0` (sale starts immediately)
   - `endOffset = 600` (sale lasts 600 seconds)
4. Funds the pool with 500,000 STKN.

Copy the printed addresses for manual testing.

### 2. Public Testnet (e.g., Goerli)

Configure your RPC URL and deployer private key in `hardhat.config.js`, then:

```bash
npx hardhat run scripts/deploy.js --network goerli
```

---

## Testing

Run the full Hardhat test suite:

```bash
npm test
```

The tests cover:

- Token funding and sale initialization.
- Buyer purchase flow (`purchase`).
- Refund logic (soft-cap conditions, admin/global/window refunds).
- Finalization for both success and failure cases.
- Unsold-token withdrawal.

---

## Manual Testing with Remix

1. Open [Remix IDE](https://remix.ethereum.org).
2. Upload the following contracts:
   - `contracts/PaymentToken.sol`
   - `contracts/MyToken.sol`
   - `contracts/IDOPool.sol`
3. Compile each with Solidity v0.8.x.
4. In **Deploy & Run** (JavaScript VM):
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
5. Simulate buyer actions:
   - Transfer PTKN: `PaymentToken.transfer(buyer, 300 * 10**18)`.
   - Approve & purchase: `PaymentToken.approve(pool, 100 * 10**18)` then `IDOPool.purchase(100 * 10**18)`.
6. Test refunds and finalization:
   - Admin sets refund window or enables global refunds.
   - Advance time and call `finalize()`.
   - Withdraw unsold tokens.

---

## License

MIT License