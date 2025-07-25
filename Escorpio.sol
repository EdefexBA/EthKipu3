// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Escorpio is ERC20 {
    constructor() ERC20("Escorpio", "ERP") {
        _mint(msg.sender, 100000000000 ether);
    }
}
