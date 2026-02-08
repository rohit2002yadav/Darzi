
// This is the main entry point for the Node.js server.
// It initializes the application, connects to the database, sets up middleware,
// and mounts all the API routes.

// --- Environment Variable Configuration ---
// This section configures the `dotenv` package to load environment variables from a .env file.
// This is crucial for keeping sensitive information like database connection strings
// and API keys out of the source code.
import dotenv from "dotenv";
import path from "path";
import { fileURLToPath } from "url"; // A helper to convert a file URL to a file path.

// These lines are necessary boilerplate when using ES Modules (`import/export` syntax) in Node.js
// to get the equivalent of the `__dirname` variable that is available in CommonJS modules.
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
// Construct the absolute path to the .env file.
const envPath = path.resolve(__dirname, ".env");
// Load the environment variables from the specified path.
dotenv.config({ path: envPath });

// --- Core Imports ---
import express from "express"; // The main framework for building the web server and APIs.
import mongoose from "mongoose"; // An Object Data Modeling (ODM) library for MongoDB and Node.js.
import cors from "cors"; // A middleware to enable Cross-Origin Resource Sharing, allowing the frontend to make requests to this backend.

// --- Route Imports ---
// Import all the different route handlers from the /routes directory.
import authRoutes from "./routes/authRoutes.js";
import orderRoutes from "./routes/orderRoutes.js";
import fabricRoutes from "./routes/fabricRoutes.js"; // This was missing from your live server

// --- Express App Initialization ---
const app = express();

// --- Middleware Setup ---
// `app.use()` is how you apply middleware to your application.

// `cors()`: Enables CORS for all routes. This allows your Flutter app (running on a different "origin")
// to make API requests to this server without being blocked by browser security policies.
app.use(cors());
// `express.json()`: This is a built-in middleware that parses incoming requests with JSON payloads.
// It makes the JSON data available on the `req.body` property.
app.use(express.json());

// --- API Route Mounting ---
// This section connects the imported route handlers to specific URL prefixes.
app.use("/api/auth", authRoutes); // All routes defined in authRoutes.js will be prefixed with /api/auth
app.use("/api/orders", orderRoutes); // All routes defined in orderRoutes.js will be prefixed with /api/orders
app.use("/api/fabrics", fabricRoutes); // This line makes the fabric API work

// --- Root Route / Health Check ---
// This defines a simple GET route for the server's root URL.
// It's often used as a "health check" to confirm that the server is running.
app.get("/", (req, res) => {
  res.json({ message: "Darzi backend is running ✅" });
});

// --- Database Connection & Server Start ---
// This block handles the connection to the MongoDB database using the URI from environment variables.
mongoose
  .connect(process.env.MONGO_URI) // Attempt to connect to the database.
  .then(() => {
    // This `.then()` block is executed if the connection is successful.
    console.log("✅ MongoDB Connected");
    // Define the port the server will listen on, using the environment variable or defaulting to 10000.
    const PORT = process.env.PORT || 10000;
    // Start the Express server, making it listen for incoming requests on the specified port.
    app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
  })
  .catch((err) => console.error("❌ MongoDB Error:", err)); // This `.catch()` block is executed if the connection fails.

