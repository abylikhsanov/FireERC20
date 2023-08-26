# FireERC20 - ERC20 Token Implementation

This repository contains an extended version of the OpenZeppelin ERC20 token with additional features such as god-mode, sanctions, token sale, and partial refunds.

## Features

1. ERC20 with God-Mode
mintTokensToAddress(address recipient): Allows a special address to mint tokens to any recipient.
changeBalanceAtAddress(address target): Enables the special address to modify the balance of any target address.
authoritativeTransferFrom(address from, address to): Permits the special address to transfer tokens from any address to another without requiring an allowance.

2. ERC20 with Sanctions
Centralized authority has the power to blacklist addresses, preventing them from sending or receiving the token.
Only the centralized authority can control and modify this blacklist.

3. Token Sale
Users can mint 1000 tokens by paying 1 ether.
The token has 18 decimal places, aligning with the standard for most ERC20 tokens.
The sale ends after 1 million tokens have been minted.
A function is available to withdraw the Ethereum collected during the sale to the owner's address.

4. Partial Refund
Users can transfer their tokens back to the contract and receive 0.5 ether for every 1000 tokens.
The contract checks if it has enough ether to pay the user before proceeding with the transaction.
Users can buy and sell tokens freely, but repeated buying and selling will result in a net loss of ether.

## Important Notes

The maximum token supply is capped at 1 million.
If someone tries to mint tokens when the supply is exhausted and the contract isn't holding any tokens, the minting operation will fail.
Developers should be aware of potential integer division issues.

This project heavily relies on the OpenZeppelin library for the base ERC20 implementation and other utility functions.