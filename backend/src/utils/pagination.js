const getPagination = (query = {}) => {
    const page = Math.max(parseInt(query.page, 10) || 1, 1);
    const limit = Math.min(Math.max(parseInt(query.limit, 10) || 10, 1), 100);

    return {
        page,
        limit,
        skip: (page - 1) * limit,
        take: limit
    };
};

const buildMeta = (total, page, limit) => ({
    page,
    limit,
    total,
    totalPages: Math.ceil(total / limit)
});

module.exports = {
    getPagination,
    buildMeta
};
