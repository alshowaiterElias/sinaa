import nodemailer from 'nodemailer';
import { logger } from '../utils/logger';

// Create reusable transporter object using the default SMTP transport
const transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.ethereal.email',
    port: parseInt(process.env.SMTP_PORT || '587'),
    secure: process.env.SMTP_SECURE === 'true', // true for 465, false for other ports
    auth: {
        user: process.env.SMTP_USER || 'ethereal_user',
        pass: process.env.SMTP_PASS || 'ethereal_pass',
    },
});

/**
 * Send verification email
 * @param to Recipient email
 * @param token Verification token
 */
export const sendVerificationEmail = async (to: string, token: string) => {
    try {
        const verificationUrl = `https://sinaa-app.com/verify-email?token=${token}`; // Replace with actual deep link or web URL

        // For mobile deep linking, it might be better to send just the code or a link that opens the app
        // Assuming we want a code for simplicity in mobile entry, or a link if we have deep linking set up.
        // Let's assume we send a link that the user can click.

        logger.info(`Attempting to send verification email to ${to}`);

        const info = await transporter.sendMail({
            from: '"Sinaa App" <no-reply@sinaa-app.com>', // sender address
            to: to, // list of receivers
            subject: 'Verify your email address', // Subject line
            text: `Please verify your email by clicking the following link: ${verificationUrl}\n\nOr enter this code in the app: ${token}`, // plain text body
            html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
          <h2>Welcome to Sinaa!</h2>
          <p>Please verify your email address to continue.</p>
          <p>Click the button below to verify:</p>
          <a href="${verificationUrl}" style="display: inline-block; padding: 10px 20px; background-color: #007bff; color: #ffffff; text-decoration: none; border-radius: 5px;">Verify Email</a>
          <p>Or enter this code in the app:</p>
          <h3 style="background-color: #f8f9fa; padding: 10px; text-align: center; letter-spacing: 5px;">${token}</h3>
          <p>If you didn't create an account, please ignore this email.</p>
        </div>
      `, // html body
        });

        logger.info(`Verification email sent to ${to}`, { messageId: info.messageId });

        // Preview only available when sending through an Ethereal account
        if (process.env.NODE_ENV !== 'production' && !process.env.SMTP_HOST) {
            logger.info(`Preview URL: ${nodemailer.getTestMessageUrl(info)}`);
        }

        return true;
    } catch (error) {
        logger.error(`Error sending verification email to ${to}`, { error });
        return false;
    }
};
