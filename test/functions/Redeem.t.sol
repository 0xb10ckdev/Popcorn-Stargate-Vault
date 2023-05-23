// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../TestBaseStargateVault.sol";

contract RedeemTest is TestBaseStargateVault {
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

    function test_redeem_fail_whenAmountExceedsMaxWithdraw() public {
        vm.startPrank(_USER);

        uint256 maxRedeem = vault.maxRedeem(_USER);

        vm.expectRevert("ERC4626: redeem more than max");
        vault.redeem(maxRedeem + 1, _USER, _USER);
    }

    function test_redeem_fail_whenReceiverIsZeroAddress() public {
        vm.startPrank(_USER);

        vm.expectRevert("ERC20: transfer to the zero address");
        vault.redeem(10e6, address(0), _USER);
    }

    function test_redeem_success_fuzzed(uint256 shares) public {
        vm.assume(shares > 1e6 && shares < vault.maxRedeem(_USER));

        vm.startPrank(_USER);

        uint256 usdcBalance = usdc.balanceOf(_USER);
        uint256 shareBalance = vault.balanceOf(_USER);
        uint256 assets = vault.previewRedeem(shares);

        vm.expectEmit(true, true, true, true, address(vault));
        emit Withdraw(_USER, _USER, _USER, assets, shares);

        vault.redeem(shares, _USER, _USER);

        assertEq(shareBalance - shares, vault.balanceOf(_USER));
        assertApproxEqAbs(usdcBalance + assets, usdc.balanceOf(_USER), 10);
        assertApproxEqAbs(100e6 - assets, vault.totalAssets(), 10);
        assertApproxEqAbs(100e6 - assets, vault.maxWithdraw(_USER), 10);
    }
}
