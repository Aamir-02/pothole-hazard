const EmergencyContact = require('../models/EmergencyContact');

// @desc Add new emergency contact (max 10)
// @route POST /api/contacts
exports.addContact = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    const { name, phone, relationship, isFavorite } = req.body;

    if (!name || !phone) {
      return res.status(400).json({ success: false, message: 'Name and phone number are required' });
    }

    const currentCount = await EmergencyContact.countDocuments({ userId });
    if (currentCount >= 10) {
      return res.status(400).json({ success: false, message: 'Maximum 10 emergency contacts limit reached' });
    }

    const contact = await EmergencyContact.create({
      userId,
      name,
      phone,
      relationship: relationship || 'Friend',
      isFavorite: isFavorite || false,
    });

    res.status(201).json({
      success: true,
      contact,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Get all emergency contacts for logged-in user
// @route GET /api/contacts
exports.getContacts = async (req, res, next) => {
  try {
    const userId = req.user._id || req.user.id;
    let contacts = await EmergencyContact.find({ userId }).sort({ isFavorite: -1, createdAt: -1 });

    if (!contacts || contacts.length === 0) {
      // Provide initial default contact
      contacts = [
        {
          _id: 'default_cnt_1',
          name: 'Primary Contact',
          phone: '+1 555 019 2834',
          relationship: 'Family',
          isFavorite: true,
        },
      ];
    }

    res.status(200).json({
      success: true,
      count: contacts.length,
      contacts,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Update emergency contact
// @route PUT /api/contacts/:id
exports.updateContact = async (req, res, next) => {
  try {
    const contact = await EmergencyContact.findById(req.params.id);
    if (!contact) {
      return res.status(404).json({ success: false, message: 'Contact not found' });
    }

    if (req.body.name) contact.name = req.body.name;
    if (req.body.phone) contact.phone = req.body.phone;
    if (req.body.relationship) contact.relationship = req.body.relationship;
    if (typeof req.body.isFavorite === 'boolean') contact.isFavorite = req.body.isFavorite;

    await contact.save();

    res.status(200).json({
      success: true,
      contact,
    });
  } catch (error) {
    next(error);
  }
};

// @desc Delete emergency contact
// @route DELETE /api/contacts/:id
exports.deleteContact = async (req, res, next) => {
  try {
    const contact = await EmergencyContact.findById(req.params.id);
    if (!contact) {
      return res.status(404).json({ success: false, message: 'Contact not found' });
    }

    await contact.deleteOne();

    res.status(200).json({
      success: true,
      message: 'Contact removed successfully',
    });
  } catch (error) {
    next(error);
  }
};
