const Pothole = require('../models/Pothole');

// @desc Report a new Pothole (with auto duplicate hiding)
// @route POST /api/potholes
exports.reportPothole = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    const { latitude, longitude, photoUrl, severity, roadType, description, address } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({ success: false, message: 'Latitude and Longitude are required' });
    }

    const lat = parseFloat(latitude);
    const lng = parseFloat(longitude);

    // Auto Duplicate Detection (Check within ~30 meters radius ~ 0.0003 deg)
    const existingNearPothole = await Pothole.findOne({
      status: 'ACTIVE',
      latitude: { $gte: lat - 0.0003, $lte: lat + 0.0003 },
      longitude: { $gte: lng - 0.0003, $lte: lng + 0.0003 },
    });

    if (existingNearPothole) {
      // Auto increment upvotes on existing report instead of duplicating
      existingNearPothole.upvotes += 1;
      if (!existingNearPothole.upvotedBy.includes(userId)) {
        existingNearPothole.upvotedBy.push(userId);
      }
      await existingNearPothole.save();

      return res.status(200).json({
        success: true,
        message: 'A report already exists nearby! Added your upvote to confirm it.',
        pothole: existingNearPothole,
        isDuplicateUpvoted: true,
      });
    }

    const pothole = await Pothole.create({
      userId,
      reporterName: req.user.name || 'Rider Community Member',
      latitude: lat,
      longitude: lng,
      location: {
        type: 'Point',
        coordinates: [lng, lat],
      },
      address: address || 'Main Road Sector',
      photoUrl: photoUrl || 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=400',
      severity: severity || 'MEDIUM',
      roadType: roadType || 'City Street',
      description: description || 'Deep severe pothole reported by rider.',
      upvotes: 1,
      upvotedBy: [userId],
    });

    res.status(201).json({
      success: true,
      pothole,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Get nearby reported potholes
// @route GET /api/potholes
exports.getPotholes = async (req, res, next) => {
  try {
    const { lat, lng, radiusKm = 10 } = req.query;

    let potholes;
    if (lat && lng) {
      const latitude = parseFloat(lat);
      const longitude = parseFloat(lng);
      potholes = await Pothole.find({
        status: 'ACTIVE',
        latitude: { $gte: latitude - 0.1, $lte: latitude + 0.1 },
        longitude: { $gte: longitude - 0.1, $lte: longitude + 0.1 },
      }).sort({ upvotes: -1, createdAt: -1 });
    } else {
      potholes = await Pothole.find({ status: 'ACTIVE' }).sort({ upvotes: -1, createdAt: -1 }).limit(50);
    }

    // Default sample data if DB is fresh
    if (!potholes || potholes.length === 0) {
      const baseLat = parseFloat(lat) || 37.7749;
      const baseLng = parseFloat(lng) || -122.4194;
      potholes = [
        {
          _id: 'pothole_sample_1',
          reporterName: 'Alex Rider',
          latitude: baseLat + 0.002,
          longitude: baseLng + 0.003,
          address: 'Oakland Ave & 4th Street',
          photoUrl: 'https://images.unsplash.com/photo-1515162816999-a0c47dc192f7?w=400',
          severity: 'HIGH',
          roadType: 'City Street',
          description: 'Deep 8-inch severe pothole right in center lane!',
          upvotes: 14,
          status: 'ACTIVE',
        },
        {
          _id: 'pothole_sample_2',
          reporterName: 'Carlos M.',
          latitude: baseLat - 0.004,
          longitude: baseLng - 0.002,
          address: 'Expressway Service Lane',
          photoUrl: 'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=400',
          severity: 'MEDIUM',
          roadType: 'Highway',
          description: 'Cracked asphalt erosion causing rim damage.',
          upvotes: 8,
          status: 'ACTIVE',
        },
      ];
    }

    res.status(200).json({
      success: true,
      count: potholes.length,
      potholes,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Upvote / Confirm Pothole
// @route POST /api/potholes/:id/upvote
exports.upvotePothole = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    const pothole = await Pothole.findById(req.params.id);

    if (!pothole) {
      return res.status(404).json({ success: false, message: 'Pothole report not found' });
    }

    if (!pothole.upvotedBy.includes(userId)) {
      pothole.upvotedBy.push(userId);
      pothole.upvotes += 1;
      await pothole.save();
    }

    res.status(200).json({
      success: true,
      upvotes: pothole.upvotes,
      pothole,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Delete or hide duplicate pothole report
// @route DELETE /api/potholes/:id
exports.deletePothole = async (req, res, next) => {
  try {
    const pothole = await Pothole.findById(req.params.id);
    if (!pothole) {
      return res.status(404).json({ success: false, message: 'Pothole report not found' });
    }
    await pothole.deleteOne();
    res.status(200).json({ success: true, message: 'Pothole report removed successfully' });
  } catch (error) {
    next(error);
  }
};
