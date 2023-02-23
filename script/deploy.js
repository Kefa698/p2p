const { ethers } = require("hardhat");

async function main() {
  const OrderBook = await ethers.getContractFactory("OrderBook");
  const orderBook = await OrderBook.deploy();

  await orderBook.deployed();

  console.log("OrderBook deployed to:", orderBook.address);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
