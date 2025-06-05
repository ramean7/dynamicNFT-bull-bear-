# 🐂🐻 Bull & Bear Dynamic NFT

A **dynamic NFT** that updates its metadata based on **real-world asset prices** using **Chainlink Data Feeds** and **Chainlink Automation**.

## 🧩 Overview

This project is an ERC-721 NFT smart contract built with Solidity that changes its metadata (i.e., the image/URI) based on market conditions:
- If the price **increases**, the NFT updates to a **Bull** image.
- If the price **decreases**, it updates to a **Bear** image.

It uses:
- **Chainlink Data Feeds** to fetch live asset prices (e.g., ETH/USD).
- **Chainlink Automation (Keepers)** to trigger updates automatically on a set time interval.

---

## 🚀 Features

- ✅ ERC721-compliant NFTs
- 🔗 Live asset tracking with Chainlink Price Feeds
- 🔁 Automatic metadata updates via Chainlink Automation
- 📡 Dynamic NFT state: Bull or Bear
- 🕓 Configurable update interval
- 🔐 Owner-restricted minting and control

---

## ⚙️ How It Works

1. **Minting**: The contract owner can mint NFTs via `safeMint()`.
2. **Automation**: The contract periodically checks asset prices using `checkUpkeep()` and updates state in `performUpkeep()`.
3. **NFT Updates**: If the price has changed:
   - A higher price updates all NFTs to the "Bull" image.
   - A lower price updates them to the "Bear" image.
4. The NFT image/metadata changes accordingly for all holders.

---

## 🔗 Technology Stack

- [Solidity ^0.8.27](https://docs.soliditylang.org/)
- [OpenZeppelin Contracts ^5.0](https://docs.openzeppelin.com/contracts/5.x/)
- [Chainlink Data Feeds](https://docs.chain.link/data-feeds/)
- [Chainlink Automation](https://docs.chain.link/chainlink-automation/introduction/)
- IPFS for hosting metadata

---

## 📄 Key Contracts and Imports

```solidity
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AutomationCompatible} from "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
