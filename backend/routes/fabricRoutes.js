
// This file defines the API routes for managing fabric inventory.
// It provides endpoints for tailors to create, read, update, and delete (CRUD)
// their available fabric items. It also includes an endpoint for customers
// to view the fabrics available for a specific tailor.

import express from "express";
import Fabric from "../models/Fabric.js"; // The Mongoose model for the Fabric schema.
// import { protect } from "../middleware/authMiddleware.js"; // Optional: Can be added later to secure routes.

const router = express.Router();

// @desc    Get all fabrics for a specific tailor
// @route   GET /api/fabrics/tailor/:tailorId
// @access  Public
// This route allows anyone to view the available fabrics for a given tailor.
// It finds all fabrics that match the `tailorId` from the URL parameters and are marked as `isAvailable`.
router.get("/tailor/:tailorId", async (req, res) => {
  try {
    const fabrics = await Fabric.find({ tailorId: req.params.tailorId, isAvailable: true });
    res.json(fabrics);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// @desc    Create a new fabric item for a tailor
// @route   POST /api/fabrics
// @access  Private (Tailor only)
// This route allows a tailor to add a new fabric to their inventory.
// It takes fabric details from the request body, creates a new `Fabric` instance,
// and saves it to the database.
router.post("/", async (req, res) => {
  // In a real, secure application, the tailor's ID would be extracted from a
  // JWT (JSON Web Token) after the user has been authenticated, not passed in the body.
  // const { tailorId } = req.user;
  const { tailorId, name, type, color, pricePerMeter, availableQty, imageUrl } = req.body;

  // Basic validation to ensure required fields are present.
  if (!tailorId || !name || !type || !pricePerMeter || !imageUrl) {
    return res.status(400).json({ message: "Please fill all required fields" });
  }

  // Create a new instance of the Fabric model.
  const fabric = new Fabric({
    tailorId,
    name,
    type,
    color,
    pricePerMeter,
    availableQty,
    imageUrl,
  });

  try {
    // Save the new fabric document to the database.
    const createdFabric = await fabric.save();
    // Return the newly created fabric with a 201 Created status code.
    res.status(201).json(createdFabric);
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// @desc    Update a fabric item
// @route   PUT /api/fabrics/:id
// @access  Private (Tailor only)
// This route allows a tailor to update the details of an existing fabric item.
// It finds the fabric by its ID and updates its fields with the new data from the request body.
router.put("/:id", async (req, res) => {
  const { name, type, color, pricePerMeter, availableQty, isAvailable } = req.body;

  try {
    const fabric = await Fabric.findById(req.params.id);

    if (fabric) {
      // TODO: Add a security check here to ensure that the user making the request
      // is the actual owner of this fabric item before allowing an update.
      
      // Update the fabric fields only if new values are provided in the request body.
      // This prevents accidentally overwriting existing data with null.
      fabric.name = name || fabric.name;
      fabric.type = type || fabric.type;
      fabric.color = color || fabric.color;
      fabric.pricePerMeter = pricePerMeter || fabric.pricePerMeter;
      fabric.availableQty = availableQty || fabric.availableQty;
      // Special handling for boolean `isAvailable` to allow setting it to `false`.
      fabric.isAvailable = isAvailable !== undefined ? isAvailable : fabric.isAvailable;

      const updatedFabric = await fabric.save();
      res.json(updatedFabric);
    } else {
      res.status(404).json({ message: "Fabric not found" });
    }
  } catch (err) {
    res.status(400).json({ message: err.message });
  }
});

// @desc    Delete a fabric item
// @route   DELETE /api/fabrics/:id
// @access  Private (Tailor only)
// This route allows a tailor to delete a fabric item from their inventory.
// It finds the fabric by its ID and removes it from the database.
router.delete("/:id", async (req, res) => {
  try {
    const fabric = await Fabric.findById(req.params.id);

    if (fabric) {
      // TODO: Add a security check to ensure only the owner can delete.
      await fabric.remove(); // `remove()` is deprecated; `deleteOne()` is preferred.
      res.json({ message: "Fabric removed" });
    } else {
      res.status(404).json({ message: "Fabric not found" });
    }
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
