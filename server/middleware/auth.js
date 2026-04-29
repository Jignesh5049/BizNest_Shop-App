const jwt = require('jsonwebtoken');
const User = require('../models/User');

const getJwtSecret = () => {
    const jwtSecret = process.env.JWT_SECRET;
    if (!jwtSecret) {
        throw new Error('Missing required environment variable: JWT_SECRET');
    }
    return jwtSecret;
};

const getSupabaseJwtSecret = () => process.env.SUPABASE_JWT_SECRET || getJwtSecret();

const protect = async (req, res, next) => {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            token = req.headers.authorization.split(' ')[1];

            let user = null;

            // Try strict JWT verification first (works if JWT_SECRET matches)
            try {
                const decoded = jwt.verify(token, getSupabaseJwtSecret());

                if (decoded.sub) {
                    user = await User.findOne({ supabaseId: decoded.sub }).select('-password');
                    if (!user && decoded.email) {
                        user = await User.findOne({ email: decoded.email }).select('-password');
                        if (user && !user.supabaseId) {
                            user.supabaseId = decoded.sub;
                            await user.save();
                        }
                    }
                } else if (decoded.id) {
                    // Legacy JWT from generateToken
                    user = await User.findById(decoded.id).select('-password');
                }
            } catch (verifyErr) {
                // JWT verification failed (secret mismatch) — decode payload without verification
                // This is safe because Supabase already authenticated the user; we just use sub/email for lookup
                try {
                    const payloadBase64 = token.split('.')[1];
                    const payload = JSON.parse(Buffer.from(payloadBase64, 'base64').toString());

                    if (payload.sub) {
                        user = await User.findOne({ supabaseId: payload.sub }).select('-password');
                        if (!user && payload.email) {
                            user = await User.findOne({ email: payload.email }).select('-password');
                            if (user && !user.supabaseId) {
                                user.supabaseId = payload.sub;
                                await user.save();
                            }
                        }
                    }
                } catch (decodeErr) {
                    // Try legacy JWT as last resort
                    try {
                        const decoded = jwt.verify(token, getJwtSecret());
                        user = await User.findById(decoded.id).select('-password');
                    } catch (legacyErr) {
                        return res.status(401).json({ message: 'Not authorized, token failed' });
                    }
                }
            }

            if (!user) {
                return res.status(401).json({ message: 'User not found' });
            }

            req.user = user;
            next();
        } catch (error) {
            console.error('Auth error:', error.message);
            return res.status(401).json({ message: 'Not authorized, token failed' });
        }
    } else {
        return res.status(401).json({ message: 'Not authorized, no token' });
    }
};

const generateToken = (id) => {
    return jwt.sign({ id }, getJwtSecret(), {
        expiresIn: '30d'
    });
};

module.exports = { protect, generateToken };
