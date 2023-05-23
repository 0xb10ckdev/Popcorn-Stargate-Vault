// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../TestBaseStargateVault.sol";

contract WithdrawTest is TestBaseStargateVault {
    event Withdraw(
        address indexed sender,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    function setUp() public override {
        super.setUp();

        vm.startPrank(_USER);

        usdc.approve(address(vault), 100e6);
        vault.deposit(100e6, _USER);
    }

    function test_withdraw_fail_whenAmountExceedsMaxWithdraw() public {
        vm.startPrank(_USER);

        uint256 maxWithdraw = vault.maxWithdraw(_USER);

        vm.expectRevert("ERC4626: withdraw more than max");
        vault.withdraw(maxWithdraw + 1, _USER, _USER);
    }

    function test_withdraw_fail_whenReceiverIsZeroAddress() public {
        vm.startPrank(_USER);

        vm.expectRevert("ERC20: transfer to the zero address");
        vault.withdraw(10e6, address(0), _USER);
    }

    function test_withdraw_success_fuzzed(uint256 assets) public {
        vm.assume(assets > 1e6 && assets < vault.maxWithdraw(_USER));

        vm.startPrank(_USER);

        uint256 usdcBalance = usdc.balanceOf(_USER);
        uint256 shareBalance = vault.balanceOf(_USER);
        uint256 shares = vault.previewWithdraw(assets);

        vm.expectEmit(true, true, true, true, address(vault));
        emit Withdraw(_USER, _USER, _USER, assets, shares);

        vault.withdraw(assets, _USER, _USER);

        assertEq(shareBalance - shares, vault.balanceOf(_USER));
        assertApproxEqAbs(usdcBalance + assets, usdc.balanceOf(_USER), 10);
        assertApproxEqAbs(100e6 - assets, vault.totalAssets(), 10);
        assertApproxEqAbs(100e6 - assets, vault.maxWithdraw(_USER), 10);
    }
}
