// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {
    ExampleExternalContract public exampleExternalContract;

    mapping(address => uint256) public balances;

    uint256 public constant threshold = 1 ether;
    uint256 public deadline = block.timestamp + 72 hours;
    bool public openForWithdraw;

    constructor(address exampleExternalContractAddress) public {
        exampleExternalContract = ExampleExternalContract(
            exampleExternalContractAddress
        );
    }

    event Stake(address indexed _from, uint256 indexed _amount);

    modifier deadlineExpired(bool requireExpired) {
        require(block.timestamp >= deadline, "Deadline not expired");
        _;
    }
    modifier notCompleted() {
        bool completed = exampleExternalContract.completed();
        require(!completed, "Contract completed");
        _;
    }

    // Collect funds in a payable `stake()` function and track individual `balances` with a mapping:
    //  ( make sure to add a `Stake(address,uint256)` event and emit it for the frontend <List/> display )
    function stake() public payable {
        require(timeLeft() > 0, "No time left to stake");
        balances[msg.sender] = balances[msg.sender] + msg.value;
        emit Stake(msg.sender, msg.value);
    }

    // After some `deadline` allow anyone to call an `execute()` function
    //  It should either call `exampleExternalContract.complete{value: address(this).balance}()` to send all the value

    function execute() public notCompleted {
        if (timeLeft() == 0 && address(this).balance > threshold) {
            exampleExternalContract.complete{value: address(this).balance}();
            openForWithdraw = false;
        } else if (timeLeft() == 0 && address(this).balance <= threshold) {
            openForWithdraw = true;
        }
    }

    // Add a `withdraw()` function to let users withdraw their balance
    // if the `threshold` was not met, allow everyone to call a `withdraw()` function

    function withdraw() external notCompleted deadlineExpired(true) {
        require(
            openForWithdraw == true && address(this).balance <= threshold,
            "Not open for withdraw"
        );

        uint256 amount = balances[msg.sender];
        require(amount > 0, "No balance to withdraw");

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Failed to send Ether");

        balances[msg.sender] = 0;
    }

    // Add a `timeLeft()` view function that returns the time left before the deadline for the frontend
    function timeLeft() public view returns (uint256 _timeLeft) {
        if (block.timestamp >= deadline) {
            return 0;
        } else {
            return deadline - block.timestamp;
        }
    }

    // Add the `receive()` special function that receives eth and calls stake()
    receive() external payable {
        emit Stake(msg.sender, msg.value);
    }
}
