import express from "express";
import { 
    signUp, 
    signIn, 
    refreshToken, 
    logout, 
    getProfile,
    updateProfile,
    getProfileStats 
} from "../controllers/auth.js";
import { authenticate } from "../middlewares/auth.js";

const router = express.Router();

// these are the public routes
router.post('/register', signUp);  
router.post('/login', signIn);
router.post('/refresh', refreshToken);

// these are protected routes
router.post('/logout', authenticate, logout);
router.get('/me', authenticate, getProfile);
router.get('/me/stats', authenticate, getProfileStats);
router.put('/profile', authenticate, updateProfile);

export default router;
