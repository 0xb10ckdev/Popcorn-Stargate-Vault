// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../TestBaseStargateVault.sol";
import {ERC20Mock} from "test/utils/ERC20Mock.sol";

contract SweepTest is TestBaseStargateVault {
    function setUp() public override {
        super.setUp();
    }

    function test_sweep_fail_whenSweepPoolAsset() public {
        vm.expectRevert(IStargateVaultErrors.CannotSweepPoolAsset.selector);
        vault.sweep(usdc, 100e6);
    }

    function test_sweep_fail_whenSweepLPToken() public {
        vm.expectRevert(IStargateVaultErrors.CannotSweepLPToken.selector);
        vault.sweep(IERC20(USDC_POOL), 100e6);
    }

    function test_sweep_fail_whenSweepStargateToken() public {
        vm.expectRevert(IStargateVaultErrors.CannotSweepStargateToken.selector);
        vault.sweep(IERC20(STARGATE), 100e6);
    }

    function test_sweep_success_fuzzed(
        uint256 balance,
        uint256 amount
    ) public virtual {
        vm.assume(balance < type(uint256).max - amount);

        IERC20 erc20 = IERC20(
            address(new ERC20Mock("Token", "TOKEN", 18, balance))
        );
        deal(address(erc20), _USER, amount);

        vm.prank(_USER);
        erc20.transfer(address(vault), amount);

        vm.expectEmit(true, true, true, true, address(vault));
        emit Sweep(erc20, amount);

        vault.sweep(erc20, amount);

        assertEq(erc20.balanceOf(address(this)), balance + amount);
    }
}
