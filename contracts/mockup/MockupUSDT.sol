// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockupUSDT is ERC20 {

    constructor () ERC20("MockUSDT", "USDT") {
        
    }

    function mint(address account, uint256 amount) external {
        require(account != address(0), "not a valid address for minting");
        _mint(account, amount);
    }
}
