// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

import "@openzeppelin/ERC4626.sol";
import "@openzeppelin/IERC20Metadata.sol";
import "@openzeppelin/Ownable.sol";
import "@openzeppelin/SafeERC20.sol";
import "./interfaces/IStargateLPStaking.sol";
import "./interfaces/IStargatePool.sol";
import "./interfaces/IStargateRouter.sol";
import "./interfaces/IStargateVault.sol";

/// @title Stargate Vault contract.
contract StargateVault is IStargateVault, ERC4626, Ownable {
    using SafeERC20 for IERC20;

    /// @notice The address of Stargate Router.
    IStargateRouter public immutable stargateRouter;

    /// @notice The address of Stargate Pool.
    IStargatePool public immutable stargatePool;

    /// @notice The address of Stargate LPStaking.
    IStargateLPStaking public immutable stargateLPStaking;

    /// @notice The address of Stargate token.
    IERC20 public immutable stargate;

    /// @notice The Id of Stargate Pool.
    uint256 public immutable stargatePoolId;

    /// @notice The Id of Stargate staking pool.
    uint256 public immutable stakingPoolId;

    /// STORAGE ///

    uint256 _totalAvailableReward;
    mapping(address => uint256) private _availableRewards;

    /// FUNCTIONS ///

    constructor(
        IERC20 asset_,
        IStargatePool stargatePool_,
        IStargateRouter stargateRouter_,
        IStargateLPStaking stargateLPStaking_,
        uint256 stakingPoolId_
    ) ERC4626(asset_) ERC20(_getVaultName(asset_), _getVaultSymbol(asset_)) {
        IERC20 poolToken = IERC20(stargatePool_.token());

        if (asset_ != poolToken) {
            revert AssetIsNotTokenForStargatePool(asset_, poolToken);
        }

        IERC20 lpToken = stargateLPStaking_.poolInfo(stakingPoolId_).lpToken;

        if (stargatePool_ != lpToken) {
            revert StakingPoolIdIsNotForPool(stargatePool_, lpToken);
        }

        stargatePool = stargatePool_;
        stargateRouter = stargateRouter_;
        stargateLPStaking = stargateLPStaking_;
        stakingPoolId = stakingPoolId_;
        stargatePoolId = stargatePool_.poolId();
        stargate = stargateLPStaking_.stargate();
    }

    /// @inheritdoc IStargateVault
    function claimReward(uint256 amount) external {
        uint256 userReward = _availableRewards[msg.sender];

        if (userReward == 0) {
            revert NoRewardForUser(msg.sender);
        }
        if (amount > userReward) {
            revert ClaimAmountExceedsAvailable(amount, userReward);
        }

        userReward -= amount;

        _totalAvailableReward -= amount;
        _availableRewards[msg.sender] = userReward;

        stargate.safeTransfer(msg.sender, amount);

        emit Claim(msg.sender, amount);
    }

    /// @inheritdoc IStargateVault
    function sweep(IERC20 token, uint256 amount) external virtual override {
        if (address(token) == asset()) {
            revert CannotSweepPoolAsset();
        }
        if (address(token) == address(stargatePool)) {
            revert CannotSweepLPToken();
        }
        if (token == stargate) {
            revert CannotSweepStargateToken();
        }

        token.safeTransfer(owner(), amount);

        emit Sweep(token, amount);
    }

    /// @inheritdoc IStargateVault
    function totalPendingReward() external view override returns (uint256) {
        return _totalPendingReward();
    }

    /// @inheritdoc IStargateVault
    function pendingReward(
        address user
    ) external view override returns (uint256) {
        return (_totalPendingReward() * maxRedeem(user)) / totalSupply();
    }

    /// @inheritdoc IStargateVault
    function totalAvailableReward() external view override returns (uint256) {
        return _totalAvailableReward;
    }

    /// @inheritdoc IStargateVault
    function availableReward(
        address user
    ) external view override returns (uint256) {
        return _availableRewards[user];
    }

    /// @inheritdoc IERC4626
    function maxWithdraw(address owner) public view override returns (uint256) {
        uint256 cash = totalAssets();

        uint256 assetBalance = convertToAssets(this.balanceOf(owner));

        return cash < assetBalance ? cash : assetBalance;
    }

    /// @inheritdoc IERC4626
    function maxRedeem(address owner) public view override returns (uint256) {
        uint256 cashInShares = convertToShares(totalAssets());

        uint256 shareBalance = this.balanceOf(owner);

        return cashInShares < shareBalance ? cashInShares : shareBalance;
    }

    /// @inheritdoc IERC4626
    function totalAssets() public view override returns (uint256 amountLD) {
        IStargateLPStaking.UserInfo memory userInfo = stargateLPStaking
            .userInfo(stakingPoolId, address(this));

        amountLD = _getAmountLD(userInfo.amount);
    }

    /// INTERNAL FUNCTIONS ///

    /// @notice Deposit assets.
    /// @dev After deposit assets, it adds liquidity to Stargate Pool.
    ///      Then, it deposit Stargate Pool Token to Stargate LP Staking.
    /// @param caller Address of caller to deposit assets.
    /// @param receiver Address of receiver to receive shares.
    /// @param assets Amount of asset to deposit.
    /// @param shares Amount of shares to mint.
    function _deposit(
        address caller,
        address receiver,
        uint256 assets,
        uint256 shares
    ) internal virtual override {
        SafeERC20.safeTransferFrom(
            IERC20(asset()),
            caller,
            address(this),
            assets
        );
        _mint(receiver, shares);

        _setAllowance(IERC20(asset()), address(stargateRouter), assets);

        stargateRouter.addLiquidity(stargatePoolId, assets, address(this));

        uint256 poolTokenBalance = stargatePool.balanceOf(address(this));

        _setAllowance(
            IERC20(address(stargatePool)),
            address(stargateLPStaking),
            poolTokenBalance
        );

        uint256 stgBalance = stargate.balanceOf(address(this));

        stargateLPStaking.deposit(stakingPoolId, poolTokenBalance);

        uint256 stgAmount = stargate.balanceOf(address(this)) - stgBalance;

        _totalAvailableReward += stgAmount;
        _availableRewards[caller] += stgAmount;

        emit Deposit(caller, receiver, assets, shares);
    }

    /// @notice Withdraw assets.
    /// @dev Before withdraw assets, it withdraw Stargate Pool Token
    ///      from Stargate LP Staking.
    ///      Then, it removes liquidity from Stargate Pool.
    /// @param caller Address of caller to withdraw assets.
    /// @param receiver Address of receiver to receive assets.
    /// @param owner Address of user owns shares.
    /// @param assets Amount of asset to withdraw.
    /// @param shares Amount of shares to burn.
    function _withdraw(
        address caller,
        address receiver,
        address owner,
        uint256 assets,
        uint256 shares
    ) internal override {
        if (caller != owner) {
            _spendAllowance(owner, caller, shares);
        }

        uint256 amountLP = _getAmountLP(assets);

        uint256 assetBalance = IERC20(asset()).balanceOf(address(this));
        uint256 stgBalance = stargate.balanceOf(address(this));

        stargateLPStaking.withdraw(stakingPoolId, amountLP);

        stargateRouter.instantRedeemLocal(
            uint16(stargatePoolId),
            amountLP,
            address(this)
        );

        uint256 assetAmount = IERC20(asset()).balanceOf(address(this)) -
            assetBalance;
        uint256 stgAmount = stargate.balanceOf(address(this)) - stgBalance;

        _totalAvailableReward += stgAmount;
        _availableRewards[owner] += stgAmount;

        _burn(owner, shares);
        SafeERC20.safeTransfer(IERC20(asset()), receiver, assetAmount);

        emit Withdraw(caller, receiver, owner, assets, shares);
    }

    /// @notice Get amount of assets from amount of Staking Pool Token.
    /// @param amountLP Amount of Staking Pool Token.
    /// @return amountLD Amount of assets.
    function _getAmountLD(
        uint256 amountLP
    ) internal view returns (uint256 amountLD) {
        if (amountLP == 0) {
            return 0;
        }

        uint256 totalLiquidity = stargatePool.totalLiquidity();

        require(
            totalLiquidity > 0,
            "Stargate: cant convert SDtoLP when totalLiq == 0"
        );

        uint256 totalSupply = stargatePool.totalSupply();
        uint256 convertRate = stargatePool.convertRate();
        uint256 deltaCredit = stargatePool.deltaCredit();

        uint256 capAmountLP = (deltaCredit * totalSupply) / totalLiquidity;

        if (amountLP > capAmountLP) {
            amountLP = capAmountLP;
        }

        uint256 amountSD = (amountLP * totalLiquidity) / totalSupply;
        amountLD = amountSD * convertRate;
    }

    /// @notice Get amount of Staking Pool Token from amount of asset.
    /// @param amountLD Amount of assets.
    /// @return amountLP Amount of Staking Pool Token.
    function _getAmountLP(
        uint256 amountLD
    ) internal view returns (uint256 amountLP) {
        if (amountLD == 0) {
            return 0;
        }

        uint256 totalLiquidity = stargatePool.totalLiquidity();

        require(
            totalLiquidity > 0,
            "Stargate: cant convert SDtoLP when totalLiq == 0"
        );

        uint256 totalSupply = stargatePool.totalSupply();
        uint256 convertRate = stargatePool.convertRate();

        uint256 amountSD = amountLD / convertRate;
        amountLP = (amountSD * totalSupply) / totalLiquidity;
    }

    /// @notice Return the total amount of pending rewards.
    function _totalPendingReward() internal view returns (uint256) {
        return stargateLPStaking.pendingStargate(stakingPoolId, address(this));
    }

    /// @notice Reset allowance of token for a spender.
    /// @param token Token of address to set allowance.
    /// @param spender Address to give spend approval to.
    function _clearAllowance(IERC20 token, address spender) internal {
        uint256 allowance = token.allowance(address(this), spender);
        if (allowance > 0) {
            token.safeDecreaseAllowance(spender, allowance);
        }
    }

    /// @notice Set allowance of token for a spender.
    /// @param token Token of address to set allowance.
    /// @param spender Address to give spend approval to.
    /// @param amount Amount to approve for spending.
    function _setAllowance(
        IERC20 token,
        address spender,
        uint256 amount
    ) internal {
        _clearAllowance(token, spender);
        token.safeIncreaseAllowance(spender, amount);
    }

    /// @notice Get vault name from underlying asset.
    /// @param asset_ Address of underlying asset.
    /// @return vaultName Name of vault.
    function _getVaultName(
        IERC20 asset_
    ) internal view returns (string memory vaultName) {
        vaultName = string.concat(
            "Popcorn Stargate Vault ",
            IERC20Metadata(address(asset_)).symbol()
        );
    }

    /// @notice Get vault symbol from underlying asset.
    /// @param asset_ Address of underlying asset.
    /// @return vaultSymbol Symbol of vault.
    function _getVaultSymbol(
        IERC20 asset_
    ) internal view returns (string memory vaultSymbol) {
        vaultSymbol = string.concat(
            "pstg",
            IERC20Metadata(address(asset_)).symbol()
        );
    }
}
