const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/database');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-this-in-production';
const JWT_EXPIRES_IN = '7d'; // Token expires in 7 days

// Register a new user
exports.register = async (req, res, next) => {
  try {
    const { email, password, name } = req.body;

    // Validation
    if (!email || !password || !name) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Email, password, and name are required',
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Password must be at least 6 characters',
      });
    }

    // Check if user already exists
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE email = $1',
      [email.toLowerCase()]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        error: 'Conflict',
        message: 'User with this email already exists',
      });
    }

    // Hash password
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user
    const result = await pool.query(
      `INSERT INTO users (email, password_hash, name)
       VALUES ($1, $2, $3)
       RETURNING id, email, name, role, created_at`,
      [email.toLowerCase(), passwordHash, name]
    );

    const user = result.rows[0];

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.status(201).json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        createdAt: user.created_at,
      },
      token,
    });
  } catch (error) {
    next(error);
  }
};

// Login user (supports both email and phone number)
exports.login = async (req, res, next) => {
  try {
    const { email, phoneNumber, password } = req.body;

    // Validation
    if ((!email && !phoneNumber) || !password) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Email or phone number and password are required',
      });
    }

    // Find user by email or phone number
    let result;
    if (phoneNumber) {
      result = await pool.query(
        'SELECT id, email, password_hash, name, role, created_at, phone_number FROM users WHERE phone_number = $1',
        [phoneNumber]
      );
    } else {
      result = await pool.query(
        'SELECT id, email, password_hash, name, role, created_at, phone_number FROM users WHERE email = $1',
        [email.toLowerCase()]
      );
    }

    if (result.rows.length === 0) {
      return res.status(401).json({
        error: 'Authentication failed',
        message: 'Invalid credentials',
      });
    }

    const user = result.rows[0];

    // Verify password
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);

    if (!isPasswordValid) {
      return res.status(401).json({
        error: 'Authentication failed',
        message: 'Invalid credentials',
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: JWT_EXPIRES_IN }
    );

    res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        phoneNumber: user.phone_number,
        createdAt: user.created_at,
      },
      token,
    });
  } catch (error) {
    next(error);
  }
};

// Get current user (requires auth)
exports.getCurrentUser = async (req, res, next) => {
  try {
    // req.user is set by auth middleware
    const userId = req.user.userId;

    const result = await pool.query(
      'SELECT id, email, name, role, created_at FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'User not found',
      });
    }

    const user = result.rows[0];

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      createdAt: user.created_at,
    });
  } catch (error) {
    next(error);
  }
};

// Get all users (admin only)
exports.getAllUsers = async (req, res, next) => {
  try {
    const result = await pool.query(
      'SELECT id, email, name, role, created_at FROM users ORDER BY created_at DESC'
    );

    const users = result.rows.map(user => ({
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      createdAt: user.created_at,
    }));

    res.json(users);
  } catch (error) {
    next(error);
  }
};

// Change password (authenticated user)
exports.changePassword = async (req, res, next) => {
  try {
    const userId = req.user.userId;
    const { currentPassword, newPassword } = req.body;

    // Validation
    if (!currentPassword || !newPassword) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Current password and new password are required',
      });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'New password must be at least 6 characters',
      });
    }

    // Get user with current password
    const result = await pool.query(
      'SELECT id, password_hash FROM users WHERE id = $1',
      [userId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'User not found',
      });
    }

    const user = result.rows[0];

    // Verify current password
    const isPasswordValid = await bcrypt.compare(currentPassword, user.password_hash);

    if (!isPasswordValid) {
      return res.status(401).json({
        error: 'Authentication failed',
        message: 'Current password is incorrect',
      });
    }

    // Hash new password
    const saltRounds = 10;
    const newPasswordHash = await bcrypt.hash(newPassword, saltRounds);

    // Update password
    await pool.query(
      'UPDATE users SET password_hash = $1 WHERE id = $2',
      [newPasswordHash, userId]
    );

    res.json({
      message: 'Password changed successfully',
    });
  } catch (error) {
    next(error);
  }
};

// Generate random password
function generatePassword() {
  const length = 8;
  const charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let password = '';
  for (let i = 0; i < length; i++) {
    password += charset.charAt(Math.floor(Math.random() * charset.length));
  }
  return password;
}

// Create a new user (admin only)
exports.createUser = async (req, res, next) => {
  try {
    const { name, phoneNumber, role } = req.body;

    // Validation
    if (!name || !phoneNumber) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Name and phone number are required',
      });
    }

    if (!phoneNumber.startsWith('+')) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Phone number must include country code (+...)',
      });
    }

    // Validate role
    const userRole = role || 'user';
    if (userRole !== 'user' && userRole !== 'admin' && userRole !== 'guest') {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Role must be "user", "admin", or "guest"',
      });
    }

    // Check if user already exists with this phone number
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE phone_number = $1',
      [phoneNumber]
    );

    if (existingUser.rows.length > 0) {
      return res.status(409).json({
        error: 'Conflict',
        message: 'User with this phone number already exists',
      });
    }

    // Auto-generate password
    const password = generatePassword();

    // Auto-generate email from phone number (for database requirement)
    const email = `${phoneNumber.replace('+', '')}@trailer-manager.local`;

    // Hash password
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create user
    const result = await pool.query(
      `INSERT INTO users (email, password_hash, name, role, phone_number)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING id, email, name, role, phone_number, created_at`,
      [email, passwordHash, name, userRole, phoneNumber]
    );

    const user = result.rows[0];

    // SMS will be sent from the Flutter app
    // Return the generated password so it can be sent via SMS
    res.status(201).json({
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      phoneNumber: user.phone_number,
      password: password, // Only returned on creation for SMS
      createdAt: user.created_at,
    });
  } catch (error) {
    next(error);
  }
};

// Update user role (admin only)
exports.updateUserRole = async (req, res, next) => {
  try {
    const { userId } = req.params;
    const { role } = req.body;

    // Validation
    if (!userId) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'User ID is required',
      });
    }

    if (!role) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Role is required',
      });
    }

    // Validate role
    if (role !== 'user' && role !== 'admin' && role !== 'guest') {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'Role must be "user", "admin", or "guest"',
      });
    }

    // Prevent self-role-change to non-admin
    if (req.user.userId === userId && role !== 'admin') {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'You cannot change your own admin role',
      });
    }

    // Check if user exists
    const existingUser = await pool.query(
      'SELECT id, email, name, role, created_at FROM users WHERE id = $1',
      [userId]
    );

    if (existingUser.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'User not found',
      });
    }

    // Update role
    const result = await pool.query(
      'UPDATE users SET role = $1 WHERE id = $2 RETURNING id, email, name, role, created_at',
      [role, userId]
    );

    const user = result.rows[0];

    res.json({
      id: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      createdAt: user.created_at,
    });
  } catch (error) {
    next(error);
  }
};

// Delete a user (admin only)
exports.deleteUser = async (req, res, next) => {
  try {
    const { userId } = req.params;

    // Validation
    if (!userId) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'User ID is required',
      });
    }

    // Prevent self-deletion
    if (req.user.userId === userId) {
      return res.status(400).json({
        error: 'Validation failed',
        message: 'You cannot delete your own account',
      });
    }

    // Check if user exists
    const existingUser = await pool.query(
      'SELECT id FROM users WHERE id = $1',
      [userId]
    );

    if (existingUser.rows.length === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'User not found',
      });
    }

    // Delete user
    await pool.query('DELETE FROM users WHERE id = $1', [userId]);

    res.json({
      message: 'User deleted successfully',
    });
  } catch (error) {
    next(error);
  }
};
