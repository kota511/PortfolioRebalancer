// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract GoldToken is ERC20, ERC20Permit {
    constructor() ERC20("GoldToken", "GLD") ERC20Permit("GoldToken") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

contract SilverToken is ERC20, ERC20Permit {
    constructor() ERC20("SilverToken", "SLV") ERC20Permit("SilverToken") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}

contract PortfolioRebalancer {
    IERC20 public tokenA;
    IERC20 public tokenB;

    event Rebalanced(uint tokenABalance, uint tokenBBalance, uint halfValue);
    event Deposited(uint amountA, uint amountB);
    event Withdrawn(uint amountA, uint amountB);

    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        owner = msg.sender;
    }
    
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the balancer owner");
        _;
    }

    function getBalances() public view returns (uint, uint) {
        uint tokenAbalance = tokenA.balanceOf(address(this));
        uint tokenBbalance = tokenB.balanceOf(address(this));
        return (tokenAbalance, tokenBbalance);
    }

    function rebalance() public onlyOwner {
        (uint aBalance, uint bBalance) = getBalances();
        uint average = (aBalance+bBalance)/2;
        if (aBalance>average){
            uint excess = aBalance - average;
            require(tokenA.approve(address(this),excess), "Approval for tokenA failed.");
            tokenA.transfer(owner, excess);
            require(tokenB.transferFrom(msg.sender, address(this), average-bBalance), "Transfer for tokenB failed.");
        }
        else if (bBalance>average){
            uint excess = bBalance - average;
            require(tokenB.approve(address(this),excess), "Approval for tokenB failed.");
            tokenB.transfer(owner, excess);
            require(tokenA.transferFrom(msg.sender, address(this), average-aBalance), "Transfer for tokenA failed.");
        }
        emit Rebalanced(aBalance, bBalance, average);
    }

    function deposit(uint amountA, uint amountB) public onlyOwner {
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);
        emit Deposited(amountA, amountB);
    }

    function withdraw(uint amountA, uint amountB) public onlyOwner {
        tokenA.transfer(owner, amountA);
        tokenB.transfer(owner, amountB);
    }
}