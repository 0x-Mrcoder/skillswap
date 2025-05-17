// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from 'forge-std/Script.sol';

import {SkillSwap} from 'src/SkillSwap.sol';

contract DeploySkillSwap is Script {
    function run() external {
        vm.startBroadcast();
        new SkillSwap(0x62127C8AB2145924e51D2CDD1E60863f267a83D0);
        vm.stopBroadcast();
    }
}
