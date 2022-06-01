pragma solidity 0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "./YourToken.sol";

contract Vendor is Ownable {
    event BuyTokens(address buyer, uint256 amountOfETH, uint256 amountOfTokens);
    event SellTokens(
        address seller,
        uint256 amountOfTokens,
        uint256 amountOfEth
    );

    YourToken public yourToken;

    constructor(address tokenAddress) {
        yourToken = YourToken(tokenAddress);
    }

    //create a price variable
    uint256 public constant tokensPerEth = 100;

    // ToDo: create a payable buyTokens() function:
    function buyTokens() external payable {
        uint256 amountOfTokens = msg.value * tokensPerEth;

        yourToken.approve(msg.sender, amountOfTokens);
        yourToken.transfer(msg.sender, amountOfTokens);

        emit BuyTokens(msg.sender, msg.value, amountOfTokens);
    }

    // ToDo: create a withdraw() function that lets the owner withdraw ETH
    function withdraw() external onlyOwner {
        (bool sucess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(sucess, "Failed withdraw Ether");
    }

    // ToDo: create a sellTokens(uint256 _amount) function:
    function sellTokens(uint256 theAmount) external {
        require(theAmount > 0, "No tokens to transfer");
        //transact tokens
        bool sell = yourToken.transferFrom(
            msg.sender,
            address(this),
            theAmount
        );
        require(sell, "Failed to sell Tokens");

        uint256 tokensToETH = theAmount / tokensPerEth;
        uint256 vendorETH = address(this).balance;
        require(vendorETH >= tokensToETH, "Not enough ETH");

        (bool sent, ) = payable(msg.sender).call{value: tokensToETH}("");
        require(sent, "Failed transaction to ETH");
        emit SellTokens(msg.sender, tokensToETH, theAmount);
    }
}
