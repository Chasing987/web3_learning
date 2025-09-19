// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICounter {
    function count() external view returns (uint256);
    function increment() external;
}

// Contract call the Counter contract
contract CallCounter{
    ICounter public counter;
    uint public count;

    constructor(address _counter) {
        counter = ICounter(_counter);
    }

    function incrementCounter() external {
        counter.increment();
    }

    function updateCount() external {
        count = counter.count();
    }
}