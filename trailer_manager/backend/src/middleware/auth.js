const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-this-in-production';

/**
 * Middleware to verify JWT token and attach user to request
 */
const authenticate = (req, res, next) => {
  try {
    // Get token from Authorization header
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      return res.status(401).json({
        error: 'Authentication required',
        message: 'No authorization header provided',
      });
    }

    // Bearer token format: "Bearer <token>"
    const parts = authHeader.split(' ');

    if (parts.length !== 2 || parts[0] !== 'Bearer') {
      return res.status(401).json({
        error: 'Authentication required',
        message: 'Invalid authorization header format. Use: Bearer <token>',
      });
    }

    const token = parts[1];

    // Verify token
    const decoded = jwt.verify(token, JWT_SECRET);

    // Attach user info to request
    req.user = {
      userId: decoded.userId,
      email: decoded.email,
      role: decoded.role,
    };

    next();
  } catch (error) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({
        error: 'Authentication failed',
        message: 'Invalid token',
      });
    }

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Authentication failed',
        message: 'Token expired',
      });
    }

    return res.status(500).json({
      error: 'Server error',
      message: 'Authentication error',
    });
  }
};

/**
 * Optional authentication - attaches user if token is present, but doesn't require it
 */
const optionalAuthenticate = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader) {
      // No token provided, continue without user
      return next();
    }

    const parts = authHeader.split(' ');

    if (parts.length === 2 && parts[0] === 'Bearer') {
      const token = parts[1];

      try {
        const decoded = jwt.verify(token, JWT_SECRET);
        req.user = {
          userId: decoded.userId,
          email: decoded.email,
          role: decoded.role,
        };
      } catch (error) {
        // Invalid token, but we don't fail - just continue without user
        console.warn('Optional auth: Invalid token provided');
      }
    }

    next();
  } catch (error) {
    next();
  }
};

/**
 * Middleware to require admin role
 * Must be used after authenticate middleware
 */
const requireAdmin = async (req, res, next) => {
  try {
    const pool = require('../config/database');

    // req.user is set by authenticate middleware
    if (!req.user || !req.user.userId) {
      return res.status(401).json({
        error: 'Authentication required',
        message: 'You must be logged in to access this resource',
      });
    }

    // Check user role in database
    const result = await pool.query(
      'SELECT role FROM users WHERE id = $1',
      [req.user.userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'User not found',
        message: 'User account no longer exists',
      });
    }

    const user = result.rows[0];

    if (user.role !== 'admin') {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Admin privileges required to access this resource',
      });
    }

    // User is admin, continue
    next();
  } catch (error) {
    console.error('Admin check error:', error);
    return res.status(500).json({
      error: 'Server error',
      message: 'Authorization check failed',
    });
  }
};

/**
 * Middleware to require write permissions (blocks guest users)
 * Must be used after authenticate middleware
 */
const requireWrite = async (req, res, next) => {
  try {
    // req.user is set by authenticate middleware
    if (!req.user || !req.user.userId) {
      return res.status(401).json({
        error: 'Authentication required',
        message: 'You must be logged in to access this resource',
      });
    }

    // Check if user is a guest
    if (req.user.role === 'guest') {
      return res.status(403).json({
        error: 'Forbidden',
        message: 'Guest users have read-only access',
      });
    }

    // User has write permissions, continue
    next();
  } catch (error) {
    console.error('Write permission check error:', error);
    return res.status(500).json({
      error: 'Server error',
      message: 'Authorization check failed',
    });
  }
};

module.exports = { authenticate, optionalAuthenticate, requireAdmin, requireWrite };
