// MyToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/v4.9.3/contracts/token/ERC20/ERC20.sol";
contract MyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("Sale Token", "STKN") {
        _mint(msg.sender, initialSupply);
    }
}