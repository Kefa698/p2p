// Import the required libraries and the OrderBook contract
const { expect } = require("chai")
const { ethers } = require("hardhat")

describe("OrderBook", function () {
    let orderBook
    let owner
    let seller
    let buyer

    // Deploy a new instance of the OrderBook contract before each test
    beforeEach(async function () {
        ;[owner, seller, buyer] = await ethers.getSigners()
        const OrderBook = await ethers.getContractFactory("OrderBook")
        orderBook = await OrderBook.deploy()
        await orderBook.deployed()
    })

    // Test the placeOrder function
    describe("placeOrder", function () {
        it("should place a new order", async function () {
            const amount = ethers.utils.parseEther("1")
            const orderId = await orderBook.placeOrder(seller.address, amount)
            expect(orderId).to.exist
        })
        it("should not allow a buyer and seller to be the same", async function () {
            const amount = ethers.utils.parseEther("1")
            await expect(orderBook.placeOrder(owner.address, amount)).to.be.revertedWith(
                "Buyer and seller cannot be the same."
            )
        })
        it("should not allow an amount of zero to be placed", async function () {
            const amount = ethers.utils.parseEther("0")
            await expect(orderBook.placeOrder(seller.address, amount)).to.be.revertedWith(
                "Amount must be greater than zero."
            )
        })
    })
})
