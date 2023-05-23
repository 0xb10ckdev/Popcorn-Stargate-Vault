// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../TestBaseStargateVault.sol";

contract DepositTest is TestBaseStargateVault {
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    function test_deposit_fail_whenAssetIsNotApproved() public {
        vm.startPrank(_USER);

        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        vault.deposit(100e6, _USER);
    }

    function test_deposit_fail_whenReceiverIsZeroAddress() public {
        vm.startPrank(_USER);

        usdc.approve(address(vault), 100e6);

        vm.expectRevert("ERC20: mint to the zero address");
        vault.deposit(100e6, address(0));
    }

    function test_deposit_success_fuzzed(uint256 assets) public {
        vm.assume(assets <= usdc.balanceOf(_USER));

        vm.startPrank(_USER);

        uint256 usdcBalance = usdc.balanceOf(_USER);
        uint256 shares = vault.previewDeposit(assets);

        usdc.approve(address(vault), assets);

        vm.expectEmit(true, true, true, true, address(vault));
        emit Deposit(_USER, _USER, assets, shares);

        vault.deposit(assets, _USER);

        assertEq(usdcBalance - assets, usdc.balanceOf(_USER));
        assertEq(shares, vault.balanceOf(_USER));
        assertApproxEqAbs(assets, vault.totalAssets(), 10);
        assertApproxEqAbs(assets, vault.maxWithdraw(_USER), 10);
    }
}
