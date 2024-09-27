//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../src/GoodFun.sol";
import "./base/BaseScript.s.sol";

contract DeployGoodFun is BaseScript {
    GoodFun internal nft;

    constructor() BaseScript(address(0x2A6C106ae13B558BB9E2Ec64Bd2f1f7BEFF3A5E0)) {}

    function run() public payable broadcast {
        nft = new GoodFun(address(0x3ed3EfD6621167f1b5A3B23216B8AF20E6098307));
    }

    function execute() public payable broadcast {
        nft.mintTen();
    }
}
