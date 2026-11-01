const mongoose = require('mongoose');

const incidentSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    rideId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Ride',
    },
    timestamp: {
      type: Date,
      default: Date.now,
    },
    location: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true },
      address: { type: String, default: '' },
    },
    sensorValues: {
      accelerometerPeakG: { type: Number, required: true },
      gyroscopeMaxRotRadSec: { type: Number, required: true },
      speedBeforeImpactKmh: { type: Number, required: true },
      speedAfterImpactKmh: { type: Number, required: true },
      orientationPitch: { type: Number, default: 0 },
      orientationRoll: { type: Number, default: 0 },
    },
    confidenceScore: {
      type: Number,
      required: true,
    },
    severity: {
      type: String,
      enum: ['LOW', 'MEDIUM', 'HIGH', 'CRITICAL'],
      default: 'HIGH',
    },
    status: {
      type: String,
      enum: ['SENT', 'CANCELLED', 'CONFIRMED_SAFE', 'RESPONDED_BY_HELP'],
      default: 'SENT',
    },
    notifiedContacts: [
      {
        name: String,
        phone: String,
        notifiedAt: Date,
      },
    ],
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Incident', incidentSchema);
