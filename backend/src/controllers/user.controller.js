const asyncHandler = require("../utils/asyncHandler");
const userService = require("../services/user.service");

const listUsers = asyncHandler(async (req, res) => {
    const { items, meta } = await userService.listUsers(req.query);

    res.json({
        success: true,
        message: "Users retrieved successfully",
        data: items,
        meta
    });
});

const getUserById = asyncHandler(async (req, res) => {
    const user = await userService.getUserById(req.params.id);

    res.json({
        success: true,
        message: "User retrieved successfully",
        data: user
    });
});

module.exports = {
    listUsers,
    getUserById
};
