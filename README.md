# Stacks Marketplace

[![Stacks](https://img.shields.io/badge/Stacks-Mainnet-5546FF)](https://stacks.co)
[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contract-orange)](https://clarity-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A full-featured NFT marketplace on Stacks blockchain with offer/bid system.

## Features

- 🏪 List NFTs for sale with custom pricing
- 🛒 Buy listed NFTs instantly
- 💬 **Make offers** - Submit bids below asking price
- ✅ **Accept/reject offers** - Sellers control negotiations
- 💰 2.5% marketplace fee
- 📊 Track sales volume and history

## Tech Stack

- **Frontend**: Next.js 14, React 18, TypeScript
- **Blockchain**: Stacks Mainnet
- **Smart Contract**: Clarity
- **Libraries**: @stacks/connect, @stacks/transactions, @stacks/network

## Contract Functions

### Listing Functions
- `create-listing (token-id, price, contract)` - List NFT for sale
- `buy-listing (listing-id)` - Purchase listed NFT
- `cancel-listing (listing-id)` - Cancel your listing

### Offer System
- `make-offer (listing-id, amount)` - Make an offer on a listing
- `accept-offer (offer-id)` - Accept an offer (sellers)
- `cancel-offer (offer-id)` - Cancel/withdraw your offer

### Read Functions
- `get-listing (id)` - Get listing details
- `get-offer (id)` - Get offer details
- `get-total-volume` - Get marketplace volume
- `calculate-fee (price)` - Calculate marketplace fee

## Getting Started

```bash
npm install
npm run dev
```

## Contract Address

Deployed on Stacks Mainnet: `SP3E0DQAHTXJHH5YT9TZCSBW013YXZB25QFDVXXWY.marketplace`

## License

MIT
