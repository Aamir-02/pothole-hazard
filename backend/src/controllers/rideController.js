const Ride = require('../models/Ride');
const User = require('../models/User');

// @desc Start new ride session
// @route POST /api/ride/start
exports.startRide = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;

    // End any lingering un-ended rides
    await Ride.updateMany(
      { userId, status: 'in_progress' },
      { status: 'completed', endTime: new Date() }
    );

    const ride = await Ride.create({
      userId,
      startTime: new Date(),
      status: 'in_progress',
      routePoints: req.body.initialPoint ? [req.body.initialPoint] : [],
    });

    res.status(201).json({
      success: true,
      ride,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Stop current ride session & compute metrics
// @route POST /api/ride/stop
exports.stopRide = async (req, res, next) => {
  try {
    const { rideId, distanceKm, avgSpeedKmh, maxSpeedKmh, routePoints, durationMinutes, potholesCount } = req.body;
    const userId = req.user._id || req.user.id;

    let ride;
    if (rideId) {
      ride = await Ride.findOne({ _id: rideId, userId });
    }
    if (!ride) {
      ride = await Ride.findOne({ userId, status: 'in_progress' }).sort({ createdAt: -1 });
    }

    if (!ride) {
      // Create completed ride log directly
      const durMinutes = typeof durationMinutes === 'number' && durationMinutes >= 0 ? durationMinutes : 1;
      const startMs = Date.now() - durMinutes * 60 * 1000;
      ride = new Ride({
        userId,
        startTime: new Date(startMs),
      });
    }

    // Use actual transmitted values without fabricated defaults
    const dist = typeof distanceKm === 'number' ? distanceKm : (ride.distanceKm || 0.0);
    const dur = typeof durationMinutes === 'number' && durationMinutes >= 0
      ? durationMinutes
      : Math.max(0, Math.round((Date.now() - new Date(ride.startTime).getTime()) / 60000));
    const avg = typeof avgSpeedKmh === 'number'
      ? avgSpeedKmh
      : (dist > 0 && dur > 0 ? parseFloat((dist / (dur / 60)).toFixed(1)) : 0.0);
    const maxSpd = typeof maxSpeedKmh === 'number' ? maxSpeedKmh : avg;
    const potholes = typeof potholesCount === 'number' ? potholesCount : (ride.potholesCount || 0);
    const calories = Math.round(dist * 22 + dur * 4);
    const fuel = parseFloat((dist * 0.035).toFixed(2));

    ride.endTime = new Date();
    ride.status = 'completed';
    ride.distanceKm = dist;
    ride.durationMinutes = dur;
    ride.avgSpeedKmh = avg;
    ride.maxSpeedKmh = maxSpd;
    ride.potholesCount = potholes;
    ride.caloriesEstimate = calories;
    ride.fuelEstimateLiters = fuel;
    if (routePoints && Array.isArray(routePoints)) {
      ride.routePoints = routePoints;
    }

    await ride.save();

    // Update user stats
    const user = await User.findById(userId);
    if (user) {
      user.todayDistanceKm = parseFloat(((user.todayDistanceKm || 0) + dist).toFixed(1));
      user.todayRideTimeMinutes = (user.todayRideTimeMinutes || 0) + dur;
      await user.save();
    }

    res.status(200).json({
      success: true,
      ride,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Get ride history for logged in user
// @route GET /api/ride/history
exports.getRideHistory = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    const rides = await Ride.find({ userId, status: 'completed' }).sort({ createdAt: -1 }).limit(50);

    res.status(200).json({
      success: true,
      count: rides.length,
      rides: rides || [],
    });
  } catch (error) {
    next(error);
  }
};
