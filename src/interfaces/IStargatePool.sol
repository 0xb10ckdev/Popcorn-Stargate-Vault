// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/IERC20.sol";

interface IStargatePool is IERC20 {
    function poolId() external view returns (uint256);

    function token() external view returns (address);

    function totalLiquidity() external view returns (uint256);

    function convertRate() external view returns (uint256);

    function deltaCredit() external view returns (uint256);
}
