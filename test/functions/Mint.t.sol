// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../TestBaseStargateVault.sol";

contract MintTest is TestBaseStargateVault {
    event Deposit(
        address indexed sender,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    function test_mint_fail_whenAssetIsNotApproved() public {
        vm.startPrank(_USER);

        vm.expectRevert("ERC20: transfer amount exceeds allowance");
        vault.mint(100e6, _USER);
    }

    function test_mint_fail_whenReceiverIsZeroAddress() public {
        vm.startPrank(_USER);

        usdc.approve(address(vault), 100e6);

        vm.expectRevert("ERC20: mint to the zero address");
        vault.mint(100e6, address(0));
    }

    function test_mint_success_fuzzed(uint256 shares) public {
        vm.assume(shares <= vault.previewDeposit(usdc.balanceOf(_USER)));

        vm.startPrank(_USER);

        uint256 usdcBalance = usdc.balanceOf(_USER);
        uint256 assets = vault.previewMint(shares);

        usdc.approve(address(vault), shares);

        vm.expectEmit(true, true, true, true, address(vault));
        emit Deposit(_USER, _USER, assets, shares);

        vault.mint(shares, _USER);

        assertEq(usdcBalance - assets, usdc.balanceOf(_USER));
        assertEq(shares, vault.balanceOf(_USER));
        assertApproxEqAbs(shares, vault.totalAssets(), 10);
        assertApproxEqAbs(shares, vault.maxWithdraw(_USER), 10);
    }
}
