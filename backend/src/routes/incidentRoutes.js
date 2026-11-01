const express = require('express');
const router = express.Router();
const {
  createIncident,
  cancelSos,
  getIncidentHistory,
  deleteIncident,
} = require('../controllers/incidentController');
const { protect } = require('../middleware/auth');

router.post('/', protect, createIncident);
router.post('/cancel', protect, cancelSos);
router.get('/history', protect, getIncidentHistory);
router.delete('/:id', protect, deleteIncident);

module.exports = router;
