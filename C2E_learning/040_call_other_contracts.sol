// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MyTargetContract {
    uint256 public x;
    uint256 public value;

    function setX(uint256 _x) external {
        x = _x;
    }

    function getX() external view returns (uint256) {
        return x;
    }

    function setXAndReceiveEther(uint256 _x) external payable {
        x = _x;
        value = msg.value;
    }

    function getXAndValue() external view returns (uint256, uint256) {
        return (x, value);
    }
}

contract MyCallerContract {
    function setTargetX(address _target, uint256 _x) external {
        MyTargetContract target = MyTargetContract(_target);
        target.setX(_x);
    }

    function getTargetX(address _target) external view returns (uint256) {
        MyTargetContract target = MyTargetContract(_target);
        return target.getX();
    }

    function setXWithEther(address _target, uint256 _x) external payable {
        MyTargetContract target = MyTargetContract(_target);
        target.setXAndReceiveEther{value: msg.value}(_x);
    }

    function getXWithEther(
        address _target
    ) external view returns (uint256, uint256) {
        MyTargetContract target = MyTargetContract(_target);
        return target.getXAndValue();
    }
}

contract Caller {
    function setX(TestContract _test, uint _x) external {
        _test.setX(_x);
    }
    function getX(address _test) external view returns (uint x) {
        x = TestContract(_test).getX();
    }
    function setXandSendEther(TestContract _test, uint _x) external payable {
        _test.setXandSendEther{value: msg.value}(_x);
    }
    function getXandValue(
        address _test
    ) external view returns (uint x, uint value) {
        (x, value) = TestContract(_test).getXandValue();
    }
}

contract TestContract {
    uint256 public x;
    uint256 public value = 123;
    function setX(uint256 _x) public returns (uint256) {
        x = _x;
        return x;
    }
    function getX() external view returns (uint) {
        return x;
    }
    function setXandSendEther(uint256 _x) public payable {
        x = _x;
        value = msg.value;
    }
    function getXandValue() external view returns (uint, uint) {
        return (x, value);
    }
}
