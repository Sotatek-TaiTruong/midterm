import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    sepolia: {
      url: "https://eth-sepolia.g.alchemy.com/v2/Ej7ORh2WM0m8l9ADrh6n4QC9KB4Jb_XJ",
      accounts: ["4dc6f039a25c1f3ada965ce89a41d7bbaea0ee28e7a904741ea2020a09b0c3fb"]
  }
  },
};

export default config;
