// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

import "hardhat/console.sol";
import "./ExampleExternalContract.sol";

contract Staker {

  ExampleExternalContract public exampleExternalContract;

  // how much ETH is deposited into the contract
  mapping(address => uint256) public balances; 
  // the time that the deposit happened
  mapping(address => uint256) public depositTimestamps;
  // the block numbers for calulating exponetial interest
  mapping(address => uint256) public depositBlocknumbers;

  // sets the interest rate for the disbursement of ETH on the principal amount staked
  uint256 public constant rewardRatePerBlock = 0.1 ether;
  // set deadlines for the staking mechanics to begin/end
  uint256 public withdrawalDeadline = block.timestamp + 120 seconds;
  uint256 public claimDeadline = block.timestamp + 240 seconds;
  // save the current block
  uint256 public currentBlock = 0;

  address public owner;

  event Stake(address indexed sender, uint256 amount);
  event Received(address, uint);
  event Execute(address indexed sender, uint256 amount);
  event WithDrawal(address indexed sender, uint256 amount);
  event Restarted();
  event UnStaked();

  // Modifiers start
  // Checks if the withdrawal period has been reached or not
  modifier withdrawalDeadlineReached( bool requireReached ) {
    uint256 timeRemaining = withdrawalTimeLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Withdrawal period is not reached yet");
    } else {
      require(timeRemaining > 0, "Withdrawal period has been reached");
    }
    _;
  }

  // Checks if the claim period has ended or not
  modifier claimDeadlineReached( bool requireReached ) {
    uint256 timeRemaining = claimPeriodLeft();
    if( requireReached ) {
      require(timeRemaining == 0, "Claim deadline is not reached yet");
    } else {
      require(timeRemaining > 0, "Claim deadline has been reached");
    }
    _;
  }

  // Requires that the contract only be completed once!
  modifier notCompleted() {
    bool completed = exampleExternalContract.completed();
    require(!completed, "Stake already completed!");
    _;
  }

  // Requires that the contract is completed (before a unstake / reset)
  modifier isCompleted() {
    bool completed = exampleExternalContract.completed();
    require(completed, "Stake not completed!");
    _;
  }
  // Modifiers end

  constructor(address exampleExternalContractAddress) {
      exampleExternalContract = ExampleExternalContract(exampleExternalContractAddress);
      owner=msg.sender;
  }

  // READ-ONLY function to calculate the time remaining before the minimum staking period has passed
  function withdrawalTimeLeft() public view returns (uint256 withdrawalTimeLeft) {
    if(block.timestamp >= withdrawalDeadline) {
      return (0);
    } else {
      return (withdrawalDeadline - block.timestamp);
    }
  }

  // READ-ONLY function to calculate the time remaining before the minimum staking period has passed
  function claimPeriodLeft() public view returns (uint256 claimPeriodLeft) {
    if(block.timestamp >= claimDeadline) {
      return (0);
    } else {
      return (claimDeadline - block.timestamp);
    }
  }

  // Stake function for a user to stake ETH in our contract
  function stake() public payable withdrawalDeadlineReached(false) claimDeadlineReached(false) {
    balances[msg.sender] = balances[msg.sender] + msg.value;
    //depositTimestamps[msg.sender] = block.timestamp;
    depositBlocknumbers[msg.sender] = block.number;
    emit Stake(msg.sender, msg.value);
  }

  // Withdraw function for a user to remove their staked ETH inclusive
  // of both the principle balance and any accrued interest
  function withdraw() public withdrawalDeadlineReached(true) claimDeadlineReached(false) notCompleted{
    require(balances[msg.sender] > 0, "You have no balance to withdraw!");
    uint256 individualBalance = balances[msg.sender];
    //uint256 indBalanceRewards = individualBalance + ((block.timestamp-depositTimestamps[msg.sender])*rewardRatePerBlock);
    
    // Update the interest mechanism in the Staker.sol contract so that you receive
    // a "non-linear" amount of ETH based on the blocks between deposit and withdrawal
    uint256 indBalanceRewards = individualBalance + (((block.number-depositBlocknumbers[msg.sender])^2)*rewardRatePerBlock);

    balances[msg.sender] = 0;
    // Transfer all ETH via call! (not transfer) cc: https://solidity-by-example.org/sending-ether
    (bool sent, bytes memory data) = msg.sender.call{value: indBalanceRewards}("");
    require(sent, "RIP; withdrawal failed :( ");
    emit WithDrawal(msg.sender, indBalanceRewards);
  }

  // Allows any user to repatriate "unproductive" funds that are left in the staking contract
  // past the defined withdrawal period
  function execute() public claimDeadlineReached(true) notCompleted {
    uint256 contractBalance = address(this).balance;
    exampleExternalContract.complete{value: address(this).balance}();
  }

  function unStake() public claimDeadlineReached(true) isCompleted {
    exampleExternalContract.unStake();
    emit UnStaked();
  }

  // Time to "kill-time" on our local testnet
  function killTime() public {
    currentBlock = block.timestamp;
  }
  
  // Add the `receive()` special function that receives eth and calls stake()
  // Function for our smart contract to receive ETH
  // cc: https://docs.soliditylang.org/en/latest/contracts.html#receive-ether-function
  receive() external payable {
      emit Received(msg.sender, msg.value);
  }

  // For testing it is easier if we can reset the timers
  function restartTime() external payable {
      withdrawalDeadline = block.timestamp + 120 seconds;
      claimDeadline = block.timestamp + 240 seconds;
      //exampleExternalContract.debugReset();
      emit Restarted();
  }

}
