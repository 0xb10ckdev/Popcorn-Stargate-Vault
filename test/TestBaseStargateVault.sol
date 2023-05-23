// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.19;

import "@openzeppelin/IERC20.sol";
import "@openzeppelin/SafeERC20.sol";
import "src/interfaces/IStargateVaultEvents.sol";
import "src/StargateVault.sol";
import "test/utils/TestBase.sol";

contract TestBaseStargateVault is TestBase, IStargateVaultEvents {
    using SafeERC20 for IERC20;

    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address constant USDC_POOL = 0xdf0770dF86a8034b3EFEf0A1Bb3c889B8332FF56;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant USDT_POOL = 0x38EA452219524Bb87e18dE1C24D3bB59510BD783;
    address constant ROUTER = 0x8731d54E9D02c286767d56ac03e8037C07e01e98;
    address constant LP_STAKING = 0xB0D502E938ed5f4df2E681fE6E419ff29631d62b;
    address constant STARGATE = 0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6;

    IERC20 usdc;
    IERC20 stg;
    StargateVault vault;

    function setUp() public virtual {
        vm.createSelectFork(vm.envString("ETH_NODE_URI_MAINNET"), 17316100);

        vault = new StargateVault(
            IERC20(USDC),
            IStargatePool(USDC_POOL),
            IStargateRouter(ROUTER),
            IStargateLPStaking(LP_STAKING),
            0
        );
        usdc = IERC20(USDC);
        stg = IERC20(STARGATE);

        deal(USDC, _USER, 1_000e6);
    }
}
