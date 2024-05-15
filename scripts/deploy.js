async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  const SwapContract = await ethers.getContractFactory("SwapContract");
  const contract = await SwapContract.deploy("0x2b6B40e6395b25Fb8401262F69e3ecec2a774A06", 5);

  console.log("Contract deployed at:", await contract.getAddress());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
