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
        year_users: "yearUsers",
        total_users: "totalUsers",
        today_orders: "todayOrders",
        year_orders: "yearOrders",
        total_orders: "totalOrders",
        today_exhibitors: "todayExhibitors",
        year_exhibitors: "yearExhibitors",
        total_exhibitors: "totalExhibitors",
        today_clients: "todayClients",
        year_clients: "yearClients",
        total_clients: "totalClients",
        today_prod_occurrences: "todayProdOccurrences",
        year_prod_occurrences: "yearProdOccurrences",
        total_prod_occurrences: "totalProdOccurrences",
        today_open_occurrences: "todayOpenOccurrences",
        total_open_occurrences: "totalOpenOccurrences",
        today_va: "todayVA",
        year_va: "yearVA",
        total_va: "totalVA",
        avg_cart: "avgCart",
        opening_date: "openingDate",
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
        yearUsers: "year_users",
        totalUsers: "total_users",
        todayOrders: "today_orders",
        yearOrders: "year_orders",
        totalOrders: "total_orders",
        todayExhibitors: "today_exhibitors",
        yearExhibitors: "year_exhibitors",
        totalExhibitors: "total_exhibitors",
        todayClients: "today_clients",
        yearClients: "year_clients",
        totalClients: "total_clients",
        todayProdOccurrences: "today_prod_occurrences",
        yearProdOccurrences: "year_prod_occurrences",
        totalProdOccurrences: "total_prod_occurrences",
        todayOpenOccurrences: "today_open_occurrences",
        totalOpenOccurrences: "total_open_occurrences",
        todayVA: "today_va",
        yearVA: "year_va",
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
async function getMybOpenings() {
    try {
        const { rows } = await db.query(
            "SELECT name, ROUND((EXTRACT(epoch FROM opening_date)* 1000)) as opening_date FROM myb_openings WHERE opening_date <= (now() + '7 day'::interval) AND opening_date >= now()"
        );
        const openings = rows.map(row => {
            return dbToMybDataKeys(row);
        });

        return openings;
    } catch (err) {
        winston.error(err.stack);

        return null;
    }
}

module.exports = { getCurrentMybData, mybDataToDbKeys, getMybOpenings };
