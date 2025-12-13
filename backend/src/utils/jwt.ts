import jwt, { JwtPayload, Secret } from 'jsonwebtoken';
import { randomUUID } from 'crypto';
import { UserRole } from '../config/constants';

export interface TokenPayload {
  userId: number;
  email: string;
  role: UserRole;
}

export interface DecodedToken extends TokenPayload, JwtPayload {}

const ACCESS_TOKEN_SECRET: Secret = process.env.JWT_SECRET || 'your-secret-key';
const REFRESH_TOKEN_SECRET: Secret = process.env.JWT_REFRESH_SECRET || 'your-refresh-secret-key';
const ACCESS_TOKEN_EXPIRES = (process.env.JWT_EXPIRES_IN || '15m') as jwt.SignOptions['expiresIn'];
const REFRESH_TOKEN_EXPIRES = (process.env.JWT_REFRESH_EXPIRES_IN || '7d') as jwt.SignOptions['expiresIn'];

/**
 * Generate access token
 */
export const generateAccessToken = (payload: TokenPayload): string => {
  return jwt.sign(payload, ACCESS_TOKEN_SECRET, {
    expiresIn: ACCESS_TOKEN_EXPIRES,
  });
};

/**
 * Generate refresh token with unique jti (JWT ID) for token rotation
 */
export const generateRefreshToken = (payload: TokenPayload): string => {
  return jwt.sign(
    { ...payload, jti: randomUUID() },
    REFRESH_TOKEN_SECRET,
    { expiresIn: REFRESH_TOKEN_EXPIRES }
  );
};

/**
 * Verify access token
 */
export const verifyAccessToken = (token: string): DecodedToken | null => {
  try {
    return jwt.verify(token, ACCESS_TOKEN_SECRET) as DecodedToken;
  } catch {
    return null;
  }
};

/**
 * Verify refresh token
 */
export const verifyRefreshToken = (token: string): DecodedToken | null => {
  try {
    return jwt.verify(token, REFRESH_TOKEN_SECRET) as DecodedToken;
  } catch {
    return null;
  }
};

/**
 * Generate both tokens
 */
export const generateTokenPair = (
  payload: TokenPayload
): { accessToken: string; refreshToken: string } => {
  return {
    accessToken: generateAccessToken(payload),
    refreshToken: generateRefreshToken(payload),
  };
};

/**
 * Decode token without verification (for debugging)
 */
export const decodeToken = (token: string): DecodedToken | null => {
  try {
    return jwt.decode(token) as DecodedToken;
  } catch {
    return null;
  }
};

/**
 * Get token expiration time
 */
export const getTokenExpiration = (token: string): Date | null => {
  const decoded = decodeToken(token);
  if (decoded?.exp) {
    return new Date(decoded.exp * 1000);
  }
  return null;
};

