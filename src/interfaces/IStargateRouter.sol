// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

interface IStargateRouter {
    function addLiquidity(
        uint256 poolId,
        uint256 amountLD,
        address to
    ) external;

    function instantRedeemLocal(
        uint16 srcPoolId,
        uint256 amountLP,
        address to
    ) external returns (uint256);
}
