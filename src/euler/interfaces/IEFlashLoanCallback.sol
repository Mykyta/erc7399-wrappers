// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IEFlashLoanCallback {
    function onFlashLoan(bytes calldata data) external;
}
