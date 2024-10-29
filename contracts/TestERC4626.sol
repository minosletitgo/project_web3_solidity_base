// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract ERC4626Vault is ERC20, ReentrancyGuard {
    IERC20 public immutable asset;

    constructor(IERC20 _asset) ERC20("ERC4626 Vault Token", "vToken") {
        asset = _asset;
    }

    /**
     * @notice 获取当前 Vault 管理的资产总量
     */
    function totalAssets() public view returns (uint256) {
        return asset.balanceOf(address(this));
    }

    /**
     * @notice 将指定数量的资产转换为等价的份额数量
     */
    function convertToShares(uint256 assets) public view returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? assets : (assets * supply) / totalAssets();
    }

    /**
     * @notice 将指定数量的份额转换为等价的资产数量
     */
    function convertToAssets(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply();
        return supply == 0 ? shares : (shares * totalAssets()) / supply;
    }

    /**
     * @notice 最大可存入数量
     */
    function maxDeposit(address) public pure returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice 存入指定数量的资产，并给接收者铸造相应份额
     */
    function deposit(uint256 assets, address receiver) public nonReentrant returns (uint256 shares) {
        require(assets <= maxDeposit(receiver), "Deposit exceeds max limit");

        shares = convertToShares(assets);
        asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice 最大可铸造数量
     */
    function maxMint(address) public pure returns (uint256) {
        return type(uint256).max;
    }

    /**
     * @notice 铸造指定数量的份额，要求存入相应资产
     */
    function mint(uint256 shares, address receiver) public nonReentrant returns (uint256 assets) {
        require(shares <= maxMint(receiver), "Mint exceeds max limit");

        assets = convertToAssets(shares);
        asset.transferFrom(msg.sender, address(this), assets);
        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    /**
     * @notice 最大可提取数量
     */
    function maxWithdraw(address owner) public view returns (uint256) {
        return convertToAssets(balanceOf(owner));
    }

    /**
     * @notice 从 Vault 中提取指定数量的资产
     */
    function withdraw(uint256 assets, address receiver, address owner) public nonReentrant returns (uint256 shares) {
        shares = convertToShares(assets);
        require(shares <= balanceOf(owner), "Insufficient balance");

        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        _burn(owner, shares);
        asset.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /**
     * @notice 最大可赎回数量
     */
    function maxRedeem(address owner) public view returns (uint256) {
        return balanceOf(owner);
    }

    /**
     * @notice 赎回指定数量的份额
     */
    function redeem(uint256 shares, address receiver, address owner) public nonReentrant returns (uint256 assets) {
        require(shares <= maxRedeem(owner), "Redeem exceeds max limit");

        assets = convertToAssets(shares);
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }

        _burn(owner, shares);
        asset.transfer(receiver, assets);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);
    }

    /**
     * @dev 存款事件，用于记录存款活动
     */
    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    /**
     * @dev 提现事件，用于记录提现活动
     */
    event Withdraw(address indexed caller, address indexed receiver, address indexed owner, uint256 assets, uint256 shares);
}
