// IDOPool.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title IDOPool
 * @notice A single-contract IDO pool that sells an existing ERC-20 sale token
 *         in exchange for a user-defined ERC-20 payment token.
 *         Supports soft cap, refund windows, admin-triggered global refunds, and owner controls.
 */
contract IDOPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    // --- Sale parameters ---
    IERC20  public saleToken;      // token being sold
    IERC20  public paymentToken;   // token used to pay
    uint256 public rate;           // number of saleToken per 1 paymentToken
    uint256 public cap;            // max paymentToken to raise
    uint256 public softCap;        // minimum to consider sale successful
    uint256 public start;          // sale start timestamp
    uint256 public end;            // sale end timestamp

    // --- Refund controls ---
    uint256 public refundStart;    // refund window start
    uint256 public refundEnd;      // refund window end
    bool    public refundEnabled;  // admin-triggered global refund flag

    // --- State tracking ---
    bool    public finalized;      // whether sale has been finalized
    uint256 public raised;         // total paymentToken collected
    mapping(address => uint256) public contributions;

    // --- Events ---
    event Purchased(address indexed buyer, uint256 paid, uint256 tokensIssued);
    event Refunded(address indexed buyer, uint256 amount);
    event SaleFinalized(uint256 totalRaised);
    event RefundsEnabled();
    event RefundWindowUpdated(uint256 start, uint256 end);
    event UnsoldWithdrawn(address indexed owner, uint256 amount);

    /**
     * @param _saleToken      Address of the ERC-20 token to sell
     * @param _paymentToken   Address of the ERC-20 token used for payment
     * @param _rate           Units of saleToken per 1 paymentToken
     * @param _cap            Maximum paymentToken to raise
     * @param _softCap        Minimum paymentToken required for a successful sale
     * @param _startOffset    Offset in seconds from now when sale starts
     * @param _endOffset      Offset in seconds from now when sale ends
     */
    constructor(
        address _saleToken,
        address _paymentToken,
        uint256 _rate,
        uint256 _cap,
        uint256 _softCap,
        uint256 _startOffset,
        uint256 _endOffset
    ) Ownable(msg.sender) {
        require(_saleToken != address(0), "saleToken is zero address");
        require(_paymentToken != address(0), "paymentToken is zero address");
        require(_rate > 0, "rate must be > 0");
        require(_cap > 0, "cap must be > 0");
        require(_softCap <= _cap, "softCap must be <= cap");
        require(_endOffset > _startOffset, "end must be after start");

        saleToken    = IERC20(_saleToken);
        paymentToken = IERC20(_paymentToken);
        rate         = _rate;
        cap          = _cap;
        softCap      = _softCap;
        start        = block.timestamp + _startOffset;
        end          = block.timestamp + _endOffset;
    }

    // --- Modifiers ---
    modifier onlyDuringSale() {
        require(block.timestamp >= start && block.timestamp <= end, "sale is not active");
        _;
    }

    modifier onlyAfterSale() {
        require(block.timestamp > end, "sale not ended");
        _;
    }

    /**
     * @notice Purchase sale tokens by transferring `amount` of payment tokens
     * @param amount  PaymentToken units to spend
     */
    function purchase(uint256 amount) external nonReentrant onlyDuringSale {
        require(raised + amount <= cap, "cap exceeded");

        paymentToken.safeTransferFrom(msg.sender, address(this), amount);
        contributions[msg.sender] += amount;
        raised += amount;

        uint256 tokensOut = amount * rate;
        saleToken.safeTransfer(msg.sender, tokensOut);

        emit Purchased(msg.sender, amount, tokensOut);
    }

    /**
     * @notice Refund a contributor if sale failed, within refund window, or after global refund enabled
     */
    function refund() external nonReentrant {
        uint256 paid = contributions[msg.sender];
        require(paid > 0, "no contribution to refund");

        bool saleFailed = (block.timestamp > end && raised < softCap);
        bool inWindow   = (block.timestamp >= refundStart && block.timestamp <= refundEnd);
        require(saleFailed || inWindow || refundEnabled, "refund not allowed");

        contributions[msg.sender] = 0;
        raised -= paid;
        paymentToken.safeTransfer(msg.sender, paid);
        emit Refunded(msg.sender, paid);
    }

    /**
     * @notice Finalize sale: if softCap met, transfer funds to owner; otherwise enable refunds
     */
    function finalize() external onlyOwner nonReentrant onlyAfterSale {
        require(!finalized, "already finalized");
        finalized = true;

        if (raised < softCap) {
            refundEnabled = true;
            emit RefundsEnabled();
        } else {
            uint256 balance = paymentToken.balanceOf(address(this));
            emit SaleFinalized(balance);
        }
    }

    /**
     * @notice Withdraw unsold sale tokens after a successful sale finalization
     */
    function withdrawUnsoldTokens() external onlyOwner nonReentrant {
        require(finalized, "sale not finalized");
        require(raised >= softCap, "sale did not meet softCap");

        uint256 unsold = saleToken.balanceOf(address(this));
        saleToken.safeTransfer(owner(), unsold);
        emit UnsoldWithdrawn(owner(), unsold);
    }

    // --- Admin Controls ---

    /// @notice Enable refunds for everyone immediately
    function enableGlobalRefund() external onlyOwner {
        refundEnabled = true;
        emit RefundsEnabled();
    }

    /// @notice Set a time window during which refunds are allowed
    function setRefundWindow(uint256 _start, uint256 _end) external onlyOwner {
        require(_end > _start, "invalid refund window");
        refundStart = _start;
        refundEnd   = _end;
        emit RefundWindowUpdated(_start, _end);
    }

    /// @notice Adjust the hard cap before sale starts
    function setCap(uint256 _cap) external onlyOwner {
        require(block.timestamp < start, "sale already started");
        require(_cap >= softCap,        "cap < softCap");
        cap = _cap;
    }

    /// @notice Adjust the soft cap before sale starts
    function setSoftCap(uint256 _softCap) external onlyOwner {
        require(block.timestamp < start, "sale already started");
        require(_softCap <= cap,         "softCap > cap");
        softCap = _softCap;
    }

    /// @notice Start the sale immediately (override scheduled start)
    function startSale() external onlyOwner {
        require(block.timestamp < end, "sale already ended");
        start = block.timestamp;
    }

    /// @notice End the sale immediately (override scheduled end)
    function endSale() external onlyOwner {
        require(block.timestamp > start, "sale not started");
        end = block.timestamp;
    }
}