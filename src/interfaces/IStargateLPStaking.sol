// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/IERC20.sol";

interface IStargateLPStaking {
    struct UserInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 allocPoint;
        uint256 lastRewardBlock;
        uint256 accStargatePerShare;
    }

    function stargate() external view returns (IERC20);

    function userInfo(
        uint256 pid,
        address owner
    ) external view returns (UserInfo memory);

    function poolInfo(uint256 pid) external view returns (PoolInfo memory);

    function deposit(uint256 pid, uint256 amount) external;

    function withdraw(uint256 pid, uint256 amount) external;

    function pendingStargate(
        uint256 pid,
        address user
    ) external view returns (uint256);
}
