async function getFeeData() {
  const feeData = await ethers.provider.getFeeData();
  feeData.maxPriorityFeePerGas = feeData.maxFeePerGas/2;
  if (feeData.maxFeePerGas > 1000e9) {
    feeData.maxFeePerGas = 1000e9;
  }
  if (feeData.maxPriorityFeePerGas > 30e9) {
    feeData.maxPriorityFeePerGas = 30e9;
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
    gasLimit: 7e6
  });
  await tx.wait();
  return tx;
}

module.exports = {
  type2Transaction,
};
