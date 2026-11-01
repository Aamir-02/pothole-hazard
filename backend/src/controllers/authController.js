const User = require('../models/User');
const { generateToken } = require('../config/jwt');

const EMAIL_REGEX = /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/;

// @desc Register / Signup new user
// @route POST /api/auth/register or POST /api/auth/signup
exports.register = async (req, res, next) => {
  try {
    const { name, email, password, confirmPassword, phone } = req.body;

    // Field presence checks
    if (!name || typeof name !== 'string' || name.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Full name is required' });
    }

    if (name.trim().length < 2) {
      return res.status(400).json({ success: false, message: 'Full name must be at least 2 characters' });
    }

    if (!email || typeof email !== 'string' || email.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Email address is required' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    if (!EMAIL_REGEX.test(normalizedEmail)) {
      return res.status(400).json({ success: false, message: 'Please enter a valid email address format' });
    }

    if (!password || typeof password !== 'string') {
      return res.status(400).json({ success: false, message: 'Password is required' });
    }

    if (password.length < 6) {
      return res.status(400).json({ success: false, message: 'Password must be at least 6 characters long' });
    }

    if (confirmPassword !== undefined && confirmPassword !== null && confirmPassword !== password) {
      return res.status(400).json({ success: false, message: 'Password and confirm password do not match' });
    }

    // Check for existing user by normalized email
    const userExists = await User.findOne({ email: normalizedEmail });
    if (userExists) {
      return res.status(409).json({ success: false, message: 'An account with this email address already exists' });
    }

    // Create user in database (pre-save hook hashes the password)
    const user = await User.create({
      name: name.trim(),
      email: normalizedEmail,
      password: password,
      phone: phone ? String(phone).trim() : '',
    });

    const token = generateToken(user._id, user.role);

    return res.status(201).json({
      success: true,
      message: 'Account created successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        settings: user.settings,
        rideScore: user.rideScore,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(409).json({ success: false, message: 'An account with this email address already exists' });
    }
    next(error);
  }
};

// @desc Login user
// @route POST /api/auth/login
exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || typeof email !== 'string' || email.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Please enter your email address' });
    }

    if (!password || typeof password !== 'string' || password.length === 0) {
      return res.status(400).json({ success: false, message: 'Please enter your password' });
    }

    const normalizedEmail = email.trim().toLowerCase();

    // Look up user with password hash selected for comparison
    const user = await User.findOne({ email: normalizedEmail }).select('+password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'No account found with this email address. Please check your email or sign up.',
      });
    }

    const isMatch = await user.matchPassword(password);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials: Incorrect password. Please try again.',
      });
    }

    const token = generateToken(user._id, user.role);

    return res.status(200).json({
      success: true,
      message: 'Logged in successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        settings: user.settings,
        rideScore: user.rideScore,
        avatar: user.avatar,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc Google OAuth Login
// @route POST /api/auth/google-login
exports.googleLogin = async (req, res, next) => {
  try {
    const { googleToken, email, name, avatar } = req.body;

    if (!email) {
      return res.status(400).json({ success: false, message: 'Email required for Google Login' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    let user = await User.findOne({ email: normalizedEmail });

    if (!user) {
      user = await User.create({
        name: name || 'Rider User',
        email: normalizedEmail,
        password: Math.random().toString(36).slice(-10) + 'Pothole2026!',
        avatar: avatar || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      });
    }

    const token = generateToken(user._id, user.role);

    res.status(200).json({
      success: true,
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        settings: user.settings,
        rideScore: user.rideScore,
        avatar: user.avatar,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    next(error);
  }
};

// @desc Forgot password request
// @route POST /api/auth/forgot-password
exports.forgotPassword = async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email || typeof email !== 'string' || email.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Please enter your email address' });
    }

    const normalizedEmail = email.trim().toLowerCase();
    if (!EMAIL_REGEX.test(normalizedEmail)) {
      return res.status(400).json({ success: false, message: 'Please enter a valid email address format' });
    }

    const user = await User.findOne({ email: normalizedEmail });
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'No registered account found with this email address.',
      });
    }

    // Notice: Server does not have an external SMTP/mailer transport configured in .env
    return res.status(200).json({
      success: true,
      emailConfigured: false,
      message: `Password reset request registered for ${normalizedEmail}. Note: SMTP/Email delivery service is currently not configured on the backend server, so automated delivery is pending administrator setup.`,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Get user profile
// @route GET /api/auth/profile
exports.getProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id || req.user.id);
    if (!user) {
      return res.status(200).json({
        success: true,
        user: req.user,
      });
    }
    res.status(200).json({
      success: true,
      user,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Update user profile & settings
// @route PUT /api/auth/profile
exports.updateProfile = async (req, res, next) => {
  try {
    const user = await User.findById(req.user._id || req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    if (req.body.name) user.name = req.body.name;
    if (req.body.phone) user.phone = req.body.phone;
    if (req.body.settings) user.settings = { ...user.settings, ...req.body.settings };

    await user.save();

    res.status(200).json({
      success: true,
      user,
    });
  } catch (error) {
    next(error);
  }
};
