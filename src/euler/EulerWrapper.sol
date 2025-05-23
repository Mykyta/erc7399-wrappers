// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import { BaseWrapper } from "../BaseWrapper.sol";
import { IEFlashLoanCallback } from "./interfaces/IEFlashLoanCallback.sol";
import { IEVKFactoryPerspective } from "./interfaces/IEVKFactoryPerspective.sol";
import { IEVault } from "./interfaces/IEVault.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Euler Flash Lender that uses Euler as source of liquidity.
contract EulerWrapper is BaseWrapper, IEFlashLoanCallback {
    error UnsupportedAsset(address asset);
    error UnverifiedVault();

    /**
     * @dev No vault for the provided asset
     */
    error UnavailableVault();

    /**
     * @dev A vault doesn't have liquidity
     */
    error NoLiquidity();

    event VaultsAdded(uint256 count);

    mapping(IERC20 token => IEVault[] vaults) public tokenVaults;

    IEVKFactoryPerspective internal evkFactory;

    constructor(IEVKFactoryPerspective evkFactoryPerspective) {
        evkFactory = evkFactoryPerspective;
        address[] memory vaultList = evkFactory.verifiedArray();
        for (uint256 i = 0; i < vaultList.length; ++i) {
            IEVault vault = IEVault(vaultList[i]);
            address asset = vault.asset();
            IERC20 token = IERC20(asset);
            addVault(token, vault);
        }
        emit VaultsAdded(vaultList.length);
    }

    function addVault(IERC20 token, IEVault vault) public {
        if (!evkFactory.isVerified(address(vault))) revert UnverifiedVault();

        if (tokenVaults[token].length == 0) {
            tokenVaults[token] = new IEVault[](0);
        }
        tokenVaults[token].push(vault);
    }

    function maxFlashLoan(address asset) public view returns (uint256) {
        IEVault[] memory vaults = tokenVaults[IERC20(asset)];
        uint256 balance = 0;

        for (uint256 i = 0; i < vaults.length; ++i) {
            uint256 vaultBalance = IERC20(asset).balanceOf(address(vaults[i]));
            if (vaultBalance > balance) {
                balance = vaultBalance;
            }
        }

        return balance;
    }

    function flashFee(address asset, uint256 amount) external view returns (uint256) {
        uint256 max = maxFlashLoan(asset);
        if (max == 0) revert UnsupportedAsset(asset);
        return amount >= max ? type(uint256).max : 0;
    }

    function onFlashLoan(bytes calldata params) external override {
        (address asset, uint256 amount, bytes memory data) = abi.decode(params, (address, uint256, bytes));
        _bridgeToCallback(asset, amount, 0, data);

        // repay amount back to the Euler contract
        IERC20(asset).transfer(msg.sender, amount);
    }

    function _flashLoan(address asset, uint256 amount, bytes memory data) internal override {
        IEVault[] memory vaults = tokenVaults[IERC20(asset)];

        // Ensure the vaults array is not empty
        if (vaults.length == 0) {
            revert UnavailableVault();
        }

        // find a vault with the max liquidity
        IEVault vault;
        uint256 balance = 0;
        for (uint256 i = 0; i < vaults.length; ++i) {
            uint256 vaultBalance = IERC20(asset).balanceOf(address(vaults[i]));
            if (vaultBalance > balance) {
                balance = vaultBalance;
                vault = vaults[i];
            }
        }

        if (address(vault) == address(0)) {
            revert NoLiquidity();
        }

        vault.flashLoan(amount, abi.encode(asset, amount, data));
    }
}
