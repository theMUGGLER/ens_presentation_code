// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract C2_Demo {
    // This is our 'storage' on the blockchain
    string private c2_address;

    // The 'Set' function: This costs GAS (Orange button)
    function setC2(string memory _newAddress) public {
        c2_address = _newAddress;
    }

    // The 'Get' function: This is FREE (Blue button)
    function getC2() public view returns (string memory) {
        return c2_address;
    }
}
