const authService = require("../services/auth.service");

const register = async (req, res) => {
    try {
        const { name, email, phone, password, role } = req.body;

        if (!name || !phone || !email || !password) {
            return res.status(400).json({
                success: false,
                message: "Name, phone, email and password are required"
            });
        }

        const user = await authService.registerUser({
            name,
            email,
            phone,
            password,
            role
        });

        res.status(201).json({
            success: true,
            message: "User registered successfully",
            data: user
        });

    } catch (error) {
        console.error("Registration error:", error);

        const status = error.statusCode || (error.code === "P2002" ? 409 : 400);

        res.status(status).json({
            success: false,
            message: error.message
        });
    }
};

const login = async (req, res) => {
    try {
        const { email, password } = req.body;

        if (!email || !password) {
            return res.status(400).json({
                success: false,
                message: "Email and password are required"
            });
        }

        const result = await authService.loginUser({
            email,
            password
        });

        res.status(200).json({
            success: true,
            message: "Login successful",
            data: result
        });

    } catch (error) {
        console.error("Login error:", error);

        res.status(error.statusCode || 401).json({
            success: false,
            message: error.message
        });
    }
};

module.exports = {
    register,
    login
};