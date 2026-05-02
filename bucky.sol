// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

contract Bucky {
    uint C2;

    // Function to update the age variable
    function setAge(uint x) public {
        C2 = x;
    }

    // Function to retrieve the current age value
    function getAge() public view returns (uint) {
        return C2;
    }
}
