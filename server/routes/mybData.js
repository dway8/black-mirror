const Router = require("express-promise-router");
const db = require("../db/index.js");
const logger = require("../logger");
const winston = logger.loggers.general;
const { sse } = require("./sse.js");

const router = new Router();

router
    .route("/")
    .get(async (req, res) => {
        const mybData = await getCurrentMybData();
        winston.verbose("mybData: ", mybData);
        res.send(mybData);
    })
    .post(async (req, res) => {
        res.send({ message: "OK" });
        const params = req.body;
        winston.verbose("Received params from MYB", params);

        let event;
        if (params.new_user) {
            handleNewUser();
            event = "new_user";
        } else if (params.new_order && params.amount) {
            await handleNewOrder(params);
            event = "new_order";
        } else if (params.order_cancelled && params.amount) {
            await handleOrderCancelled(params);
            event = "order_cancelled";
        } else if (params.new_exhibitor) {
            await handleNewExhibitor();
            event = "new_exhibitor";
        } else if (params.new_prod_occurrence) {
            await handleNewProdOccurrence(params);
            event = "new_prod_occurrence";
        } else if (params.new_open_occurrence) {
            await handleNewOpenOccurrence();
            event = "new_open_occurrence";
        }

        const currentMybData = await getCurrentMybData();

        sse.send({ data: currentMybData, event }, "MYB-event");
    });

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

async function handleNewUser() {
    let { id, todayUsers, totalUsers } = await getCurrentMybData();

    todayUsers++;
    totalUsers++;

    await updateTodayMybData({ totalUsers, todayUsers }, id);
}

async function handleNewOrder(params) {
    let {
        id,
        todayOrders,
        totalOrders,
        todayExhibitors,
        totalExhibitors,
        todayVA,
        totalVA,
        avgCart,
    } = await getCurrentMybData();

    winston.verbose("cur todayOrders", { id, todayOrders, totalOrders });

    todayOrders++;
    totalOrders++;
    todayVA = todayVA + parseFloat(params.amount);
    totalVA = totalVA + parseFloat(params.amount);
    avgCart = Math.round(totalVA / 100 / totalOrders);

    if (params.is_new_exhibitor) {
        todayExhibitors++;
        totalExhibitors++;
    }

    await updateTodayMybData(
        {
            todayOrders,
            totalOrders,
            todayExhibitors,
            totalExhibitors,
            todayVA,
            totalVA,
            avgCart,
        },
        id
    );
}

async function handleOrderCancelled(params) {
    let {
        id,
        todayOrders,
        totalOrders,
        todayVA,
        totalVA,
        avgCart,
    } = await getCurrentMybData();

    totalOrders--;
    totalVA = totalVA - parseFloat(params.amount);
    avgCart = Math.round(totalVA / 100 / totalOrders);

    const orderDate = new Date(params.date * 1000);
    if (orderDate >= getTodayMidnight()) {
        todayVA = todayVA - parseFloat(params.amount);
        todayOrders--;
    }

    await updateTodayMybData(
        { totalOrders, todayOrders, todayVA, totalVA, avgCart },
        id
    );
}

async function handleNewExhibitor() {
    let { id, todayExhibitors, totalExhibitors } = await getCurrentMybData();
    todayExhibitors++;
    totalExhibitors++;

    updateTodayMybData({ totalExhibitors, todayExhibitors }, id);
}

async function handleNewProdOccurrence(params) {
    let {
        id,
        todayClients,
        totalClients,
        todayProdOccurrences,
        totalProdOccurrences,
    } = await getCurrentMybData();

    todayProdOccurrences++;
    totalProdOccurrences++;

    if (params.is_new_client) {
        todayClients++;
        totalClients++;
    }

    await updateTodayMybData(
        {
            todayProdOccurrences,
            totalProdOccurrences,
            todayClients,
            totalClients,
        },
        id
    );
}

async function handleNewOpenOccurrence() {
    let {
        id,
        todayOpenOccurrences,
        totalOpenOccurrences,
    } = await getCurrentMybData();
    todayOpenOccurrences++;
    totalOpenOccurrences++;

    await updateTodayMybData(
        {
            todayOpenOccurrences,
            totalOpenOccurrences,
        },
        id
    );
}

// DB

async function updateTodayMybData(data, id) {
    winston.verbose("Updating today MYB data with", data);

    try {
        const newData = mybDataToDbKeys(data);
        for (let [key, value] of Object.entries(newData)) {
            const query = `UPDATE myb_data SET ${key} = ${value} WHERE id = ${id}`;
            await db.query(query);
        }
    } catch (err) {
        winston.error(err.stack);
    }
}

function getTodayMidnight() {
    return new Date().setHours(0, 0, 0, 0);
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

module.exports = router;
