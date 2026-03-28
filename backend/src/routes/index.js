import express from 'express';
import * as challengeCtrl from '../controllers/challengeController.js';
import * as adminCtrl from '../controllers/adminController.js';
import { protect, isAdmin } from '../middleware/authMiddleware.js';

const router = express.Router();

// User Routes
router.get('/challenges/today', protect, challengeCtrl.getTodayChallenge);
router.post('/challenges/complete', protect, challengeCtrl.submitCompletion);

// Admin Routes
router.post('/admin/challenges', protect, isAdmin, adminCtrl.createChallenge);
router.get('/admin/challenges', protect, isAdmin, adminCtrl.getAllChallenges);
router.put('/admin/challenges/:id', protect, isAdmin, adminCtrl.updateChallenge);
router.delete('/admin/challenges/:id', protect, isAdmin, adminCtrl.deleteChallenge);

export default router;
