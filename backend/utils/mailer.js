
// This file contains the configuration and utility function for sending emails
// using the SendGrid API. It's specifically used for sending One-Time Passwords (OTPs)
// for user verification and password resets.

import sgMail from "@sendgrid/mail"; // Imports the official SendGrid mailer library.

// --- API Key Setup ---
// It's crucial to set the API key before making any requests.
// The key is loaded from environment variables for security, preventing it from being hardcoded.
if (process.env.SENDGRID_API_KEY) {
  sgMail.setApiKey(process.env.SENDGRID_API_KEY);
  // A log message to confirm that the SendGrid service is configured and ready.
  console.log("✅ SENDGRID_API_KEY is loaded!"); 
} else {
  // If the API key is not found in the environment variables, log an error.
  // This is a critical failure, as no emails can be sent without the key.
  console.error("❌ SENDGRID_API_KEY is missing in .env");
}

/**
 * Sends a stylized OTP email to a user.
 * @param {string} to The recipient's email address.
 * @param {string} otp The 6-digit One-Time Password to be sent.
 * @returns {Promise<boolean>} A promise that resolves to `true` if the email was sent successfully, and `false` otherwise.
 */
export const sendOtpEmail = async (to, otp) => {
  // A try...catch block is used to gracefully handle any errors that might occur during the API call.
  try {
    // The `msg` object defines all the components of the email.
    const msg = {
      to, // The recipient's email address.
      from: process.env.VERIFIED_EMAIL, // The sender's email address, which must be a verified sender in your SendGrid account.
      subject: "Your Darzi OTP Verification Code", // The subject line of the email.
      // The `html` property contains the body of the email, styled with inline CSS for maximum compatibility across email clients.
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
          <h2 style="color: #6a1b9a;">Darzi App Verification</h2>
          <p>Hello,</p>
          <p>Your one-time password (OTP) for account verification is:</p>
          <h1 style="color: #6a1b9a; letter-spacing: 5px; background: #f4f4f4; padding: 10px; display: inline-block;">${otp}</h1>
          <p>This code will expire in <b>10 minutes</b>.</p>
          <p>If you did not request this code, please ignore this email.</p>
          <hr style="border: none; border-top: 1px solid #eee; margin-top: 20px;" />
          <p style="font-size: 12px; color: #888;">Powered by Darzi Direct</p>
        </div>
      `,
    };

    // `sgMail.send()` is an asynchronous function that sends the email message via the SendGrid API.
    await sgMail.send(msg);
    // Log a success message to the console for debugging purposes.
    console.log("✅ OTP email successfully sent to:", to);
    return true; // Indicate success.
  } catch (error) {
    // If an error occurs (e.g., network issue, invalid API key, invalid email address), it will be caught here.
    console.error(
      "❌ SendGrid Mailer Error:",
      // Log the detailed error response from SendGrid if available, otherwise log the general error message.
      error.response?.body || error.message
    );
    return false; // Indicate failure.
  }
};
