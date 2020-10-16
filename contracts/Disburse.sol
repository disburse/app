// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

contract Disburse {

    address public admin;
    string public name;

    modifier restricted() {
        require(
        msg.sender == admin,
        "This function is restricted to the administrator"
        );
        _;
    }

    constructor () public
    {
        admin = msg.sender;
    }

    function setName(string memory _name) public {
        name = _name;
    }
}