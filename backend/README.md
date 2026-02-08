# Darzi Server (Backend)

This is the backend server for the **Darzi Application**, an on-demand tailoring service platform.  
The backend is built using **Node.js**, **Express**, and **MongoDB** and provides APIs for authentication, orders, and email OTP verification.

---

## 🛠️ Tech Stack

- Node.js
- Express.js
- MongoDB (Mongoose)
- SendGrid (Email OTP)
- JWT (Authentication)

---

## 📂 Project Structure

darzi_server/
├── server.js # Main server entry point
├── package.json
├── .env # Environment variables (not committed)
├── routes/
│ ├── authRoutes.js # Authentication & OTP routes
│ └── orderRoutes.js # Order related APIs
├── models/
│ ├── User.js # User schema
│ └── Order.js # Order schema
├── utils/
│ └── mailer.js # SendGrid email helper
└── README.md