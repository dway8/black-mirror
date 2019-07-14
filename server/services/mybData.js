const db = require("../db/index.js");
const logger = require("../logger");
const winston = logger.loggers.general;

async function getCurrentMybData() {
    try {
        const res = await db.query(
            "SELECT * FROM myb_data ORDER BY date DESC LIMIT 1"
        );
        const row = dbToMybDataKeys(res.rows[0]);

        return row;
    } catch (err) {
        winston.error(err.stack);

        return null;
    }
}

function dbToMybDataKeys(data) {
    const dbToMyb = {
        today_users: "todayUsers",
        total_users: "totalUsers",
        today_orders: "todayOrders",
        total_orders: "totalOrders",
        today_exhibitors: "todayExhibitors",
        total_exhibitors: "totalExhibitors",
        today_clients: "todayClients",
        total_clients: "totalClients",
        today_prod_occurrences: "todayProdOccurrences",
        total_prod_occurrences: "totalProdOccurrences",
        today_open_occurrences: "todayOpenOccurrences",
        total_open_occurrences: "totalOpenOccurrences",
        today_va: "todayVA",
        total_va: "totalVA",
        avg_cart: "avgCart",
    };
    const newData = {};

    for (let [key, value] of Object.entries(data)) {
        const newKey = dbToMyb[key] || key;
        newData[newKey] = value;
    }

    return newData;
}

function mybDataToDbKeys(data) {
    const mybToDb = {
        todayUsers: "today_users",
        totalUsers: "total_users",
        todayOrders: "today_orders",
        totalOrders: "total_orders",
        todayExhibitors: "today_exhibitors",
        totalExhibitors: "total_exhibitors",
        todayClients: "today_clients",
        totalClients: "total_clients",
        todayProdOccurrences: "today_prod_occurrences",
        totalProdOccurrences: "total_prod_occurrences",
        todayOpenOccurrences: "today_open_occurrences",
        totalOpenOccurrences: "total_open_occurrences",
        todayVA: "today_va",
        totalVA: "total_va",
        avgCart: "avg_cart",
    };
    const newData = {};

    for (let [key, value] of Object.entries(data)) {
        const newKey = mybToDb[key] || key;
        newData[newKey] = value;
    }

    return newData;
}

module.exports = { getCurrentMybData, mybDataToDbKeys };
