const http = require('http');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();

const connectDB = require('./config/db');
const { initSocket } = require('./services/socketService');
const { apiLimiter } = require('./middleware/rateLimiter');
const errorHandler = require('./middleware/errorHandler');

// Route Imports
const authRoutes = require('./routes/authRoutes');
const rideRoutes = require('./routes/rideRoutes');
const incidentRoutes = require('./routes/incidentRoutes');
const contactsRoutes = require('./routes/contactsRoutes');
const potholesRoutes = require('./routes/potholesRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const weatherRoutes = require('./routes/weatherRoutes');

const app = express();
const server = http.createServer(app);

// Connect Database
connectDB();

// Initialize Socket.io
initSocket(server);

// Security & Utility Middlewares
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan('dev'));
}

// Global API Rate Limiter
app.use('/api', apiLimiter);

// Healthcheck Route
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'HEALTHY',
    service: 'Pothole Hazard Backend Service',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development',
  });
});

// API Routes Mount
app.use('/api/auth', authRoutes);
app.use('/api/ride', rideRoutes);
app.use('/api/rides', rideRoutes);
app.use('/api/incident', incidentRoutes);
app.use('/api/incidents', incidentRoutes);
app.use('/api/emergency', incidentRoutes);
app.use('/api/contacts', contactsRoutes);
app.use('/api/potholes', potholesRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/weather', weatherRoutes);

// Error Handler Middleware
app.use(errorHandler);

const PORT = process.env.PORT || 5000;

if (process.env.NODE_ENV !== 'test') {
  server.listen(PORT, () => {
    console.log(`\n======================================================`);
    console.log(`🚀 Pothole Hazard Server Running on Port ${PORT}`);
    console.log(`🌐 Health check: http://localhost:${PORT}/health`);
    console.log(`======================================================\n`);
  });
}

module.exports = { app, server };
