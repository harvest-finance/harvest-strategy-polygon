async function getFeeData() {
  const feeData = await ethers.provider.getFeeData();
  feeData.maxPriorityFeePerGas = 35e9;
  if (feeData.maxFeePerGas < feeData.maxPriorityFeePerGas) {
    feeData.maxFeePerGas = Number(feeData.maxFeePerGas) + Number(feeData.maxPriorityFeePerGas);
  }
  if (feeData.maxFeePerGas > 1000e9) {
    feeData.maxFeePerGas = 1000e9;
  }
  if (feeData.maxFeePerGas / 6 > 35e9) {
    feeData.maxPriorityFeePerGas = Math.round(feeData.maxFeePerGas / 6);
    if (feeData.maxPriorityFeePerGas > 100e9) {
      feeData.maxPriorityFeePerGas = 100e9;
    }
  }
  return feeData;
}

async function getSigner() {
  const signer = await ethers.provider.getSigner();
  return signer;
}

async function type2Transaction(callFunction, ...params) {
  const signer = await getSigner();
  const feeData = await getFeeData();
  const unsignedTx = await callFunction.request(...params);
  const tx = await signer.sendTransaction({
    from: unsignedTx.from,
    to: unsignedTx.to,
    data: unsignedTx.data,
    maxFeePerGas: feeData.maxFeePerGas,
    maxPriorityFeePerGas: feeData.maxPriorityFeePerGas,
    gasLimit: 5e6
  });
  await tx.wait();
  return tx;
}

module.exports = {
  type2Transaction,
};
