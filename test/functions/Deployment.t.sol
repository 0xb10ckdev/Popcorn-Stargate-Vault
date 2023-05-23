// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../TestBaseStargateVault.sol";

contract DeploymentTest is TestBaseStargateVault {
    function test_deployment_fail_whenAssetIsNotTokenForStargatePool() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IStargateVaultErrors.AssetIsNotTokenForStargatePool.selector,
                USDT,
                USDC
            )
        );
        new StargateVault(
            IERC20(USDT),
            IStargatePool(USDC_POOL),
            IStargateRouter(ROUTER),
            IStargateLPStaking(LP_STAKING),
            0
        );
    }

    function test_deployment_fail_whenStakingPoolIdIsNotForPool() public {
        vm.expectRevert(
            abi.encodeWithSelector(
                IStargateVaultErrors.StakingPoolIdIsNotForPool.selector,
                USDC_POOL,
                USDT_POOL
            )
        );
        new StargateVault(
            IERC20(USDC),
            IStargatePool(USDC_POOL),
            IStargateRouter(ROUTER),
            IStargateLPStaking(LP_STAKING),
            1
        );
    }

    function test_deployment_success() public {
        vault = new StargateVault(
            IERC20(USDC),
            IStargatePool(USDC_POOL),
            IStargateRouter(ROUTER),
            IStargateLPStaking(LP_STAKING),
            0
        );

        assertEq(vault.decimals(), 6);
        assertEq(vault.name(), "Popcorn Stargate Vault USDC");
        assertEq(vault.symbol(), "pstgUSDC");

        assertEq(address(vault.stargateRouter()), ROUTER);
        assertEq(address(vault.stargatePool()), USDC_POOL);
        assertEq(address(vault.stargateLPStaking()), LP_STAKING);
        assertEq(vault.stargatePoolId(), 1);
        assertEq(vault.stakingPoolId(), 0);
    }
}
