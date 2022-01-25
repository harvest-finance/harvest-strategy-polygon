require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-ethers");
require('hardhat-deploy');

const secret = require('./dev-keys.json');
require("solidity-coverage");

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
      accounts: {
        mnemonic: secret.mnemonic,
      },
      chainId: 137,
      forking: {
        url: `https://polygon-mainnet.g.alchemy.com/v2/${secret.alchemyKey}`,
        blockNumber: 24152600, // <-- edit here
      },
    },
    mainnet: {
      url: `https://polygon-mainnet.g.alchemy.com/v2/${secret.alchemyKey}`,
      accounts: {
        mnemonic: secret.mnemonic,
      },
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  namedAccounts: {
    deployer: 0,
  },
  mocha: {
    timeout: 2000000
  },
  etherscan: {
    apiKey: secret.etherscanAPI,
  },
};
