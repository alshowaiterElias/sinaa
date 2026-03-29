import nodemailer from 'nodemailer';
import { logger } from '../utils/logger';

// Create reusable transporter using Gmail SMTP
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: process.env.SMTP_SECURE === 'true',
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

const FROM_ADDRESS = process.env.SMTP_FROM || `"4All App" <${process.env.SMTP_USER}>`;

/**
 * Branded email wrapper
 */
function wrapInTemplate(content: string): string {
  return `
    <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; background: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 4px 20px rgba(0,0,0,0.08);">
      <!-- Header -->
      <div style="background: linear-gradient(135deg, #D4A574 0%, #C4956A 100%); padding: 32px 24px; text-align: center;">
        <h1 style="color: #ffffff; margin: 0; font-size: 28px; font-weight: 700; letter-spacing: 1px;">4Alls</h1>
        <p style="color: rgba(255,255,255,0.85); margin: 4px 0 0; font-size: 14px;">4All App</p>
      </div>
      <!-- Body -->
      <div style="padding: 32px 24px;">
        ${content}
      </div>
      <!-- Footer -->
      <div style="background: #f8f9fa; padding: 20px 24px; text-align: center; border-top: 1px solid #eee;">
        <p style="color: #999; font-size: 12px; margin: 0;">
          هذا البريد الإلكتروني تم إرساله تلقائياً من تطبيق 4All. لا ترد على هذه الرسالة.
        </p>
        <p style="color: #bbb; font-size: 11px; margin: 8px 0 0;">
          © ${new Date().getFullYear()} 4All. All rights reserved.
        </p>
      </div>
    </div>
    `;
}

/**
 * Send verification email with 6-digit code
 */
export const sendVerificationEmail = async (to: string, token: string): Promise<boolean> => {
  try {
    const content = `
        <div style="text-align: center;">
          <h2 style="color: #333; margin: 0 0 12px; font-size: 22px;">تأكيد بريدك الإلكتروني</h2>
          <p style="color: #666; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">
            مرحباً بك في 4All! للمتابعة، يرجى إدخال رمز التحقق التالي في التطبيق:
          </p>
          <div style="background: linear-gradient(135deg, #f8f4f0 0%, #f0e8e0 100%); border: 2px dashed #D4A574; border-radius: 12px; padding: 20px; margin: 0 auto 24px; max-width: 280px;">
            <span style="font-size: 36px; font-weight: 700; letter-spacing: 10px; color: #C4956A; font-family: monospace;">${token}</span>
          </div>
          <p style="color: #999; font-size: 13px; margin: 0;">
            رمز التحقق صالح لمدة 24 ساعة. إذا لم تقم بإنشاء حساب، يمكنك تجاهل هذا البريد.
          </p>
        </div>
        `;

    logger.info(`Sending verification email to ${to}`);

    const info = await transporter.sendMail({
      from: FROM_ADDRESS,
      to,
      subject: 'تأكيد بريدك الإلكتروني - 4All | Verify your email - 4All',
      text: `رمز التحقق الخاص بك هو: ${token}\nYour verification code is: ${token}`,
      html: wrapInTemplate(content),
    });

    logger.info(`Verification email sent to ${to}`, { messageId: info.messageId });
    return true;
  } catch (error) {
    logger.error(`Error sending verification email to ${to}`, { error });
    return false;
  }
};

/**
 * Send password reset email with 6-digit code
 */
export const sendPasswordResetEmail = async (to: string, token: string): Promise<boolean> => {
  try {
    const content = `
        <div style="text-align: center;">
          <div style="width: 64px; height: 64px; margin: 0 auto 16px; background: #FFF3E0; border-radius: 50%; display: flex; align-items: center; justify-content: center;">
            <span style="font-size: 28px;">🔐</span>
          </div>
          <h2 style="color: #333; margin: 0 0 12px; font-size: 22px;">إعادة تعيين كلمة المرور</h2>
          <p style="color: #666; font-size: 15px; line-height: 1.6; margin: 0 0 24px;">
            لقد تلقينا طلباً لإعادة تعيين كلمة المرور الخاصة بك. أدخل الرمز التالي في التطبيق:
          </p>
          <div style="background: linear-gradient(135deg, #FFF8E1 0%, #FFF3E0 100%); border: 2px dashed #FF9800; border-radius: 12px; padding: 20px; margin: 0 auto 24px; max-width: 280px;">
            <span style="font-size: 36px; font-weight: 700; letter-spacing: 10px; color: #E65100; font-family: monospace;">${token}</span>
          </div>
          <p style="color: #999; font-size: 13px; margin: 0 0 8px;">
            رمز إعادة التعيين صالح لمدة ساعة واحدة فقط.
          </p>
          <p style="color: #d32f2f; font-size: 13px; margin: 0;">
            إذا لم تطلب إعادة تعيين كلمة المرور، يرجى تجاهل هذا البريد.
          </p>
        </div>
        `;

    logger.info(`Sending password reset email to ${to}`);

    const info = await transporter.sendMail({
      from: FROM_ADDRESS,
      to,
      subject: 'إعادة تعيين كلمة المرور - 4All | Password Reset - 4All',
      text: `رمز إعادة تعيين كلمة المرور: ${token}\nYour password reset code is: ${token}`,
      html: wrapInTemplate(content),
    });

    logger.info(`Password reset email sent to ${to}`, { messageId: info.messageId });
    return true;
  } catch (error) {
    logger.error(`Error sending password reset email to ${to}`, { error });
    return false;
  }
};
