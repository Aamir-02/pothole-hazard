const express = require('express');
const router = express.Router();
const {
  reportPothole,
  getPotholes,
  upvotePothole,
  deletePothole,
} = require('../controllers/potholesController');
const { protect } = require('../middleware/auth');

router.post('/', protect, reportPothole);
router.get('/', protect, getPotholes);
router.post('/:id/upvote', protect, upvotePothole);
router.delete('/:id', protect, deletePothole);

module.exports = router;
