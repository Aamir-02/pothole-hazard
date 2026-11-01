const mongoose = require('mongoose');

const rideSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    startTime: {
      type: Date,
      default: Date.now,
    },
    endTime: {
      type: Date,
    },
    durationMinutes: {
      type: Number,
      default: 0,
    },
    distanceKm: {
      type: Number,
      default: 0.0,
    },
    avgSpeedKmh: {
      type: Number,
      default: 0.0,
    },
    maxSpeedKmh: {
      type: Number,
      default: 0.0,
    },
    rideScore: {
      type: Number,
      default: 100,
    },
    potholesCount: {
      type: Number,
      default: 0,
    },
    caloriesEstimate: {
      type: Number,
      default: 0,
    },
    fuelEstimateLiters: {
      type: Number,
      default: 0.0,
    },
    routePoints: [
      {
        latitude: Number,
        longitude: Number,
        speedKmh: Number,
        timestamp: Date,
      },
    ],
    status: {
      type: String,
      enum: ['in_progress', 'completed', 'cancelled', 'emergency_triggered'],
      default: 'in_progress',
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Ride', rideSchema);
