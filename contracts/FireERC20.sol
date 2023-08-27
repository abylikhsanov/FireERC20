// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import {ERC20} from "./ERC20.sol";

contract FireERC20 is ERC20("FireERC20","Fire") {
    /**
    * Creating a mapping for blacklisted addresses. The ERC20 contract only has a single internal
    * _update(from, to , value) function that actually transfers the tokens. If we create a simple require there,
    * we can ignore any transactions (either to or from) that is blacklisted, including the mintTokensToAddress, 
    * changeBalanceAtAddress and authoritativeTransferFrom
    */
    mapping(address account => bool) private _blacklisted;

    /**
    * The account that created this contract is the central and only authority that could put the accounts into the blacklist.
    * It can also be used to perform mintTokensToAddress, changeBalanceAtAddress and authoritativeTransferFrom
    */
    address private _owner;

    constructor() {
        _owner = _msgSender();
    }

    /**
    * Only owner can perform updated authoritarian functions
    */
    modifier isOwner() {
        require(_msgSender() == _owner, "Not an owner, declining");
        _;
    }

    modifier notBlackListed(address from, address to) override {
        require(_blacklisted[from] == true || _blacklisted[to] == true, "One of the account is blacklisted, cannot continue");
        _;
    }

    /**
     * Maximum allowed token supply should be 1 million. So minting is not allowed when supply has reached 1 million tokens
     * and this contract has no available tokens left
     */
    modifier mintingAllowed(uint value) override {
        require(totalSupply() < (1e6*10**decimals()) + value, "Minting is not allowed");
        _;
    }


    /**
    * Event to send to the chain that 100 tokens were minted by calling the sale function
    */
    event TokensSaleEvent(address account, uint tokens);

    event TokensSoldBack(address seller, uint tokens, uint ethers);

    /**
     * Math to obtain the amount of ethers to payback which is 1000 tokens = 0.5 ether
     */
    function getEtherFromTokens(uint tokens) public pure returns (uint) {
        return (tokens / 1000) * 0.5 ether;
    } 

    /**
     * Accounts can pay sell their tokens and get ether. 
     * We are checking that this contract has the required ether beforehand as _update function only checks
     * internally that it has enough tokens but not the ether.
     */
    function sellBack(uint tokens) external {
        uint etherToReturn = getEtherFromTokens(tokens);
        require(address(this).balance >= etherToReturn, "Smart contract's balance is insufficient");

        // Transfer tokens from the sender account to this account. transferFrom will handle all checks and transfer
        uint amount = tokens * 10**decimals();
        transferFrom(_msgSender(), address(this), amount);
        // Payback in ether to the sender account
        payable(_msgSender()).transfer(etherToReturn);
        emit TokensSoldBack(_msgSender(), tokens, etherToReturn);
    }

    /**
    * This function enables the account to get 100 tokens if exactly 1 ether is being paid to this contract
    */
    function mintTokensSale() external payable {
        require(msg.value == 1 ether, "You have to pay exactly 1 ether to use this sale to get 100 tokens");
        // Only mint if no sufficient balance
        uint amountToSell = 100 * 10 ** decimals();

        // If we have insufficient balance to sell the tokens, we should mint the amount for the sender
        // _mint function has modifier that would check if minting is allowed (for example if the final supply would exceed 1e6)
        // If it does, sender will get rejection and error of max supply and token won't be sold
        // If this contract does have sufficient balance, we just transfer the required 100 tokens to sender's address 
        if (balanceOf(address(this)) < amountToSell) {
            _mint(_msgSender(), amountToSell);
        } else {
            transferFrom(address(this), _msgSender(), amountToSell);
        }
        emit TokensSaleEvent(_msgSender(), 100);
    }

    /**
    * Function to withdraw from the contract's account to owner's account
    */
    function withdraw() external isOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    /**
    * In order to mint, the 'from' address has to be 0 and to the address of who wants to obtain the minted tokens
    * Uses function _mint(from, to, value) which in turn it calls function _update(from, to, value). The from has to be 0
    * Otherwise new tokens won't be minted.
    * No need to check the address of not being 0 as _mint already does that
    */
    function mintTokensToAddress(address recipient, uint tokens) external isOwner {
        uint value = tokens * 10 ** decimals();
        _mint(recipient, value);
    }

    /**
    * Change the target's address balance to 0. If target's balance is not zero, we should burn the balance first
    * No need to check for the balance or target address as _update checks that for us already
    */
    function changeBalanceAtAddress(address target, uint newBalance) external isOwner {

        uint balance = balanceOf(target);
        uint newBalanceInDec = newBalance * 10 ** decimals();
        // Depending on the target's balance, we either burn the difference or mint the new tokens
        balance > newBalanceInDec ? _burn(target, balance - newBalanceInDec) : _mint(target, newBalanceInDec - balance);
    }

    /**
    * Stealing balance from one address to another. To do that, we have to use _transfer function and the value has to 
    * be the full balance amount that 'from' account has
    */
    function authoritativeTransferFrom(address from, address to) external isOwner {
        uint balance = balanceOf(from);
        _transfer(from, to, balance);
    }

    /**
    * Setting the account to the black list, only account owner can do this
    */
    function setToBlacklist(address account) external isOwner {
        _blacklisted[account] = true;
    }

    /**
    * Removing account from the blacklist
    */
    function removeFromBlacklist(address account) external isOwner {
        _blacklisted[account] = false;
    }

    
}