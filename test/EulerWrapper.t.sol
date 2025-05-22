// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {EulerWrapper} from "../src/euler/EulerWrapper.sol";
import {MockBorrower} from "./MockBorrower.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CommonBase} from "forge-std/Base.sol";
import {StdChains} from "forge-std/StdChains.sol";
import {StdCheats, StdCheatsSafe} from "forge-std/StdCheats.sol";
import {StdUtils} from "forge-std/StdUtils.sol";
import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";

/// @dev If this is your first time with Forge, read this tutorial in the Foundry Book:
/// https://book.getfoundry.sh/forge/writing-tests
contract EulerWrapperTest is Test {
    using SafeERC20 for IERC20;

    EulerWrapper internal wrapper;
    MockBorrower internal borrower;
    address internal USDC;
    address internal arETH;
    address internal usdcVault;

    /// @dev A function invoked before each test case is run.
    function setUp() public virtual {
        // Revert if there is no API key.
        string memory alchemyApiKey = vm.envOr("API_KEY_ALCHEMY", string(""));
        if (bytes(alchemyApiKey).length == 0) {
            revert("API_KEY_ALCHEMY variable missing");
        }

        vm.createSelectFork({urlOrAlias: "base", blockNumber: 30017722});
        usdcVault = 0x0A1a3b5f2041F33522C4efc754a7D096f880eE16;
        USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
        arETH = 0xCc9EE9483f662091a1de4795249E24aC0aC2630f;

        address[] memory tokens = new address[](1);
        address[] memory vaults = new address[](1);

        tokens[0] = USDC;
        vaults[0] = usdcVault;

        address owner = address(0x1);
        vm.startPrank(owner);
        wrapper = new EulerWrapper(owner);
        wrapper.setVaults(tokens, vaults);
        borrower = new MockBorrower(wrapper);
        vm.stopPrank();
    }

    /// @dev Basic test. Run it with `forge test -vvv` to see the console log.
    function test_flashFee() external {
        console2.log("test_flashFee");
        assertEq(wrapper.flashFee(USDC, 10e6), 0, "Fee not zero");
    }

    function test_flashFee_unsupportedAsset() external {
        console2.log("test_flashFee");
        vm.expectRevert(abi.encodeWithSelector(EulerWrapper.UnsupportedAsset.selector, arETH));
        wrapper.flashFee(arETH, 1e18);
    }

    function test_maxFlashLoan() external {
        console2.log("test_maxFlashLoan");
        assertEq(wrapper.maxFlashLoan(USDC), 2504267155141, "Max flash loan not right");
    }

    function test_flashLoan() external {
        console2.log("test_flashLoan");
        uint256 loan = 10e6;
        bytes memory result = borrower.flashBorrow(USDC, loan);

        // Test the return values passed through the wrapper
        (bytes32 callbackReturn) = abi.decode(result, (bytes32));
        assertEq(uint256(callbackReturn), uint256(borrower.ERC3156PP_CALLBACK_SUCCESS()), "Callback failed");

        // Test the borrower state during the callback
        assertEq(borrower.flashInitiator(), address(borrower));
        assertEq(address(borrower.flashAsset()), address(USDC));
        assertEq(borrower.flashAmount(), loan);
        assertEq(borrower.flashBalance(), loan); // The amount we transferred to pay for fees, plus the amount we borrowed
        assertEq(borrower.flashFee(), 0);
    }

    function test_measureFlashLoanGas() public {
        console2.log("test_measureFlashLoanGas");
        uint256 loan = 10e6;
        uint256 fee = wrapper.flashFee(USDC, loan);
        IERC20(USDC).safeTransfer(address(borrower), fee);
        borrower.flashBorrowMeasureGas(USDC, loan, "Euler");
    }
}
