import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config({ path: ".env" });

const MUMBAI_API_URL = process.env.MUMBAI_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    mumbai: {
      url: MUMBAI_API_URL || "",
      accounts: PRIVATE_KEY != undefined ? [PRIVATE_KEY] : []
    },
  }
};

export default config;

