const mongoose = require('mongoose');

const potholeSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    reporterName: {
      type: String,
      default: 'Anonymous Rider',
    },
    location: {
      type: {
        type: String,
        enum: ['Point'],
        default: 'Point',
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        required: true,
      },
    },
    latitude: { type: Number, required: true },
    longitude: { type: Number, required: true },
    address: { type: String, default: 'Street Road' },
    photoUrl: {
      type: String,
      default: 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=400',
    },
    severity: {
      type: String,
      enum: ['LOW', 'MEDIUM', 'HIGH'],
      default: 'MEDIUM',
    },
    roadType: {
      type: String,
      enum: ['City Street', 'Highway', 'Rural Road', 'Alleyway'],
      default: 'City Street',
    },
    description: {
      type: String,
      default: 'Dangerous deep pothole recorded by rider.',
    },
    upvotes: {
      type: Number,
      default: 1,
    },
    upvotedBy: [
      {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
      },
    ],
    status: {
      type: String,
      enum: ['ACTIVE', 'RESOLVED', 'DUPLICATE_HIDDEN'],
      default: 'ACTIVE',
    },
  },
  {
    timestamps: true,
  }
);

potholeSchema.index({ location: '2dsphere' });

module.exports = mongoose.model('Pothole', potholeSchema);
