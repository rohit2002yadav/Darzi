
// This file defines the Mongoose schema for the 'Fabric' collection in the MongoDB database.
// A schema is a blueprint that defines the structure of documents within a collection,
// including the fields, their data types, and any validation rules.

import mongoose from "mongoose";

// Create a new Mongoose schema for fabrics.
const fabricSchema = new mongoose.Schema({
  // A reference to the User who owns this fabric. This creates a link between
  // the Fabric collection and the User collection. It's required for every fabric.
  tailorId: { 
    type: mongoose.Schema.Types.ObjectId, // The data type is a MongoDB Object ID.
    ref: "User", // This specifies that the ID refers to a document in the 'User' collection.
    required: true // This field must be present for every fabric document.
  },
  // The name of the fabric (e.g., "Bombay Rayon Blue Striped").
  name: String,
  // The type of material (e.g., "Cotton", "Silk", "Linen").
  type: String,
  // The color of the fabric (e.g., "Royal Blue").
  color: String,
  // The price of the fabric per meter.
  pricePerMeter: Number,
  // The quantity of the fabric available in stock, measured in meters.
  availableQty: Number,
  // A URL pointing to an image of the fabric.
  imageUrl: String,
  // A boolean flag to indicate if the fabric is currently in stock and available for selection.
  // It defaults to `true`, meaning new fabrics are available by default.
  isAvailable: { type: Boolean, default: true }
});

// Compiles the schema into a Mongoose model named 'Fabric'.
// A model is a constructor compiled from a schema definition. An instance of a model
// represents a single MongoDB document and can be saved to or retrieved from the database.
// Exporting it makes it available to be used in other parts of the application (e.g., in the routes).
export default mongoose.model("Fabric", fabricSchema);
