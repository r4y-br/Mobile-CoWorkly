import rateLimit from 'express-rate-limit';

// Shared rate limiter used by tests and the app
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 100,
    message: { error: 'Too many requests' },
    standardHeaders: true,
    legacyHeaders: false,
});

export { limiter };
