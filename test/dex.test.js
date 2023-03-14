const { expect } = require("chai")
const { ethers } = require("hardhat")

// Start the test suite
describe("OrderBook", function () {
    let orderBook, admin, seller, escrow, buyer, owner, transactionId
    beforeEach(async function () {
        // Deploy the contract and assign the admin

        const accounts = await ethers.getSigners()
        admin = accounts[0]
        buyer = accounts[1]
        seller = accounts[2]
        escrow = accounts[3]
        owner = accounts[4]

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
    describe("newEscrowTransaction", function () {
        it("should create a new escrow transaction and update the databases", async function () {
            const value = ethers.utils.parseEther("1")
            const notes = ethers.utils.formatBytes32String("Test notes")

            // Make the transaction from the buyer to the contract
            await orderBook
                .connect(buyer)
                .newEscrowTransaction(seller.address, escrow.address, notes, {
                    value: ethers.utils.parseEther("0.5"),
                })

            // Check that the buyer's escrow database has been updated
            const buyerEscrow = await orderBook.buyerDatabase(buyer.address, 0)
            expect(buyerEscrow.buyer).to.equal(buyer.address)
            expect(buyerEscrow.seller).to.equal(seller.address)
            expect(buyerEscrow.escrow_agent).to.equal(escrow.address)

            expect(buyerEscrow.notes).to.equal(ethers.utils.formatBytes32String("Test notes"))

            // // Check that the seller's transaction database has been updated
            const sellerTransaction = await orderBook.sellerDatabase(seller.address, 0)
            expect(sellerTransaction.buyer).to.equal(buyer.address)
            expect(sellerTransaction.buyer_nounce).to.equal(0)

            // // Check that the escrow's transaction database has been updated
            const escrowTransaction = await orderBook.escrowDatabase(escrow.address, 0)
            expect(escrowTransaction.buyer).to.equal(buyer.address)
            expect(escrowTransaction.buyer_nounce).to.equal(0)
        })
    })
    describe("getNumTransactions", function () {
        it("should return number of transactions", async function () {
            const value = ethers.utils.parseEther("1")
            const notes = ethers.utils.formatBytes32String("Test notes")

            // Make the transaction from the buyer to the contract
            await orderBook
                .connect(buyer)
                .newEscrowTransaction(seller.address, escrow.address, notes, {
                    value: ethers.utils.parseEther("1"),
                })
            // Check the number of transactions for the seller
            const numBuyerTransactions = await orderBook.getNumTransactions(seller.address, 1)
            expect(numBuyerTransactions).to.equal(1)
        })
    })
    describe("release funds to the seller", function () {
        it("should release funds", async function () {
            const value = ethers.utils.parseEther("1")
            const notes = ethers.utils.formatBytes32String("Test notes")

            // Make the transaction from the buyer to the contract
            await orderBook
                .connect(buyer)
                .newEscrowTransaction(seller.address, escrow.address, notes, {
                    value: ethers.utils.parseEther("5"),
                })
            // Check the number of transactions for the seller
            const numBuyerTransactions = await orderBook.getNumTransactions(seller.address, 1)
            expect(numBuyerTransactions).to.equal(1)
            transactionId = (await orderBook.getNumTransactions(buyer.address, 0)).toNumber() - 1

            const sellerBalance = await ethers.provider.getBalance(seller.address)

            expect(sellerBalance).to.equal("10000000000000000000000")
        })
    })
})
