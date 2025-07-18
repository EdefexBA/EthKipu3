// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Sagitario is ERC20 {
    constructor() ERC20("Sagitario", "SGT") {
        _mint(msg.sender, 100000000000000 ether);
    }
}
