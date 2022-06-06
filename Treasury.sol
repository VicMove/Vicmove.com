// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (finance/VestingWallet.sol)
pragma solidity ^0.8.0;


import "./Address.sol";
import "./BEPOwnable.sol";
import "./IBEP20.sol";

contract Treasury is BEPOwnable {

    address public Pool2;

    /**
     * @dev Set the beneficiary, start timestamp and vesting duration of the vesting wallet.
     */
    constructor() payable { 
        Pool2 = 0xfA0E47A2d6a58b9fd7Ca1d4bFAADd11E8811824B;
    }
    
    /**
     * @dev The contract should be able to receive Eth.
     */
    

    function setPool2(address _Pool2) external onlyOwner {
        Pool2 = _Pool2;
    }  
    /**
     * @dev get balance.
     */
    function getBalanceToken(address token) public view virtual returns (uint256) {
        return IBEP20(token).balanceOf(address(this));
    }
    function sentT2Pool2Token(address tokenaddress, uint256 amount) external onlyOwner {
        uint256 newBalance = IBEP20(tokenaddress).balanceOf(address(this));
        require(amount>0 && amount<=newBalance,"Amount > 0 && < Balance");
        IBEP20(tokenaddress).transfer(Pool2, amount);
    }

    function getBalanceBNB() public view virtual returns (uint256) {
        return address(this).balance;
    }
    function sentT2Pool2BNB(uint256 amount) external onlyOwner {
        uint256 newBalance = address(this).balance;
        require(amount>0 && amount<=newBalance,"Amount > 0 && < Balance");
        payable(Pool2).transfer(amount);
    }

    receive() external payable {}
}