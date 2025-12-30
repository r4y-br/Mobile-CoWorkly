import express from "express";
import { 
    signUp, 
    signIn, 
    refreshToken, 
    logout, 
    getProfile,
    getMyProfile,
    updateProfile 
} from "../controllers/auth.js";
import { authenticate } from "../middlewares/auth.js";

const router = express.Router();

// these are the public routes
router.post('/signup', signUp);
router.post('/signin', signIn);
router.post('/refresh', refreshToken);

// these are protected routes
router.post('/logout', authenticate, logout);
router.get('/profile', authenticate, getProfile);
router.get('/me', authenticate, getMyProfile);
router.put('/profile', authenticate, updateProfile);

export default router;
