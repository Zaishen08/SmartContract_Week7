// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Weth9.sol";

contract Weth9Test is Test {
    Weth9 instance;
    uint256 testAmount = 100 ether;
    uint256 amount = 1 ether;
    address testUser;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function setUp() public {
        instance = new Weth9(amount);
        testUser = generateRandomAddress();
        vm.label(testUser, "Zephyr");
        vm.deal(testUser, testAmount);
    }

    function generateRandomAddress() public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(msg.sender, block.timestamp));
        return address(uint160(uint256(hash)));
    }

    /**
     * Test1: deposit 應該將與 msg.value 相等的 ERC20 token mint 給 user
     */
    function testDepositMint() public {
        vm.assume(amount <= 100 * 10 ** 18);
        vm.startPrank(testUser);
        instance.deposit{value: amount}();
        assertEq(instance.balanceOf(testUser), amount);
        vm.stopPrank();
    }

    /**
     * Test2: deposit 應該將 msg.value 的 ether 轉入合約
     */
    function testDepositEther() public {
        vm.prank(testUser);
        uint256 balanceBefore = address(instance).balance;

        instance.deposit{value: amount}();
        uint256 balanceAfter = address(instance).balance;

        assertEq(balanceBefore + amount, balanceAfter);
    }

    /**
     * Test3: deposit 應該要 emit Deposit event
     */
    function testDepositEvent() public {
        vm.startPrank(testUser);

        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), testUser, amount);
        instance.deposit{value: amount}();

        vm.stopPrank();
    }

    /**
     * Test4: withdraw 應該要 burn 掉與 input parameters 一樣的 erc20 token
     */
    function testWithdrawBurnErc20Token() public {
        vm.startPrank(testUser);

        instance.deposit{value: amount}();
        assertEq(instance.balanceOf(testUser), amount);
        instance.withdraw(amount);
        assertEq(instance.balanceOf(testUser), 0);

        vm.stopPrank();
    }

    /**
     * Test5: withdraw 應該將 burn 掉的 erc20 換成 ether 轉給 user
     */
    function testWithdrawChangeBurnEther() public {
        vm.startPrank(testUser);

        instance.deposit{value: amount}();
        uint256 balanceBefore = address(testUser).balance;
        instance.withdraw(amount);
        uint256 balanceAfter = address(testUser).balance;
        assertEq(balanceBefore + amount, balanceAfter);

        vm.stopPrank();
    }

    /**
     * Test6: withdraw 應該要 emit Withdraw event
     */
    function testEmitWithdrawEvent() public {
        vm.startPrank(testUser);

        instance.deposit{value: amount}();
        vm.expectEmit(true, true, false, true);
        emit Transfer(testUser,address(0), amount);
        instance.withdraw(amount);

        vm.stopPrank();
    }

    /**
     * Test7: transfer 應該要將 erc20 token 轉給別人
     */
    function testTransferErc20() public {
        vm.startPrank(testUser);

        address Bob = address(1);
        instance.deposit{value: amount}();
        instance.transfer(Bob, amount);

        assertEq(instance.balanceOf(testUser), 0);
        assertEq(instance.balanceOf(Bob), amount);

        vm.stopPrank();
    }

    /**
     * Test8: approve 應該要給他人 allowance
     */
    function testApproveWithAllowance() public {
        vm.startPrank(testUser);

        address Bob = generateRandomAddress();
        instance.approve(Bob, amount);
        assertEq(instance.allowance(testUser, Bob), amount);

        vm.stopPrank();
    }

    /**
     * Test9: transferFrom 應該要可以使用他人的 allowance
     */
    function testTransferFromWithAllowance() public {
        address sender = generateRandomAddress();
        address receiver = generateRandomAddress();

        vm.startPrank(testUser);

        instance.deposit{value: amount}();
        instance.approve(sender, amount);

        assertEq(instance.allowance(testUser, sender), amount);

        vm.stopPrank();
        vm.prank(sender);
        instance.transferFrom(testUser, receiver, amount);
        assertEq(instance.allowance(testUser, sender), 0);
    }

    /**
     * test10: transferFrom 後應該要減除用完的 allowance
     */
    function testTransferFromAfterAllowance() public {
        address sender = generateRandomAddress();
        address receiver = address(1);

        vm.startPrank(testUser);
        instance.deposit{value: amount}();
        instance.approve(sender, amount);
        vm.stopPrank();

        vm.prank(sender);
        instance.transferFrom(testUser, receiver, amount);
        assertEq(instance.balanceOf(testUser), 0);
        assertEq(instance.balanceOf(receiver), amount);
        assertEq(instance.allowance(testUser, sender), 0);
    }
}