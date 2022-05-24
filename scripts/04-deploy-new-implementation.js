const prompt = require('prompt');
const hre = require("hardhat");
const { type2Transaction } = require('./utils.js');

async function main() {
  console.log("New implementation deployment.");
  console.log("Specify the implementation contract's name");
  prompt.start();
  const addresses = require("../test/test-config.js");

  const {implName} = await prompt.get(['implName']);

  const ImplContract = artifacts.require(implName);
  const impl = await type2Transaction(ImplContract.new);

  console.log("Deployment complete. Implementation deployed at:", impl.creates);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
