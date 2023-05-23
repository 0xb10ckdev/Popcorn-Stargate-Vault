// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/IERC20.sol";

interface IStargateVaultErrors {
    error AssetIsNotTokenForStargatePool(IERC20 asset, IERC20 actual);
    error StakingPoolIdIsNotForPool(IERC20 pool, IERC20 actual);
    error NoRewardForUser(address user);
    error ClaimAmountExceedsAvailable(uint256 amount, uint256 available);
    error CannotSweepPoolAsset();
    error CannotSweepLPToken();
    error CannotSweepStargateToken();
}
