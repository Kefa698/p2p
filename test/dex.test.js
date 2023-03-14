const { expect } = require("chai")
const { ethers } = require("hardhat")

// Start the test suite
describe("OrderBook", function () {
    let orderBook, admin, seller, escrow
    beforeEach(async function () {
        // Deploy the contract and assign the admin
        ;[admin, seller, escrow] = await ethers.getSigners()
        const OrderBook = await ethers.getContractFactory("OrderBook")
        orderBook = await OrderBook.deploy()
        await orderBook.deployed()
    })

    // Test the fundAccount function
    describe("fundAccount", function () {
        it("should add funds to the sender's account", async function () {
            const sender = admin.address
            const amount = ethers.utils.parseEther("1")
            const initialFunds = await orderBook.Funds(sender)
            await orderBook.fundAccount(sender, { value: amount })
            const newFunds = await orderBook.Funds(sender)
            expect(newFunds).to.equal(initialFunds.add(amount))
        })
    })

    // Test the setEscrowFee function
    describe("setEscrowFee", function () {
        it("should set the escrow fee for the sender", async function () {
            const fee = 50
            await orderBook.setEscrowFee(fee)
            const sender = admin.address
            const expectedFee = fee
            const actualFee = await orderBook.escrowFee(sender)
            expect(actualFee).to.equal(expectedFee)
        })

        it("should revert if the fee is outside the allowed range", async function () {
            const fee = 200
            await expect(orderBook.setEscrowFee(fee)).to.be.revertedWith("revert")
        })
    })
})
