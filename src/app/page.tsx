"use client";

import { useState } from "react";
import { openContractCall, showConnect } from "@stacks/connect";
import { STACKS_MAINNET } from "@stacks/network";
import { AnchorMode, PostConditionMode, uintCV, principalCV } from "@stacks/transactions";

const CONTRACT_ADDRESS = "SP3E0DQAHTXJHH5YT9TZCSBW013YXZB25QFDVXXWY";
const CONTRACT_NAME = "marketplace";

export default function Marketplace() {
  const [address, setAddress] = useState<string | null>(null);
  const [txId, setTxId] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [tokenId, setTokenId] = useState("");
  const [price, setPrice] = useState("");
  const [nftContract, setNftContract] = useState("");
  const [listingId, setListingId] = useState("");

  const connectWallet = () => {
    showConnect({
      appDetails: { name: "Stacks Marketplace", icon: "/logo.png" },
      onFinish: () => {
        const userData = JSON.parse(localStorage.getItem("blockstack-session") || "{}");
        setAddress(userData?.userData?.profile?.stxAddress?.mainnet || null);
      },
      userSession: undefined,
    });
  };

  const createListing = async () => {
    if (!tokenId || !price || !nftContract) return;
    setLoading(true);
    try {
      await openContractCall({
        network: STACKS_MAINNET,
        anchorMode: AnchorMode.Any,
        contractAddress: CONTRACT_ADDRESS,
        contractName: CONTRACT_NAME,
        functionName: "create-listing",
        functionArgs: [
          uintCV(parseInt(tokenId)),
          uintCV(Math.floor(Number(price) * 1000000)),
          principalCV(nftContract)
        ],
        postConditionMode: PostConditionMode.Allow,
        onFinish: (data) => {
          setTxId(data.txId);
          setLoading(false);
        },
        onCancel: () => setLoading(false),
      });
    } catch (error) {
      console.error(error);
      setLoading(false);
    }
  };

  const buyListing = async () => {
    if (!listingId) return;
    setLoading(true);
    try {
      await openContractCall({
        network: STACKS_MAINNET,
        anchorMode: AnchorMode.Any,
        contractAddress: CONTRACT_ADDRESS,
        contractName: CONTRACT_NAME,
        functionName: "buy-listing",
        functionArgs: [uintCV(parseInt(listingId))],
        postConditionMode: PostConditionMode.Allow,
        onFinish: (data) => {
          setTxId(data.txId);
          setLoading(false);
        },
        onCancel: () => setLoading(false),
      });
    } catch (error) {
      console.error(error);
      setLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-gradient-to-br from-pink-900 to-rose-900 text-white p-8">
      <div className="max-w-xl mx-auto">
        <h1 className="text-4xl font-bold mb-2 text-center">🏪 NFT Marketplace</h1>
        <p className="text-center text-gray-300 mb-8">Buy and sell NFTs on Stacks</p>

        {!address ? (
          <button onClick={connectWallet} className="w-full bg-pink-500 hover:bg-pink-600 py-3 rounded-lg font-semibold">
            Connect Wallet
          </button>
        ) : (
          <div className="space-y-6">
            <div className="bg-white/10 p-4 rounded-lg">
              <p className="font-mono text-sm">{address.slice(0, 12)}...{address.slice(-6)}</p>
            </div>

            <div className="bg-white/10 p-6 rounded-lg space-y-4">
              <h2 className="text-xl font-bold">Create Listing</h2>
              <input type="text" value={nftContract} onChange={(e) => setNftContract(e.target.value)} placeholder="NFT Contract Address" className="w-full bg-white/10 border border-white/20 rounded px-4 py-2" />
              <div className="grid grid-cols-2 gap-4">
                <input type="number" value={tokenId} onChange={(e) => setTokenId(e.target.value)} placeholder="Token ID" className="bg-white/10 border border-white/20 rounded px-4 py-2" />
                <input type="number" value={price} onChange={(e) => setPrice(e.target.value)} placeholder="Price (STX)" className="bg-white/10 border border-white/20 rounded px-4 py-2" />
              </div>
              <button onClick={createListing} disabled={loading} className="w-full bg-pink-600 hover:bg-pink-700 py-3 rounded-lg disabled:opacity-50">
                {loading ? "Creating..." : "List NFT"}
              </button>
            </div>

            <div className="bg-white/10 p-6 rounded-lg space-y-4">
              <h2 className="text-xl font-bold">Buy NFT</h2>
              <input type="number" value={listingId} onChange={(e) => setListingId(e.target.value)} placeholder="Listing ID" className="w-full bg-white/10 border border-white/20 rounded px-4 py-2" />
              <button onClick={buyListing} disabled={loading} className="w-full bg-green-600 hover:bg-green-700 py-3 rounded-lg disabled:opacity-50">
                {loading ? "Buying..." : "Buy Now"}
              </button>
            </div>

            {txId && (
              <div className="bg-green-500/20 border border-green-500 p-4 rounded-lg">
                <a href={`https://explorer.hiro.so/txid/${txId}?chain=mainnet`} target="_blank" className="text-green-300 underline break-all">View TX</a>
              </div>
            )}
          </div>
        )}
      </div>
    </main>
  );
}
