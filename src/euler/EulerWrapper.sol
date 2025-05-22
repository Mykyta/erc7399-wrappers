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
    error UnverifiedVault(address vault);

    event VaultsAdded(uint256 count);

    mapping(IERC20 token => IEVault vault) public vaults;

    IEVKFactoryPerspective internal factory;

    constructor(address evkFactoryPerspective) {
        factory = IEVKFactoryPerspective(evkFactoryPerspective);
        address[] memory vaultList = factory.verifiedArray();
        for (uint256 i = 0; i < vaultList.length; ++i) {
            IEVault vault = IEVault(vaultList[i]);
            address asset = vault.asset();
            vaults[IERC20(asset)] = vault;
        }
        emit VaultsAdded(vaultList.length);
    }

    function setVaults(address[] calldata vaultList) external {
        for (uint256 i = 0; i < vaultList.length; ++i) {
            address vaultAddr = vaultList[i];
            if (!factory.isVerified(vaultAddr)) revert UnverifiedVault(vaultAddr);
            IEVault vault = IEVault(vaultAddr);
            address asset = vault.asset();
            vaults[IERC20(asset)] = vault;
        }
        emit VaultsAdded(vaultList.length);
    }

    function maxFlashLoan(address asset) public view returns (uint256) {
        IEVault vault = vaults[IERC20(asset)];
        if (address(vault) == address(0)) {
            return 0;
        }

        return IERC20(asset).balanceOf(address(vault));
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
        IEVault vault = vaults[IERC20(asset)];
        vault.flashLoan(amount, abi.encode(asset, amount, data));
    }
}
