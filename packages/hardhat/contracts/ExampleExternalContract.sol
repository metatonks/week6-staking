// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;  //Do not change the solidity version as it negativly impacts submission grading

//import "@openzeppelin/contracts/access/Ownable.sol";

contract ExampleExternalContract {

  bool public completed;

  address public owner;
  address public stakerContractAddress;

  // Defining a constructor   
  constructor() public {
    owner=msg.sender;
  }

  function setStakerContractAddress(address _stakerContractAddress) public {
    //require(msg.sender == owner, "Only callable by owner!");
    stakerContractAddress = _stakerContractAddress;
  }

  function complete() public payable {
    completed = true;
  }

  // Return the staked fund back to Staker.sol and reset the completed flag
  function unStake() public {
    uint256 contractBalance = address(this).balance;

    // Require caller is the Staker.sol contract
    require(msg.sender == stakerContractAddress, "Only callable by Staker contract");
    // Require there is funds staked in this contract
    require(contractBalance > 0, "No funds to transfer");

    (bool sent, bytes memory data) = msg.sender.call{value: address(this).balance}("");
    require(sent, "RIP; withdrawal failed :( ");

    completed = false;

  }

}
