// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/**
Interface for the WETH9 token contract.
*/
interface IWETH9 {
    function deposit() external payable;
    function withdraw(uint256 _amount) external;
}

contract Weth9 is IWETH9 {
    string public constant name = "Zephyr";
    string public constant symbol = "Z";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    constructor(uint256 initialSupply) {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = initialSupply;
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(amount <= balanceOf[msg.sender], "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        require(spender != address(0), "Approve to zero address");

        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        require(recipient != address(0), "Transfer to zero address");
        require(amount <= balanceOf[sender], "Insufficient balance");
        require(
            amount <= allowance[sender][msg.sender],
            "Insufficient allowance"
        );

        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        allowance[sender][msg.sender] -= amount;

        emit Transfer(sender, recipient, amount);
        return true;
    }

    function deposit() external payable override {
        require(
            msg.value > 0,
            "Deposit amount must be greater than zero"
        );

        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;

        emit Transfer(address(0), msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external override {
        require(amount > 0, "Withdraw amount must be greater than zero");
        require(amount <= balanceOf[msg.sender], "Insufficient balance");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "ETH transfer failed");
    }

    receive() external payable {
        require(
            msg.value > 0,
            "Receive amount must be greater than zero"
        );

        balanceOf[msg.sender] += msg.value;
        totalSupply += msg.value;

        emit Transfer(address(0), msg.sender, msg.value);
    }
}