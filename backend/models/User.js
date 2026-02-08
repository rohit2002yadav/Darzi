
// This file defines the Mongoose schema for the 'User' collection in the MongoDB database.
// It is a flexible schema designed to handle two distinct roles: "customer" and "tailor".
// The schema includes core user information, authentication details, role-specific data,
// and a geospatial index for location-based queries.

import mongoose from "mongoose";

// Create a new Mongoose schema for users.
const userSchema = new mongoose.Schema(
  {
    // --- Core User Information ---
    name: { type: String, required: true },
    // `unique: true` ensures that no two users can register with the same email or phone number.
    email: { type: String, required: true, unique: true },
    phone: { type: String, required: true, unique: true },
    password: { type: String, required: true }, // The user's hashed password.
    role: { type: String, enum: ["customer", "tailor"], required: true }, // The role must be one of the specified values.

    // --- Account Status & Verification ---
    isVerified: { type: Boolean, default: false }, // Tracks if the user has completed OTP verification.
    status: { type: String, enum: ["ACTIVE", "INACTIVE", "SUSPENDED"], default: "ACTIVE" },

    // --- One-Time Password (OTP) Fields ---
    // These fields are used temporarily for account verification and password resets.
    otp: { type: String },
    otpExpires: { type: Date }, // A timestamp to determine when the OTP is no longer valid.

    // --- Geospatial Location Data (for Tailors) ---
    // This field stores the tailor's location in a GeoJSON "Point" format.
    // It's crucial for finding nearby tailors.
    location: {
      type: {
        type: String,
        enum: ["Point"], // The type must be 'Point' for geospatial queries.
        default: "Point",
      },
      coordinates: {
        type: [Number], // The coordinates are stored in [longitude, latitude] order.
      },
    },

    // --- Customer-Specific Details ---
    // This is a nested object that holds information relevant only to users with the "customer" role.
    customerDetails: {
      address: { type: String },
      city: { type: String },
      state: { type: String },
      landmark: { type: String },
      pin: { type: String },
      // `measurementProfiles` is an array of saved measurement profiles for the customer.
      measurementProfiles: [
        {
          profileName: { type: String, required: true },
          garmentType: { type: String, required: true }, // e.g., "Shirt", "Pant"
          measurements: { type: mongoose.Schema.Types.Mixed }, // A flexible map for measurements.
        },
      ],
    },

    // --- Tailor-Specific Details ---
    // A comprehensive nested object for all information relevant to users with the "tailor" role.
    tailorDetails: {
      shopName: { type: String },
      experience: { type: Number },
      specializations: { type: [String] }, // e.g., ["Shirts", "Blouses"]
      workingDays: { type: [String] }, // e.g., ["Monday", "Tuesday"]
      workingHours: { open: String, close: String },
      pricing: { basePrice: Number, alterationPrice: Number },
      homePickup: { type: Boolean, default: false }, // Does the tailor offer home pickup?
      measurementVisit: { type: Boolean, default: false }, // Does the tailor visit for measurements?
      providesFabric: { type: Boolean, default: false }, // Does the tailor sell their own fabric?
      address: { type: String },
      city: { type: String },
      state: { type: String },
      zipCode: { type: String },
      landmark: { type: String },
      profilePictureUrl: { type: String }, // URL for the tailor's profile photo.
      shopImageUrl: { type: String }, // URL for a photo of the tailor's shop.
      workPhotoUrls: { type: [String] }, // A list of URLs for photos of their work.
      rating: { type: Number, default: 4.5 }, // The tailor's average rating, with a default value.
    },
  },
  {
    // Mongoose option to automatically add `createdAt` and `updatedAt` fields.
    timestamps: true 
  }
);

// --- Geospatial Index ---
// This creates a `2dsphere` index on the `location` field. This is a special index that
// allows MongoDB to perform efficient geospatial queries, such as finding all tailors
// within a certain radius of a given point.
userSchema.index({ location: "2dsphere" });

// Compiles the schema into a Mongoose model named 'User' and exports it.
export default mongoose.model("User", userSchema);
