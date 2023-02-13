// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract P2POrderMatching is Ownable {
    using SafeMath for uint256;

    // Mapping of order IDs to order details
    mapping(uint256 => Order) public orders;
    // Array of order IDs
    uint256[] public orderIds;
    // Event for new order creation
    event NewOrder(uint256 orderId);
    // Event for order confirmation
    event OrderConfirmed(uint256 orderId);
    // Event for dispute initiation
    event DisputeInitiated(uint256 orderId);
    // Event for dispute resolution
    event DisputeResolved(uint256 orderId);

    // Order struct
    struct Order {
        uint256 orderId;
        address seller;
        address buyer;
        address tokenAddress;
        uint256 tokenAmount;
        bool orderConfirmed;
        bool fundsReceived;
        bool disputeInitiated;
        bool disputeResolved;
    }

    // Function to list a new order
    function listOrder(
        address _seller,
        address _buyer,
        uint256 _tokenAmount,
        address _tokenAddress
    ) public {
        // Create a new order
        Order memory order = Order({
            orderId: orderIds.length + 1,
            seller: _seller,
            buyer: _buyer,
            tokenAmount: _tokenAmount,
            tokenAddress: _tokenAddress,
            orderConfirmed: false,
            fundsReceived: false,
            disputeInitiated: false,
            disputeResolved: false
        });

        // Add the order to the orders mapping
        orders[order.orderId] = order;
        // Add the order ID to the order IDs array
        orderIds.push(order.orderId);
        // Emit the NewOrder event
        emit NewOrder(order.orderId);
    }

    // Function for the buyer to confirm the order
    function confirmOrder(uint256 orderId) public {
        // Retrieve the order details
        Order storage order = orders[orderId];
        // Ensure the caller is the buyer
        require(msg.sender == order.buyer, "Only the buyer can confirm the order.");
        // Set the orderConfirmed flag
        order.orderConfirmed = true;
        // Update the orders mapping
        orders[orderId] = order;
        // Emit the OrderConfirmed event
        emit OrderConfirmed(orderId);
    }

    // Function for the buyer or seller to initiate a dispute
    function initiateDispute(uint256 orderId) public {
        // Retrieve the order details
        Order storage order = orders[orderId];
        // Ensure the caller is either the buyer or the seller
        require(
            msg.sender == order.buyer || msg.sender == order.seller,
            "Only the buyer or seller can initiate a dispute."
        );
        // Set the disputeInitiated flag
        order.disputeInitiated = true;
        // Update the orders mapping
        orders[orderId] = order;
        // Emit the DisputeInitiated event
        emit DisputeInitiated(orderId);
    }

    // Function for the owner of the contract to resolve a dispute
    function resolveDispute(uint256 orderId) public onlyOwner {
        // Retrieve the order details
        Order storage order = orders[orderId];
        // Ensure a dispute has been initiated
        require(order.disputeInitiated, "No dispute has been initiated for this order.");
        // Set the disputeResolved flag
        order.disputeResolved = true;
        // Update the orders mapping
        orders[orderId] = order;
        // Emit the DisputeResolved event
        emit DisputeResolved(orderId);
    }

    // Function to handle token transfers
    function transferToken(uint256 orderId, address _to) public {
        // Retrieve the order details
        Order storage order = orders[orderId];
        // Ensure the order has been confirmed
        require(order.orderConfirmed, "The order has not been confirmed yet.");
        // Ensure the dispute has not been initiated or resolved
        require(
            !order.disputeInitiated && !order.disputeResolved,
            "The dispute has not been resolved yet."
        );
        // Transfer the token
        ERC20(order.tokenAddress).transfer(_to, order.tokenAmount);
    }
}
