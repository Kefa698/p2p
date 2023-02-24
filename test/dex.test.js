const { expect } = require("chai")

describe("OrderBook", function () {
    let orderBook
    let owner
    let seller
    let buyer

    beforeEach(async function () {
        const OrderBook = await ethers.getContractFactory("OrderBook")
        orderBook = await OrderBook.deploy()
        await orderBook.deployed()

        ;[owner, seller, buyer] = await ethers.getSigners()
    })

    it("should place an order", async function () {
        const amount = ethers.utils.parseEther("1")
        const orderId = await orderBook.placeOrder(seller.address, amount)

        const order = await orderBook.getOrder(orderId)
        expect(order.buyer).to.equal(buyer.address)
        expect(order.seller).to.equal(seller.address)
        expect(order.amount).to.equal(amount)
        expect(order.escrowed).to.equal(false)
        expect(order.buyerConfirmed).to.equal(false)
        expect(order.sellerConfirmed).to.equal(false)

        const buyerOrders = await orderBook.getOrdersByBuyer(buyer.address)
        expect(buyerOrders).to.deep.equal([orderId])

        const sellerOrders = await orderBook.getOrdersBySeller(seller.address)
        expect(sellerOrders).to.deep.equal([orderId])

        const escrowedTokens = await orderBook.getEscrowedTokens(seller.address, orderId)
        expect(escrowedTokens).to.equal(0)

        const events = await orderBook.queryFilter("OrderPlaced", orderId)
        expect(events.length).to.equal(1)
        expect(events[0].args.orderId).to.equal(orderId)
        expect(events[0].args.buyer).to.equal(buyer.address)
        expect(events[0].args.seller).to.equal(seller.address)
        expect(events[0].args.amount).to.equal(amount)
    })
})
