
// This file defines the API routes for creating, retrieving, and managing orders.
// It provides a comprehensive set of endpoints for both customers and tailors
// to interact with the order workflow, from creation to completion.

import express from "express";
import Order from "../models/Order.js"; // The Mongoose model for the Order schema.

const router = express.Router();

// A map defining the linear progression of order statuses.
// This is used by the /update-status endpoint to automatically advance an order to the next stage.
const STATUS_FLOW = {
  ACCEPTED: "CUTTING",
  CUTTING: "STITCHING",
  STITCHING: "FINISHING",
  FINISHING: "READY",
  READY: "DELIVERED", // Simplified final step
};

// @desc    Create a new order
// @route   POST /api/orders
// @access  Public (should be protected in a real app)
// This route handles the creation of a new order. It takes all the order details
// from the request body, generates a random 4-digit OTP for delivery verification,
// and saves the new order to the database.
router.post("/", async (req, res) => {
  try {
    // Generate a simple 4-digit OTP. In a real app, this should be more secure.
    const deliveryOtp = Math.floor(1000 + Math.random() * 9000).toString();
    const order = new Order({ ...req.body, deliveryOtp });
    const saved = await order.save();
    res.status(201).json(saved); // Returns the newly created order with a 201 Created status.
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// @desc    Get all orders for a specific customer
// @route   GET /api/orders/customer
// @access  Public (should be protected)
// This route fetches all orders associated with a customer, identified by their phone number.
// The results are sorted by creation date in descending order (newest first).
router.get("/customer", async (req, res) => {
  const { phone } = req.query;
  if (!phone) return res.status(400).json({ error: "Phone required" });
  const orders = await Order.find({ customerPhone: phone }).sort({ createdAt: -1 });
  res.json(orders);
});

// @desc    Get orders for a specific tailor, filtered by status
// @route   GET /api/orders/tailor
// @access  Public (should be protected)
// This route is used by the tailor's dashboard to fetch orders based on their status.
// It supports filtering for "ONGOING", "PLACED", or any other specific status.
router.get("/tailor", async (req, res) => {
  const { tailorId, status } = req.query;
  if (!tailorId) return res.status(400).json({ error: "tailorId required" });

  let query = { tailorId };
  if (status === "ONGOING") {
    // For "ONGOING", it fetches orders that are in any of the active work stages.
    query.status = { $in: ["ACCEPTED", "CUTTING", "STITCHING", "FINISHING", "READY"] };
  } else if (status === "PLACED") { // This handles the "New" tab for tailors.
    query.status = "PLACED";
  } else if (status) {
    // For any other status (e.g., "DELIVERED"), it uses an exact match.
    query.status = status;
  }
  // The results are sorted by the last update time, so the most recently changed orders appear first.
  const orders = await Order.find(query).sort({ updatedAt: -1 });
  res.json(orders);
});

// @desc    Get simple analytics for a tailor
// @route   GET /api/orders/analytics
// @access  Public (should be protected)
// This route provides basic analytics, such as counting the number of orders
// created for a specific tailor on the current day.
router.get("/analytics", async (req, res) => {
  try {
    const { tailorId } = req.query;
    if (!tailorId) return res.status(400).json({ error: "tailorId required" });
    // Counts documents for the tailorId created after the beginning of the current day.
    const todayCount = await Order.countDocuments({ 
      tailorId, 
      createdAt: { $gte: new Date().setHours(0, 0, 0, 0) } 
    });
    res.json({ todayOrders: todayCount });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// @desc    Confirm that the initial deposit has been paid for an order
// @route   POST /api/orders/:id/confirm-deposit
// @access  Private (Tailor only)
// This action is performed by the tailor. It updates the order's payment status
// and automatically moves the order status to "ACCEPTED".
router.post("/:id/confirm-deposit", async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ error: "Order not found" });

    order.payment.depositStatus = "PAID";
    order.status = "ACCEPTED";
    
    const updatedOrder = await order.save();
    res.status(200).json(updatedOrder);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// @desc    Accept a new order
// @route   POST /api/orders/:id/accept
// @access  Private (Tailor only)
// Allows a tailor to accept a newly placed order, changing its status to "ACCEPTED".
router.post("/:id/accept", async (req, res) => {
  try {
    // `findByIdAndUpdate` is an efficient way to find and update a document in one step.
    // `{ new: true }` ensures that the updated document is returned.
    const order = await Order.findByIdAndUpdate(req.params.id, { status: "ACCEPTED" }, { new: true });
    if (!order) return res.status(404).json({ error: "Order not found" });
    res.json(order);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// @desc    Reject a new order
// @route   POST /api/orders/:id/reject
// @access  Private (Tailor only)
// Allows a tailor to reject a newly placed order, changing its status to "REJECTED".
router.post("/:id/reject", async (req, res) => {
  try {
    const order = await Order.findByIdAndUpdate(req.params.id, { status: "REJECTED" }, { new: true });
    if (!order) return res.status(404).json({ error: "Order not found" });
    res.json(order);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// @desc    Update the status of an ongoing order to the next step
// @route   POST /api/orders/:id/update-status
// @access  Private (Tailor only)
// This is a key endpoint for the tailor's workflow. It uses the `STATUS_FLOW` map
// to automatically advance the order to its next logical status.
router.post("/:id/update-status", async (req, res) => {
  try {
    const order = await Order.findById(req.params.id);
    if (!order) return res.status(404).json({ error: "Order not found" });

    const next = STATUS_FLOW[order.status]; // Look up the next status in the flow.
    if (!next) return res.status(400).json({ error: "No further status updates available" });

    order.status = next;
    await order.save();
    res.json(order);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
