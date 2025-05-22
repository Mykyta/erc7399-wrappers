// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

interface IEVault {
    function flashLoan(uint256 amount, bytes memory data) external;
}
