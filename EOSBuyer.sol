pragma solidity ^0.4.11;

/*

EOS Buyer
========================

WARNING: THIS IS NOT YET A FUNCTIONING CONTRACT - DO NOT USE!

Buys EOS tokens from the crowdsale on your behalf.

Author: Forked from Bancor Buyer by /u/Cintix under MIT license

Copyright (c) 2017

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

// ERC20 Interface: https://github.com/ethereum/EIPs/issues/20
contract ERC20 {
  function transfer(address _to, uint _value) returns (bool success);
}

// Interface to EOS ICO Contract
contract CrowdsaleController {
  function contributeETH() payable returns (uint256 amount);
}

contract EOSBuyer {

  // Store the amount of ETH deposited or EOS owned by each account.
  mapping (address => uint) public balances;
  
  // Reward for first to execute the buy.
  uint public reward;
  
  // Track whether the contract has bought the tokens yet.
  bool public bought_tokens;
  
  // Record the time the contract bought the tokens.
  uint public time_bought;

  // The EOS Token Sale address.
  address public sale = 0x75000000000000000000000000000000000000;
  
  // EOS Smart Token Contract address.
  address public token = 0xE0500000000000000000000000000000000000;
  
  // The developer address.
  address developer = 0xDA000000000000000000000000000000000000;
  
  // Withdraws all ETH deposited by the sender.
  // Called to cancel a user's participation in the sale.
  function withdraw(){
  
    // Store the user's balance prior to withdrawal in a temporary variable.
    uint amount = balances[msg.sender];
    
    // Update the user's balance prior to sending ETH to prevent recursive call.
    balances[msg.sender] = 0;
    
    // Return the user's funds.  Throws on failure to prevent loss of funds.
    msg.sender.transfer(amount);
    
  }
  
  // Allow anyone to contribute to the buy executer's reward.
  function add_reward() payable {
  
    // Update reward value to include received amount.
    reward += msg.value;
    
  }
  
  // Buys tokens in the crowdsale and rewards the caller, callable by anyone.
  function buy(){
  
    // Record that the contract has bought the tokens.
    bought_tokens = true;
    
    // Record the time the contract bought the tokens.
    time_bought = now;
    
    // Transfer all the funds (less the caller reward) 
    // to the E0S crowdsale contract to buy tokens.
    // Throws if the crowdsale hasn't started yet or has
    // already completed, preventing loss of funds.
    CrowdsaleController(sale).contributeETH.value(this.balance - reward)();
    
    // Reward the caller for being the first to execute the buy.
    msg.sender.transfer(reward);
  }
  
  // A helper function for the default function, allowing contracts to interact.
  function default_helper() payable {
  
    // Only allow deposits if the contract hasn't already purchased the tokens.
      // ** Allow during sale or only pre-launch? Rolling contract or daily contracts? Probably daily for safety. ** //
    if (!bought_tokens) {
      // Update records of deposited ETH to include the received amount.
      balances[msg.sender] += msg.value;
    }
    
    // Withdraw the sender's tokens if the contract has already purchased them.
    else {
    
      // Store the user's E0S balance in a temporary variable (1 ETHWei -> 100 EOSWei).
        // ** This amount will be variable on daily basis. Need to confirm from chain? ** //
      uint amount = balances[msg.sender] * 100;
      
      // Update the user's balance prior to sending EOS to prevent recursive call.
      balances[msg.sender] = 0;
      
      // No fee for withdrawing during the crowdsale.
        // ** This amount will be variable on daily basis. Need to confirm from chain? ** //
      uint fee = 0;
      
      // 1% fee for withdrawing after the crowdsale has ended.
      if (now > time_bought + 1 hours) {
        fee = amount / 100;
      }
      
      // Transfer the tokens to the sender and the developer.
      ERC20(token).transfer(msg.sender, amount - fee);
      ERC20(token).transfer(developer, fee);
      
      // Refund any ETH sent after the contract has already purchased tokens.
      msg.sender.transfer(msg.value);
      
    }
  }
  
  function () payable {
    default_helper();
  }
}
