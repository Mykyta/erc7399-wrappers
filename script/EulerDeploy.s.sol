// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { EulerWrapper } from "../src/euler/EulerWrapper.sol";
import { CommonBase } from "forge-std/Base.sol";
import { Script } from "forge-std/Script.sol";
import { StdChains } from "forge-std/StdChains.sol";
import { StdCheatsSafe } from "forge-std/StdCheats.sol";
import { StdUtils } from "forge-std/StdUtils.sol";
import { console2 } from "forge-std/console2.sol";

interface EVault {
    function asset() external view returns (address);
}

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract EulerDeploy is Script {
    enum ChainToDeploy {
        Ethereum,
        Base,
        Berachain
    }

    ChainToDeploy internal chainToDeploy = ChainToDeploy.Berachain;

    function run() public {
        console2.log("Deploying as %s", msg.sender);

        vm.startBroadcast();
        EulerWrapper wrapper = new EulerWrapper(msg.sender);
        console2.log("Euler deployed at: %s", address(wrapper));
        vm.stopBroadcast();

        vm.startBroadcast();
        console2.log("Configure Euler vaults...");

        // see https://github.com/euler-xyz/euler-labels/blob/master/8453/products.json
        EVault[] memory baseVaults = new EVault[](13);
        baseVaults[0] = EVault(0x859160DB5841E5cfB8D3f144C6b3381A85A4b410); //WETH
        baseVaults[1] = EVault(0x7b181d6509DEabfbd1A23aF1E65fD46E89572609); //wstETH
        baseVaults[2] = EVault(0x358f25F82644eaBb441d0df4AF8746614fb9ea49); //cbETH
        baseVaults[3] = EVault(0xd4A805261B28f375fc9c3d89EcD2C952Cd130d14); //weETH
        baseVaults[4] = EVault(0xa487f940D6f40D7304CD4e62751220f97124BeC9); //ezETH
        baseVaults[5] = EVault(0x8b70a855B057cA85F38Ebb2a7399D9FE0BDC1046); //rETH
        baseVaults[6] = EVault(0x0A1a3b5f2041F33522C4efc754a7D096f880eE16); //USDC
        baseVaults[7] = EVault(0x9ECD9fbbdA32b81dee51AdAed28c5C5039c87117); //EURC
        baseVaults[8] = EVault(0x882018411Bc4A020A879CEE183441fC9fa5D7f8B); //CBBTC
        baseVaults[9] = EVault(0x3f0d3Fd87A42BDaa3dfCC13ADA42eA922e638a7A); //LBTC
        baseVaults[10] = EVault(0x5Fe2DE3E565a6a501a4Ec44AAB8664b1D674ac25); //AERO
        baseVaults[11] = EVault(0x556d518FDFDCC4027A3A1388699c5E11AC201D8b); //USDS
        baseVaults[12] = EVault(0x65cFEF3Efbc5586f0c05299343b8BeFb3fF5d81a); //sUSDS

        // see https://github.com/euler-xyz/euler-labels/blob/master/80094/products.json
        EVault[] memory berachainVaults = new EVault[](15);
        berachainVaults[0] = EVault(0xad9e5E2647EFb9137B6B8D688d4906fa51476870); //WBERA
        berachainVaults[1] = EVault(0x6D976915bD9DE43De1A60C39e128e320dadda000); //WETH
        berachainVaults[2] = EVault(0xb758d6eC8111FEB9b0EC758A61B7874e5821dfFd); //WBTC
        berachainVaults[3] = EVault(0xd538b6aeF78E4bDDe4FD4576E9E3A403704602bc); //HONEY
        berachainVaults[4] = EVault(0x1371dD58ce95eCD624340F072f97212A2661A280); //USDC.e
        berachainVaults[5] = EVault(0x826244d9Db2A0f438C3190a0f393c13d41AD7a2E); //STONE
        berachainVaults[6] = EVault(0x91e1Ec1e948F635c127dad41eaE1aF899399F15a); //BYUSD
        berachainVaults[7] = EVault(0x413dfb1814A6B5fe4488c49f86e2a74D285ffd5b); //NECT
        berachainVaults[8] = EVault(0x85Dba39B85218229a4c3B9b037d05CD6eB4cF05D); //beraETH
        berachainVaults[9] = EVault(0x558B16E07b8558b2a54946cA973b7b20B86A8b87); //USDe
        berachainVaults[10] = EVault(0x3de0CA4AF11108c94c9066a935ee67e53b7f9447); //sUSDe
        berachainVaults[11] = EVault(0x2CCCd307bB616E5F896Ab61CaE09Ef4E5e9fEdB7); //rUSD
        berachainVaults[12] = EVault(0xB8064453B25a91D7a4e8b7e7883A817D5742dE34); //srUSD
        berachainVaults[13] = EVault(0x1dfB669DF5E70D4238F2Cc0a9EE3b1a21FF91bC0); //iBERA
        berachainVaults[14] = EVault(0xBaBF4ce18FBab547Ad5939dEFf825f3E2f8d9402); //PT-sUSDE-25SEP2025

        // see https://github.com/euler-xyz/euler-labels/blob/master/1/products.json
        EVault[] memory ethVaults = new EVault[](24);
        ethVaults[0] = EVault(0xD8b27CF359b7D15710a5BE299AF6e7Bf904984C2);
        ethVaults[1] = EVault(0xbC4B4AC47582c3E38Ce5940B80Da65401F4628f1);
        ethVaults[2] = EVault(0x7338d86137052F0dF6e9048d6D23e09735a99585);
        ethVaults[3] = EVault(0xe846ca062aB869b66aE8DcD811973f628BA82eAf);
        ethVaults[4] = EVault(0x797DD80692c3b2dAdabCe8e30C07fDE5307D48a9);
        ethVaults[5] = EVault(0x313603FA690301b0CaeEf8069c065862f9162162);
        ethVaults[6] = EVault(0x07F9A54Dc5135B9878d6745E267625BF0E206840);
        ethVaults[7] = EVault(0x1e548CfcE5FCF17247E024eF06d32A01841fF404);
        ethVaults[8] = EVault(0x298966b32C968884F716F762f6759e8e5811aE14);
        ethVaults[9] = EVault(0x9c6e67fA86138Ab49359F595BfE4Fb163D0f16cc);
        ethVaults[10] = EVault(0x9e714434A1c94B842b75631a70E07d13f2575368);
        ethVaults[11] = EVault(0x998D761eC1BAdaCeb064624cc3A1d37A46C88bA4);
        ethVaults[12] = EVault(0x056f3a2E41d2778D3a0c0714439c53af2987718E);
        ethVaults[13] = EVault(0xbC35161043EE2D74816d421EfD6a45fDa73B050A);
        ethVaults[14] = EVault(0xE88e44C2C7dfc9bcb86e380d29375ccD6cd85406);
        ethVaults[15] = EVault(0x0D1B386187be8e96680bbddBf7Bc05FC737f81b8);
        ethVaults[16] = EVault(0xddd082d01852EFccEc0DB5477F41f530Ecb0C136);
        ethVaults[17] = EVault(0x1924D7fab80d0623f0836Cbf5258a7fa734EE9D9);
        ethVaults[18] = EVault(0x9Dfe12dBd94eb8294b047Fabe3142C5d7178071b);
        ethVaults[19] = EVault(0x1D09693608C440205fd53D7062862CBf5a6Ca69a);
        ethVaults[20] = EVault(0x34716B7026D9e6247D21e37Da1f1b157b62a16e0);
        ethVaults[21] = EVault(0xd27159604ae512c056cf282933B838A4d38B1D17);
        ethVaults[22] = EVault(0xA28C23a459fF8773EB4dBe0e7250d93F79F1Fe2B);
        ethVaults[23] = EVault(0x328646cdfBaD730432620d845B8F5A2f7D786C01);

        EVault[] memory eVaults;
        if (chainToDeploy == ChainToDeploy.Berachain) {
            eVaults = berachainVaults;
        } else if (chainToDeploy == ChainToDeploy.Ethereum) {
            eVaults = ethVaults;
        } else if (chainToDeploy == ChainToDeploy.Base) {
            eVaults = baseVaults;
        } else {
            revert("Undefined chain");
        }

        uint256 count = eVaults.length;
        address[] memory tokens = new address[](count);
        address[] memory vaults = new address[](count);
        for (uint256 i = 0; i < count; ++i) {
            address asset = eVaults[i].asset();
            address vault = address(eVaults[i]);

            vaults[i] = vault;
            tokens[i] = asset;
        }

        wrapper.setVaults(tokens, vaults);
        vm.stopBroadcast();
    }
}
