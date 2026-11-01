const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'pothole_hazard_jwt_super_secret_key_2026';
const JWT_EXPIRE = process.env.JWT_EXPIRE || '30d';

const generateToken = (userId, role = 'user') => {
  return jwt.sign({ id: userId, role }, JWT_SECRET, {
    expiresIn: JWT_EXPIRE,
  });
};

const verifyToken = (token) => {
  return jwt.verify(token, JWT_SECRET);
};

module.exports = {
  generateToken,
  verifyToken,
};
