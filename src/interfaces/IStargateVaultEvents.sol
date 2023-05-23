// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/IERC20.sol";

interface IStargateVaultEvents {
    /// @notice Emitted when claimReward is called.
    /// @param user Address of user to claim.
    /// @param amount Amount of reward.
    event Claim(address user, uint256 amount);

    /// @notice Emitted when sweep is called.
    /// @param asset Address of asset.
    /// @param amount Amount of asset.
    event Sweep(IERC20 asset, uint256 amount);
}
