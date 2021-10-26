# Polygon Chain: Harvest Strategy Development

This [Hardhat](https://hardhat.org/) environment is configured to use Mainnet fork by default and provides templates and utilities for strategy development and testing.

## Installation

1. Run `npm install` to install all the dependencies.
2. Sign up on [Alchemy](https://dashboard.alchemyapi.io/signup/). We recommend using Alchemy over Infura to allow for a reproducible
Mainnet fork testing environment as well as efficiency due to caching.
3. Create a file `dev-keys.json`:
  ```
    {
      "alchemyKey": "<your-alchemy-key>"
    }
  ```

## Run

All tests are located under the `test` folder.

1. Run `npx hardhat test [test file location]`: `npx hardhat test ./test/curve/aave.js` (if for some reason the NodeJS heap runs out of memory, make sure to explicitly increase its size via `export NODE_OPTIONS=--max_old_space_size=4096`). This will produce the following output:
  ```
  Polygon Mainnet Curve Aave
Impersonating...
0xf00dD244228F51547f0563e60bCa65a30FBF5f7f
Fetching Underlying at:  0xE7a24EF0C5e95Ffb0f6684b813A78F2a3AD7D171
New Vault Deployed:  0xF8ce90c2710713552fb564869694B2505Bfc0846
Strategy Deployed:  0xDDa0648FA8c9cD593416EC37089C2a2E6060B45c
Strategy and vault added to Controller.
    Happy path
loop  0
old shareprice:  1000000000000000000
new shareprice:  1000000000000000000
growth:  1
loop  1
old shareprice:  1000000000000000000
new shareprice:  1000141138681462160
growth:  1.000141138681462
loop  2
old shareprice:  1000141138681462160
new shareprice:  1000327782939361291
growth:  1.000186617918892
loop  3
old shareprice:  1000327782939361291
new shareprice:  1000514426794411531
growth:  1.0001865826964256
loop  4
old shareprice:  1000514426794411531
new shareprice:  1000701097344949064
growth:  1.0001865745715788
loop  5
old shareprice:  1000701097344949064
new shareprice:  1000878677026348228
growth:  1.0001774552679819
loop  6
old shareprice:  1000878677026348228
new shareprice:  1001019907056855214
growth:  1.0001411060438679
loop  7
old shareprice:  1001019907056855214
new shareprice:  1001161152484596161
growth:  1.0001411015173078
loop  8
old shareprice:  1001161152484596161
new shareprice:  1001302413308521684
growth:  1.0001410969888065
loop  9
old shareprice:  1001302413308521684
new shareprice:  1001443692715028091
growth:  1.000141095641665
earned!
APR: 11.570408862519965 %
APY: 12.264303010549993 %
      √ Farmer should earn money (45307ms)


  1 passing (1m)
  ```

## Develop

Under `contracts/strategies`, there are plenty of examples to choose from in the repository already, therefore, creating a strategy is no longer a complicated task. Copy-pasting existing strategies with minor modifications is acceptable.

Under `contracts/base`, there are existing base interfaces and contracts that can speed up development.
Base contracts currently exist for developing SNX and MasterChef-based strategies.

Note that the Universal Liquidator will not be available on BSC until a later stage of this project.

## Contribute

When ready, open a pull request with the following information:
1. Instructions on how to run the test and at which block number
2. A **mainnet fork test output** (like the one above in the README) clearly showing the increases of share price
3. Info about the protocol, including:
   - Live farm page(s)
   - GitHub link(s)
   - Etherscan link(s)
   - Start/end dates for rewards
   - Any limitations (e.g., maximum pool size)
   - Current pool sizes used for liquidation (to make sure they are not too shallow)

   The first few items can be omitted for well-known protocols (such as `curve.fi`).

5. A description of **potential value** for Harvest: why should your strategy be live? High APYs, decent pool sizes, longevity of rewards, well-secured protocols, high-potential collaborations, etc.

A more extensive checklist for assessing protocols and farming opportunities can be found [here](https://www.notion.so/harvestfinance/Farm-ops-check-list-7cd2e0d9da364252ac465cb8a176f0e0)

## Deployment

If your pull request is merged and given a green light for deployment, the Harvest team will take care of on-chain deployment.
