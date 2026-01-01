import { prisma } from "../../lib/prisma.js";
import { isValidEmail, isValidPassword } from "../../lib/Validators.js";
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET;
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET;

const generateAccessToken = (userId, role) => {
    return jwt.sign({ id: userId, role }, JWT_SECRET, { expiresIn: '15m' });
};

const generateRefreshToken = (userId) => {
    return jwt.sign({ id: userId }, JWT_REFRESH_SECRET, { expiresIn: '7d' });
};

export const signUp = async (req, res) => {
    try {
        const { name, email, password, retypedPassword, phone } = req.body;
        
        if (!name || !email || !password || !retypedPassword) {
            return res.status(400).json({ message: "All fields are required." });
        }
        
        if (password !== retypedPassword) {
            return res.status(400).json({ message: "Passwords do not match." });
        }
        
        if (!isValidEmail(email)) {
            return res.status(400).json({ message: "Invalid email format." });
        }
        
        if (!isValidPassword(password)) {
            return res.status(400).json({ message: "Password does not meet complexity requirements." });
        }

        const existingUser = await prisma.user.findUnique({ where: { email } });
        if (existingUser) {
            return res.status(400).json({ message: "Email is already registered." });
        }
        
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const newUser = await prisma.user.create({
            data: {
                name,
                email,
                password: hashedPassword,
                phone
            },
        });
        
        const accessToken = generateAccessToken(newUser.id, newUser.role);
        const refreshToken = generateRefreshToken(newUser.id);
        
        // store refresh token in database
        await prisma.user.update({
            where: { id: newUser.id },
            data: { refreshToken }
        });
        
        return res.status(201).json({ 
            message: "User registered successfully.", 
            user: {
                id: newUser.id,
                name: newUser.name,
                email: newUser.email,
                role: newUser.role,
                createdAt: newUser.createdAt
            },
            token: accessToken,
            accessToken,
            refreshToken
        });

    } catch (error) {
        console.error("Error during sign-up:", error);
        return res.status(500).json({ message: "Internal server error." });
    }
};

export const signIn = async (req, res) => {
    try {
        const { email, password } = req.body;
        
        if (!email || !password) {
            return res.status(400).json({ message: "Email and password are required." });
        }
        
        const user = await prisma.user.findUnique({ where: { email } });
        if (!user || !(await bcrypt.compare(password, user.password))) {
            return res.status(401).json({ message: "Invalid email or password." });
        }
        
        const accessToken = generateAccessToken(user.id, user.role);
        const refreshToken = generateRefreshToken(user.id);
        
        // refresh token update in database
        await prisma.user.update({
            where: { id: user.id },
            data: { refreshToken }
        });
        
        return res.status(200).json({ 
            message: "Sign-in successful.", 
            user: {
                id: user.id,
                name: user.name,
                email: user.email,
                role: user.role,
                createdAt: user.createdAt
            },
            token: accessToken,
            accessToken,
            refreshToken
        });

    } catch (error) {
        console.error("Error during sign-in:", error);
        return res.status(500).json({ message: "Internal server error." });
    }
};

export const refreshToken = async (req, res) => {
    try {
        const { refreshToken } = req.body;
        
        if (!refreshToken) {
            return res.status(401).json({ message: "Refresh token required." });
        }
        
        // verify the refresh token
        const decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
        
        // check if token exists in database
        const user = await prisma.user.findUnique({ 
            where: { id: decoded.id } 
        });
        
        if (!user || user.refreshToken !== refreshToken) {
            return res.status(403).json({ message: "Invalid refresh token." });
        }
        
        // token generation
        const newAccessToken = generateAccessToken(user.id, user.role);
        const newRefreshToken = generateRefreshToken(user.id);
        
        // refresh token update in database
        await prisma.user.update({
            where: { id: user.id },
            data: { refreshToken: newRefreshToken }
        });
        
        return res.status(200).json({
            accessToken: newAccessToken,
            refreshToken: newRefreshToken
        });
        
    } catch (error) {
        console.error("Error refreshing token:", error);
        return res.status(403).json({ message: "Invalid or expired refresh token." });
    }
};

export const logout = async (req, res) => {
    try {
        const userId = req.user.id; 
        
        // we remove refresh token from database when we logout 
        await prisma.user.update({
            where: { id: userId },
            data: { refreshToken: null }
        });
        
        return res.status(200).json({ message: "Logged out successfully." });
        
    } catch (error) {
        console.error("Error during logout:", error);
        return res.status(500).json({ message: "Internal server error." });
    }
};

export const getProfile = async (req, res) => {
    try {
        const user = await prisma.user.findUnique({
            where: { id: req.user.id },
            select: {
                id: true,
                name: true,
                email: true,
                phone: true,
                role: true,
                createdAt: true
            }
        });
        
        if (!user) {
            return res.status(404).json({ message: "User not found." });
        }
        
        return res.status(200).json({ user });
        
    } catch (error) {
        console.error("Error fetching profile:", error);
        return res.status(500).json({ message: "Internal server error." });
    }
};


export const updateProfile = async (req, res) => {
    try {
        const userId = req.user.id;
        const { name, phone } = req.body;
        
        const updatedUser = await prisma.user.update({
            where: { id: userId },
            data: { name, phone },
            select: {
                id: true,
                name: true,
                email: true,
                phone: true,
                role: true,
                createdAt: true
            }
        });
        
        return res.status(200).json({ 
            message: "Profile updated successfully.", 
            user: updatedUser 
        });
        
    } catch (error) {
        console.error("Error updating profile:", error);
        return res.status(500).json({ message: "Internal server error." });
    }
};
