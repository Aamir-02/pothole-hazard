const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      lowercase: true,
      trim: true,
      match: [
        /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)+$/,
        'Please enter a valid email address',
      ],
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [6, 'Password must be at least 6 characters long'],
      select: false,
    },
    phone: {
      type: String,
      trim: true,
      default: '',
    },
    avatar: {
      type: String,
      default: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    },
    role: {
      type: String,
      enum: ['user', 'admin'],
      default: 'user',
    },
    rideScore: {
      type: Number,
      default: 95,
    },
    todayDistanceKm: {
      type: Number,
      default: 0.0,
    },
    todayRideTimeMinutes: {
      type: Number,
      default: 0,
    },
    settings: {
      sensorSensitivity: {
        type: String,
        enum: ['low', 'medium', 'high'],
        default: 'medium',
      },
      countdownSeconds: {
        type: Number,
        enum: [5, 10, 15, 20, 30],
        default: 15,
      },
      darkMode: {
        type: Boolean,
        default: true,
      },
      units: {
        type: String,
        enum: ['metric', 'imperial'],
        default: 'metric',
      },
      batteryOptimizationEnabled: {
        type: Boolean,
        default: true,
      },
    },
    deviceToken: {
      type: String,
      default: '',
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform: function (doc, ret) {
        delete ret.password;
        delete ret.__v;
        return ret;
      },
    },
    toObject: {
      transform: function (doc, ret) {
        delete ret.password;
        delete ret.__v;
        return ret;
      },
    },
  }
);

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

userSchema.methods.matchPassword = async function (enteredPassword) {
  return await bcrypt.compare(enteredPassword, this.password);
};

module.exports = mongoose.model('User', userSchema);
