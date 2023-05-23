// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../TestBaseStargateVault.sol";
import "forge-std/StdStorage.sol";

contract ClaimTest is TestBaseStargateVault {
    using stdStorage for StdStorage;

    function setUp() public override {
        super.setUp();

        vm.startPrank(_USER);

        usdc.approve(address(vault), 100e6);
        vault.deposit(100e6, _USER);
    }

    function test_claim_fail_whenNoRewardForUser() public {
        vm.startPrank(_USER);

        vm.expectRevert(
            abi.encodeWithSelector(
                IStargateVaultErrors.NoRewardForUser.selector,
                _USER
            )
        );
        vault.claimReward(1e6);
    }

    function test_claim_fail_whenClaimAmountExceedsAvailable() public {
        vm.startPrank(_USER);

        IStargateLPStaking.PoolInfo memory poolInfo = IStargateLPStaking(
            LP_STAKING
        ).poolInfo(vault.stakingPoolId());

        stdstore
            .target(LP_STAKING)
            .sig("poolInfo(uint256)")
            .with_key(uint256(0))
            .depth(3)
            .checked_write(poolInfo.accStargatePerShare + 1_000e18);

        uint256 pendingReward = vault.pendingReward(_USER);

        vault.withdraw(vault.maxWithdraw(_USER), _USER, _USER);

        vm.expectRevert(
            abi.encodeWithSelector(
                IStargateVaultErrors.ClaimAmountExceedsAvailable.selector,
                pendingReward + 1,
                pendingReward
            )
        );
        vault.claimReward(pendingReward + 1);
    }

    function test_claim_success_fuzzed(uint256 assets) public {
        vm.assume(assets > 1e6 && assets < vault.maxWithdraw(_USER));

        vm.startPrank(_USER);

        IStargateLPStaking.PoolInfo memory poolInfo = IStargateLPStaking(
            LP_STAKING
        ).poolInfo(vault.stakingPoolId());

        stdstore
            .target(LP_STAKING)
            .sig("poolInfo(uint256)")
            .with_key(uint256(0))
            .depth(3)
            .checked_write(poolInfo.accStargatePerShare + 1_000e18);

        uint256 pendingReward = vault.pendingReward(_USER);
        uint256 totalPendingReward = vault.totalPendingReward();

        assertEq(pendingReward, totalPendingReward);

        vault.withdraw(assets, _USER, _USER);

        uint256 availableReward = vault.availableReward(_USER);
        uint256 totalAvailableReward = vault.totalAvailableReward();

        assertEq(availableReward, totalAvailableReward);
        assertEq(
            totalPendingReward - totalAvailableReward,
            vault.totalPendingReward()
        );
        assertEq(totalAvailableReward, stg.balanceOf(address(vault)));

        uint256 stgBalance = stg.balanceOf(_USER);

        vm.expectEmit(true, true, true, true, address(vault));
        emit Claim(_USER, availableReward);

        vault.claimReward(availableReward);

        assertEq(0, vault.availableReward(_USER));
        assertEq(stgBalance + availableReward, stg.balanceOf(_USER));
    }
}
