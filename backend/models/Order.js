
// This file defines the Mongoose schema for the 'Order' collection in the MongoDB database.
// This is one of the most important models in the application, as it encapsulates all the
// information related to a single customer order, from customer and tailor details to
// measurements, payment, and status.

import mongoose from "mongoose";

// Create a new Mongoose schema for orders.
const orderSchema = new mongoose.Schema(
  {
    // --- Customer & Tailor Details ---
    customerName: { type: String, required: true, trim: true }, // `trim: true` removes whitespace from the start and end.
    customerPhone: { type: String, required: true },
    customerEmail: { type: String }, // Optional, as users can sign up with a phone number.
    tailorId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true }, // A reference to the tailor (a User document).
    tailorName: { type: String, required: true },
    tailorPhone: { type: String }, // The tailor's phone number, denormalized for easy access by the customer.
    tailorAddress: { type: String }, // The tailor's shop address, denormalized for easy access.

    // --- Garment & Measurement Details ---
    garmentType: { type: String, required: true }, // The primary type of garment (e.g., "Shirt").
    items: { type: [String], default: [] }, // A list of items in the order.
    measurements: { type: mongoose.Schema.Types.Mixed, default: {} }, // A flexible field to store key-value pairs of measurements.
    
    // --- Fabric Details ---
    // This section is a nested object that can store details for fabric provided
    // by either the customer or the tailor, making it very flexible.
    isTailorProvidingFabric: { type: Boolean, default: false },
    fabricDetails: {
      // Customer-provided details
      type: { type: String },
      length: { type: String },
      color: { type: String },
      photoPath: { type: String },
      // Tailor-provided details
      fabricId: { type: mongoose.Schema.Types.ObjectId, ref: "Fabric" }, // Reference to a document in the Fabric collection.
      name: { type: String },
      pricePerMeter: { type: Number },
      quantity: { type: Number },
    },

    // --- Logistics & Handover Details ---
    handoverType: { type: String, enum: ["pickup", "drop"], required: true }, // The handover method.
    pickup: { // Details for when the handover type is "pickup".
      address: String,
      date: String, // The scheduled date for pickup.
      timeSlot: String, // The chosen time slot for pickup.
    },
    
    // --- Payment Details ---
    payment: {
      totalAmount: { type: Number, required: true },
      depositAmount: { type: Number, required: true }, // The initial deposit required.
      remainingAmount: { type: Number, required: true },
      depositMode: { type: String, enum: ["CASH", "ONLINE"] }, // How the deposit was paid.
      depositStatus: { type: String, enum: ["PENDING", "PAID"], default: "PENDING" },
      paymentStatus: { // The overall payment status of the entire order.
        type: String, 
        enum: ["PENDING_DEPOSIT", "DEPOSIT_PAID", "PAID"], 
        default: "PENDING_DEPOSIT" 
      },
    },

    // --- Order Status & Workflow ---
    status: { // The current stage of the order in the workflow.
      type: String,
      enum: [
        "PLACED", // Customer has placed the order, waiting for tailor action.
        "ACCEPTED", // Tailor has accepted the order.
        "CUTTING", // Work in progress: cutting stage.
        "STITCHING", // Work in progress: stitching stage.
        "FINISHING", // Work in progress: finishing stage.
        "READY", // Order is complete and ready for delivery.
        "DELIVERED", // Order has been successfully delivered to the customer.
        "REJECTED", // Tailor has rejected the order.
        "CANCELLED", // Customer has cancelled the order.
      ],
      default: "PLACED", // New orders default to this status.
    },
    // A simple OTP used for verifying the final delivery to the customer.
    deliveryOtp: { type: String },
  },
  {
    // Mongoose option to automatically add `createdAt` and `updatedAt` fields to the schema.
    // This is extremely useful for tracking when documents are created and modified.
    timestamps: true 
  }
);

// Compiles the schema into a Mongoose model named 'Order' and exports it.
export default mongoose.model("Order", orderSchema);
