// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SkillToken is ERC20, Ownable {
    constructor() ERC20("SkillToken", "SKL") Ownable(msg.sender) {
        _mint(msg.sender, 1_000_000 * 1e18); // Initial supply to deployer
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount); // Only SkillSwap contract can mint
    }
}