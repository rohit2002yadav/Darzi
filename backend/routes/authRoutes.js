// This file defines all the API routes related to user authentication and management.
// It handles user registration (signup), login, password reset, and tailor discovery.

import express from "express";
import bcrypt from "bcryptjs"; // For hashing and comparing passwords securely.
import jwt from "jsonwebtoken"; // For creating and verifying JSON Web Tokens for session management.
import User from "../models/User.js"; // The Mongoose model for the User schema.
import { sendOtpEmail } from "../utils/mailer.js"; // A utility function to send OTP emails.

const router = express.Router();

// Use the JWT_SECRET from environment variables, with a fallback for local development.
const JWT_SECRET = process.env.JWT_SECRET || "your_super_secret_key_darzi";

// Helper function to generate a JWT for a given user ID.
// The token expires in 30 days.
const generateToken = (id) => {
  return jwt.sign({ id }, JWT_SECRET, { expiresIn: "30d" });
};

// --- GET ALL ACTIVE TAILORS ---
// A simple endpoint to retrieve all users with the 'tailor' role who are currently active.
// This is useful for admin panels or as a fallback if location services are unavailable.
router.get("/tailors", async (req, res) => {
  try {
    // Find all users who are tailors and active. Exclude sensitive fields from the result.
    const tailors = await User.find({ role: "tailor", status: "ACTIVE" }, { password: 0, otp: 0, otpExpires: 0 });
    res.status(200).json(tailors);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- GET NEARBY TAILORS (GEOSPATIAL SEARCH) ---
// A complex endpoint to find nearby tailors using MongoDB's geospatial queries.
// It can also filter tailors based on their capabilities (e.g., specializations).
router.get("/tailors/nearby", async (req, res) => {
  try {
    const { lat, lng, garmentType, isTailorProvidingFabric } = req.query;
    if (!lat || !lng) return res.status(400).json({ error: "Lat/Lng required" });

    // Set a search radius, ensuring it's within a reasonable range (1km to 5km).
    const radius = Math.min(parseFloat(req.query.radius) || 1, 5);
    const maxDist = radius * 1000; // Convert kilometers to meters for the geoNear query.

    // The aggregation pipeline is a multi-stage process to query and transform data.
    let pipeline = [
      {
        // The $geoNear stage must be the first stage. It finds documents near a specified point.
        $geoNear: {
          near: { type: "Point", coordinates: [parseFloat(lng), parseFloat(lat)] },
          distanceField: "distance", // Adds a 'distance' field (in meters) to each result.
          maxDistance: maxDist, // Filters results to be within the specified radius.
          query: { role: "tailor", status: "ACTIVE" }, // Additional filter for the documents.
          spherical: true, // Use spherical geometry for distance calculation.
          key: "location" // Specifies the geospatial index field to use.
        }
      }
    ];

    // Dynamically add more filtering stages to the pipeline based on query parameters.
    let matchConditions = {};
    if (garmentType) {
      matchConditions["tailorDetails.specializations"] = garmentType;
    }
    if (isTailorProvidingFabric === 'true') {
      matchConditions["tailorDetails.providesFabric"] = true;
    }

    if (Object.keys(matchConditions).length > 0) {
      pipeline.push({ $match: matchConditions }); // Add the $match stage if there are conditions.
    }

    // The $project stage reshapes the output documents, selecting fields and transforming them.
    pipeline.push({
      $project: {
        _id: 1,
        name: 1,
        distance: { $divide: ["$distance", 1000] }, // Convert distance from meters to kilometers.
        tailorDetails: 1,
      }
    });

    const tailors = await User.aggregate(pipeline);

    res.status(200).json({
      radius: radius,
      count: tailors.length,
      tailors: tailors
    });

  } catch (err) {
    console.error("❌ GeoNear Error:", err.message);
    res.status(500).json({ error: err.message });
  }
});

// --- USER LOGIN ---
// Handles the login process for a user with either email or phone number.
router.post("/login", async (req, res) => {
  try {
    const { email, phone, password } = req.body;
    // Find a user that matches either the provided email or phone number.
    const user = await User.findOne({ $or: [{ email }, { phone }] });
    if (!user) return res.status(400).json({ error: "User not found" });
    
    // Check if the user has completed the OTP verification step.
    if (!user.isVerified) return res.status(403).json({ error: "Please verify your email first.", needsVerification: true });
    
    // If a password was provided, compare it with the hashed password in the database.
    if (password) {
        const isValid = await bcrypt.compare(password, user.password);
        if (!isValid) return res.status(400).json({ error: "Invalid password" });
    }
    
    // On successful login, return user data and a JWT.
    res.status(200).json({ 
      message: "Login successful", 
      user,
      token: generateToken(user._id)
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- SEND OTP FOR SIGNUP ---
// This is the first step of the registration process. It creates/updates a user record
// and sends an OTP to their email for verification.
router.post("/send-otp", async (req, res) => {
  try {
    const { email, phone, name, password, role } = req.body;

    if (!email || !phone || !name) {
      return res.status(400).json({ error: "Name, Email, and Phone are required." });
    }

    // Check if a user already exists and is verified with this email or phone.
    const existingUser = await User.findOne({ $or: [{ email }, { phone }] });
    if (existingUser && existingUser.isVerified) {
      return res.status(400).json({ error: "Account already exists with this email or phone." });
    }

    // Generate a random 6-digit OTP.
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Prepare the data to be saved. This includes all user details from the request body.
    let updateData = {
      ...req.body,
      otp,
      otpExpires: Date.now() + 10 * 60 * 1000, // Set OTP expiry to 10 minutes from now.
      isVerified: false,
      status: "ACTIVE" // User is active but not verified.
    };

    // If a password is provided, hash it before saving.
    if (password) {
        updateData.password = await bcrypt.hash(password, 10);
    }

    let user;
    // If there is no existing (unverified) user, create a new one.
    if (!existingUser) {
      user = new User(updateData);
    } else {
      // If an unverified user exists, update their record with the new data.
      user = Object.assign(existingUser, updateData);
    }

    await user.save(); // Save the new or updated user to the database.
    await sendOtpEmail(email, otp); // Send the OTP to the user's email.
    res.status(200).json({ message: "OTP sent successfully" });
  } catch (err) {
    console.error("Signup error:", err);
    res.status(500).json({ error: err.message });
  }
});

// --- VERIFY OTP & COMPLETE REGISTRATION ---
// This is the second step of registration. The user provides the OTP they received.
router.post("/verify-and-register", async (req, res) => {
  try {
    const { email, otp } = req.body;
    // Find the unverified user with the matching email.
    const user = await User.findOne({ email, isVerified: false });
    
    // Check if the user exists and if the OTP is correct and has not expired.
    if (!user || user.otp !== otp || user.otpExpires < Date.now()) {
      return res.status(400).json({ error: "Invalid or expired OTP." });
    }

    // If OTP is valid, mark the user as verified and clear the OTP fields.
    user.isVerified = true;
    user.otp = undefined;
    user.otpExpires = undefined;
    user.status = "ACTIVE"; 
    await user.save();
    
    // Return a success message, the user data, and a login token.
    res.status(201).json({ 
      message: "Registration successful!",
      user,
      token: generateToken(user._id)
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- FORGOT PASSWORD (STEP 1: SEND OTP) ---
// Finds a user by email and sends them an OTP for password reset.
router.post("/forgot-password", async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ error: "Email is required" });

    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ error: "No user found with this email." });

    // Generate and save a new OTP for the user.
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    user.otp = otp;
    user.otpExpires = Date.now() + 10 * 60 * 1000; // 10 minute expiry.
    
    await user.save();
    await sendOtpEmail(email, otp);
    res.status(200).json({ message: "A reset OTP has been sent to your email." });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// --- RESET PASSWORD (STEP 2: VERIFY OTP & UPDATE) ---
// Verifies the reset OTP and updates the user's password with the new one provided.
router.post("/reset-password", async (req, res) => {
  try {
    const { email, otp, newPassword } = req.body;
    if (!email || !otp || !newPassword) return res.status(400).json({ error: "All fields are required" });

    const user = await User.findOne({ email });
    // Check if the user exists and if the OTP is valid and not expired.
    if (!user || user.otp !== otp || user.otpExpires < Date.now()) {
      return res.status(400).json({ error: "Invalid or expired OTP." });
    }

    // If valid, hash the new password and update the user record.
    user.password = await bcrypt.hash(newPassword, 10);
    // Clear the OTP fields.
    user.otp = undefined;
    user.otpExpires = undefined;
    await user.save();
    res.status(200).json({ message: "Password updated successfully!" });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default router;
