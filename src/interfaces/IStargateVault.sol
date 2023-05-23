// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "./IStargateLPStaking.sol";
import "./IStargateRouter.sol";
import "./IStargatePool.sol";
import "./IStargateVaultErrors.sol";
import "./IStargateVaultEvents.sol";

interface IStargateVault is IStargateVaultErrors, IStargateVaultEvents {
    /// @notice The address of Stargate Router.
    function stargateRouter() external view returns (IStargateRouter);

    /// @notice The address of Stargate Pool.
    function stargatePool() external view returns (IStargatePool);

    /// @notice The address of Stargate LPStaking.
    function stargateLPStaking() external view returns (IStargateLPStaking);

    /// @notice The id of Stargate Pool.
    function stargatePoolId() external view returns (uint256);

    /// @notice The id of Stargate staking pool.
    function stakingPoolId() external view returns (uint256);

    /// @notice Return the total amount of pending rewards.
    function totalPendingReward() external view returns (uint256);

    /// @notice Return the amount of pending reward for user.
    /// @param user The address of user.
    function pendingReward(address user) external view returns (uint256);

    /// @notice Return the amount of available reward to claim.
    function totalAvailableReward() external view returns (uint256);

    /// @notice Return the amount of available reward to claim for user.
    /// @param user Address of user.
    function availableReward(address user) external view returns (uint256);

    /// @notice Claim current available reward.
    /// @param amount Amount of reward to claim.
    function claimReward(uint256 amount) external;

    /// @notice Return an asset to the owner.
    /// @param token Address of token.
    /// @param amount Amount of token.
    function sweep(IERC20 token, uint256 amount) external;
}
