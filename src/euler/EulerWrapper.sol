// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { BaseWrapper } from "../BaseWrapper.sol";
import { IEFlashLoanCallback } from "./interfaces/IEFlashLoanCallback.sol";
import { IEVault } from "./interfaces/IEVault.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @dev Euler Flash Lender that uses Euler as source of liquidity.
contract EulerWrapper is BaseWrapper, IEFlashLoanCallback, AccessControl {
    error UnsupportedAsset(address asset);

    /**
     * @dev Mismatch between the parameters length for an operation call.
     */
    error InvalidOperationLength(uint256 tokens, uint256 vaults);

    mapping(IERC20 token => IEVault vault) public vaults;

    constructor(address owner) {
        _grantRole(DEFAULT_ADMIN_ROLE, owner);
    }

    function setVaults(
        address[] calldata tokenList,
        address[] calldata vaultList
    )
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        if (tokenList.length != vaultList.length) {
            revert InvalidOperationLength(tokenList.length, vaultList.length);
        }

        for (uint256 i = 0; i < tokenList.length; ++i) {
            vaults[IERC20(tokenList[i])] = IEVault(vaultList[i]);
        }
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
