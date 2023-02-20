// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title OrderBook
 * @dev A smart contract for managing an order book with an escrow.
 */
contract OrderBook {
    // Struct representing an order
    struct Order {
        address payable buyer; // Address of the buyer
        address payable seller; // Address of the seller
        uint256 amount; // Amount of tokens being sold
        bool escrowed; // Whether tokens have been locked in escrow
        bool buyerConfirmed; // Whether the buyer has confirmed receipt of tokens
        bool sellerConfirmed; // Whether the seller has confirmed receipt of payment
    }

    mapping(uint256 => Order) private orders; // Mapping of order IDs to orders
    mapping(address => uint256[]) private ordersByBuyer; // Mapping of buyer addresses to their order IDs
    mapping(address => uint256[]) private ordersBySeller; // Mapping of seller addresses to their order IDs
    mapping(address => mapping(uint256 => uint256)) private escrowedTokensBySeller; // Mapping of seller addresses and order IDs to the amount of tokens escrowed

    // Events
    event OrderPlaced(
        uint256 indexed orderId,
        address indexed buyer,
        address indexed seller,
        uint256 amount
    );
    event PaymentConfirmed(uint256 indexed orderId, address indexed buyer, address indexed seller);
    event ReceiptConfirmed(uint256 indexed orderId, address indexed buyer, address indexed seller);

    // Place an order
    function placeOrder(address payable _seller, uint256 _amount) public returns (uint256) {
        require(_seller != msg.sender, "Buyer and seller cannot be the same.");
        require(_amount > 0, "Amount must be greater than zero.");
        uint256 orderId = uint256(
            keccak256(abi.encodePacked(msg.sender, _seller, _amount, block.timestamp))
        ); // Generate a unique order ID
        Order storage order = orders[orderId];
        order.buyer = payable(msg.sender);
        order.seller = _seller;
        order.amount = _amount;
        order.escrowed = false;
        order.buyerConfirmed = false;
        order.sellerConfirmed = false;
        ordersByBuyer[msg.sender].push(orderId);
        ordersBySeller[_seller].push(orderId);
        emit OrderPlaced(orderId, msg.sender, _seller, _amount);
        return orderId;
    }

    // Confirm payment from buyer
    function confirmPayment(uint256 _orderId) public payable {
        Order storage order = orders[_orderId];
        require(order.buyer == msg.sender, "Only buyer can confirm payment.");
        require(!order.escrowed, "Tokens already escrowed.");
        require(msg.value == order.amount, "Incorrect amount sent.");
        escrowedTokensBySeller[order.seller][_orderId] = order.amount; // Lock tokens in escrow
        order.escrowed = true;
        emit PaymentConfirmed(_orderId, msg.sender, order.seller);
    }

    // Confirm receipt of tokens by buyer
    function confirmReceipt(uint256 _orderId) public {
        Order storage order = orders[_orderId];
        require(order.buyer == msg.sender, "Only buyer can confirm receipt.");
        require(!order.buyerConfirmed, "Buyer already confirmed receipt.");
        require(order.escrowed, "Tokens not yet escrowed.");
        require(!order.sellerConfirmed, "Seller has not yet confirmed receipt of payment.");
        order.buyerConfirmed = true;
        if (order.buyerConfirmed && order.sellerConfirmed) {
            escrowedTokensBySeller[order.seller][_orderId] = 0; // Reset amount of tokens in escrow
            order.buyer.transfer(escrowedTokensBySeller[order.seller][_orderId]); // Transfer tokens from escrow to buyer
            emit ReceiptConfirmed(_orderId, msg.sender, order.seller);
        }
    }

    // Confirm receipt of payment by seller
    function confirmPaymentReceipt(uint256 _orderId) public {
        Order storage order = orders[_orderId];
        require(order.seller == msg.sender, "Only seller can confirm payment receipt.");
        require(order.escrowed, "Tokens not yet escrowed.");
        require(!order.sellerConfirmed, "Seller already confirmed payment receipt.");
        order.sellerConfirmed = true;
        if (order.buyerConfirmed && order.sellerConfirmed) {
            escrowedTokensBySeller[order.seller][_orderId] = 0; // Reset amount of tokens in escrow
            order.seller.transfer(order.amount); // Transfer payment to seller
            emit ReceiptConfirmed(_orderId, order.buyer, msg.sender);
        }
    }

    // Get order details by order ID
    function getOrder(
        uint256 _orderId
    )
        public
        view
        returns (
            address payable buyer,
            address seller,
            uint256 amount,
            bool escrowed,
            bool buyerConfirmed,
            bool sellerConfirmed
        )
    {
        Order storage order = orders[_orderId];
        return (
            order.buyer,
            order.seller,
            order.amount,
            order.escrowed,
            order.buyerConfirmed,
            order.sellerConfirmed
        );
    }

    // Get order IDs by buyer address
    function getOrdersByBuyer(address _buyer) public view returns (uint256[] memory) {
        return ordersByBuyer[_buyer];
    }

    // Get order IDs by seller address
    function getOrdersBySeller(address _seller) public view returns (uint256[] memory) {
        return ordersBySeller[_seller];
    }

    // Get amount of escrowed tokens for an order
    function getEscrowedTokens(uint256 _orderId) public view returns (uint256) {
        Order storage order = orders[_orderId];
        return escrowedTokensBySeller[order.seller][_orderId];
    }
}
