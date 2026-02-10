# 🧵 Darzi – On-Demand Tailoring Platform

Darzi is a full-stack application that connects **customers** with **local tailors** for stitching, alterations, and fabric services.  
Customers can place tailoring orders from home, and tailors can manage orders digitally.

This repository is a **monorepo** containing both:
- Backend (Node.js / Express)
- Frontend (Flutter)

---

## 📂 Project Structure


---

## ⚙️ Tech Stack

### Backend
- Node.js
- Express.js
- MongoDB
- JWT Authentication
- REST APIs
- Hosted on **Render**

### Frontend
- Flutter (Android / Web)
- Dart
- REST API integration
- Location & Image Picker support

---

## 👥 User Roles

### 👤 Customer
- Sign up / Login with OTP
- Select tailor
- Add measurements
- Place orders
- Track order status
- View order history

### ✂️ Tailor
- Sign up with shop details & location
- Accept / Reject orders
- View customer measurements
- Update order status
- Manage fabrics & pricing

---

## 🔄 Order Flow (Simple)

1. Customer selects garment & tailor
2. Customer adds measurements
3. Order is placed
4. Tailor receives the order
5. Tailor accepts and starts stitching
6. Order status updates (In Progress → Completed)

---

## 🚀 How to Run Locally

### Backend
```bash
cd backend
npm install
npm start OR npx nodemon server.js

### Frontend
```bash
cd loginpage
flutter pub get
flutter run

