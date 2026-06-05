const nodemailer = require('nodemailer');

// Email configuration from environment variables
const EMAIL_HOST = process.env.EMAIL_HOST || 'smtp.gmail.com';
const EMAIL_PORT = process.env.EMAIL_PORT || 587;
const EMAIL_USER = process.env.EMAIL_USER;
const EMAIL_PASSWORD = process.env.EMAIL_PASSWORD;
const EMAIL_FROM = process.env.EMAIL_FROM || EMAIL_USER;
const APP_URL = process.env.APP_URL || 'https://lassi.cloud';
const APP_DOWNLOAD_URL = process.env.APP_DOWNLOAD_URL || `${APP_URL}/downloads/trailer-manager.apk`;

// Create transporter
const transporter = nodemailer.createTransporter({
  host: EMAIL_HOST,
  port: EMAIL_PORT,
  secure: EMAIL_PORT === 465, // true for 465, false for other ports
  auth: EMAIL_USER && EMAIL_PASSWORD ? {
    user: EMAIL_USER,
    pass: EMAIL_PASSWORD,
  } : undefined,
});

/**
 * Send welcome email to new user with app download link
 */
async function sendWelcomeEmail(userEmail, userName, temporaryPassword) {
  // Skip if email is not configured
  if (!EMAIL_USER || !EMAIL_PASSWORD) {
    console.warn('Email not configured - skipping welcome email');
    return false;
  }

  const mailOptions = {
    from: `Trailer Manager <${EMAIL_FROM}>`,
    to: userEmail,
    subject: 'Welcome to Trailer Manager - Download the App',
    html: `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body {
            font-family: Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 600px;
            margin: 0 auto;
            padding: 20px;
          }
          .header {
            background-color: #2196F3;
            color: white;
            padding: 20px;
            text-align: center;
            border-radius: 5px 5px 0 0;
          }
          .content {
            background-color: #f9f9f9;
            padding: 30px;
            border: 1px solid #ddd;
            border-top: none;
            border-radius: 0 0 5px 5px;
          }
          .credentials {
            background-color: #fff;
            padding: 15px;
            border-left: 4px solid #2196F3;
            margin: 20px 0;
          }
          .download-button {
            display: inline-block;
            background-color: #4CAF50;
            color: white;
            padding: 15px 30px;
            text-decoration: none;
            border-radius: 5px;
            margin: 20px 0;
            font-weight: bold;
          }
          .footer {
            text-align: center;
            margin-top: 20px;
            font-size: 12px;
            color: #666;
          }
        </style>
      </head>
      <body>
        <div class="header">
          <h1>🚛 Welcome to Trailer Manager</h1>
        </div>
        <div class="content">
          <p>Hello ${userName},</p>

          <p>Your account has been created! You can now access the Trailer Manager app to track and manage trailers.</p>

          <div class="credentials">
            <h3>Your Login Credentials:</h3>
            <p><strong>Email:</strong> ${userEmail}</p>
            <p><strong>Temporary Password:</strong> ${temporaryPassword}</p>
            <p><em>Please change your password after your first login.</em></p>
          </div>

          <h3>Download the App:</h3>
          <p>Click the button below to download the Trailer Manager app for Android:</p>

          <a href="${APP_DOWNLOAD_URL}" class="download-button">📱 Download Android App</a>

          <p>Or copy this link: <br><a href="${APP_DOWNLOAD_URL}">${APP_DOWNLOAD_URL}</a></p>

          <h3>Installation Instructions:</h3>
          <ol>
            <li>Download the APK file to your Android device</li>
            <li>Open the downloaded file</li>
            <li>If prompted, allow installation from unknown sources</li>
            <li>Follow the installation prompts</li>
            <li>Open the app and log in with your credentials</li>
          </ol>

          <p>If you have any questions or need assistance, please contact your administrator.</p>

          <p>Best regards,<br>Trailer Manager Team</p>
        </div>
        <div class="footer">
          <p>This is an automated message. Please do not reply to this email.</p>
        </div>
      </body>
      </html>
    `,
    text: `
Welcome to Trailer Manager!

Hello ${userName},

Your account has been created! You can now access the Trailer Manager app to track and manage trailers.

Your Login Credentials:
Email: ${userEmail}
Temporary Password: ${temporaryPassword}
Please change your password after your first login.

Download the App:
${APP_DOWNLOAD_URL}

Installation Instructions:
1. Download the APK file to your Android device
2. Open the downloaded file
3. If prompted, allow installation from unknown sources
4. Follow the installation prompts
5. Open the app and log in with your credentials

If you have any questions or need assistance, please contact your administrator.

Best regards,
Trailer Manager Team
    `,
  };

  try {
    await transporter.sendMail(mailOptions);
    console.log(`Welcome email sent to ${userEmail}`);
    return true;
  } catch (error) {
    console.error('Error sending welcome email:', error);
    return false;
  }
}

module.exports = {
  sendWelcomeEmail,
};
