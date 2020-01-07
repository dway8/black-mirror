const Router = require("express-promise-router");
const db = require("../db/index.js");
const logger = require("../logger");
const winston = logger.loggers.general;
const { sse } = require("./sse.js");
const {
    getCurrentMybData,
    mybDataToDbKeys,
    getMybOpenings,
} = require("../services/mybData.js");

const router = new Router();

router
    .route("/")
    .get(async (req, res) => {
        const mybData = await getCurrentMybData();
        mybData.openings = await getMybOpenings();
        winston.verbose("mybData: ", mybData);
        res.send(mybData);
    })
    .post(async (req, res) => {
        res.send({ message: "OK" });
        const params = req.body;
        winston.verbose("Received params from MYB", params);

        const event = params.event;

        switch (event) {
            case "new_user":
                await handleNewUser();
                break;
            case "new_order":
                if (params.amount) {
                    await handleNewOrder(params);
                }
                break;
            case "order_cancelled":
                if (params.amount) {
                    await handleOrderCancelled(params);
                }
                break;
            case "new_exhibitor":
                await handleNewExhibitor();
                break;
            case "new_prod_occurrence":
                await handleNewProdOccurrence(params);
                break;
            case "new_open_occurrence":
                await handleNewOpenOccurrence();
                break;
            case "user_deleted":
                await handleUserDeleted(params);
                break;
            default:
                break;
        }

        let currentMybData = await getCurrentMybData();
        currentMybData.openings = await getMybOpenings();

        sse.send({ data: currentMybData, event }, "MYB-event");
    });

router.post("/update", async (req, res) => {
    res.send({ message: "OK" });
    const params = req.body;
    winston.verbose("Updating MYB data with", params);

    let { id } = await getCurrentMybData();
    await updateTodayMybData(params, id);
    winston.verbose("OK! Updated.");
});

async function handleNewUser() {
    let { id, todayUsers, yearUsers, totalUsers } = await getCurrentMybData();

    todayUsers++;
    yearUsers++;
    totalUsers++;

    await updateTodayMybData({ totalUsers, todayUsers, yearUsers }, id);
}

async function handleNewOrder(params) {
    let {
        id,
        todayOrders,
        yearOrders,
        totalOrders,
        todayExhibitors,
        yearExhibitors,
        totalExhibitors,
        todayVA,
        yearVA,
        totalVA,
        avgCart,
    } = await getCurrentMybData();

    todayOrders++;
    yearOrders++;
    totalOrders++;
    todayVA = todayVA + parseFloat(params.amount);
    yearVA = yearVA + parseFloat(params.amount);
    totalVA = totalVA + parseFloat(params.amount);
    avgCart = Math.round(totalVA / 100 / totalOrders);

    await updateTodayMybData(
        {
            todayOrders,
            yearOrders,
            totalOrders,
            todayExhibitors,
            yearExhibitors,
            totalExhibitors,
            todayVA,
            yearVA,
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
        yearOrders,
        totalOrders,
        todayVA,
        yearVA,
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

    if (new Date(orderDate).getFullYear() === getCurrentYear()) {
        yearVA = yearVA - parseFloat(params.amount);
        yearOrders--;
    }

    await updateTodayMybData(
        {
            totalOrders,
            yearOrders,
            todayOrders,
            todayVA,
            yearVA,
            totalVA,
            avgCart,
        },
        id
    );
}

async function handleNewExhibitor() {
    let {
        id,
        todayExhibitors,
        yearExhibitors,
        totalExhibitors,
    } = await getCurrentMybData();
    todayExhibitors++;
    yearExhibitors++;
    totalExhibitors++;

    updateTodayMybData(
        { totalExhibitors, todayExhibitors, yearExhibitors },
        id
    );
}

async function handleNewProdOccurrence(params) {
    const { is_new_client, occurrence_id, name, opening_date } = params;
    let {
        id,
        todayClients,
        yearClients,
        totalClients,
        todayProdOccurrences,
        yearProdOccurrences,
        totalProdOccurrences,
    } = await getCurrentMybData();

    todayProdOccurrences++;
    yearProdOccurrences++;
    totalProdOccurrences++;

    if (is_new_client) {
        todayClients++;
        yearClients++;
        totalClients++;
    }

    await updateTodayMybData(
        {
            todayProdOccurrences,
            yearProdOccurrences,
            totalProdOccurrences,
            todayClients,
            yearClients,
            totalClients,
        },
        id
    );

    try {
        await db.query(
            "INSERT INTO myb_openings(occurrence_id, name, opening_date) VALUES($1, $2, $3)",
            [occurrence_id, name, opening_date]
        );
    } catch (err) {
        winston.error(err.stack);
    }
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

async function handleUserDeleted(params) {
    let { id, todayUsers, yearUsers, totalUsers } = await getCurrentMybData();

    totalUsers--;

    const userRegistrationDate = new Date(params.date * 1000);
    if (userRegistrationDate >= getTodayMidnight()) {
        todayUsers--;
    }

    if (new Date(userRegistrationDate).getFullYear() >= getCurrentYear()) {
        yearUsers--;
    }

    await updateTodayMybData({ totalUsers, todayUsers, yearUsers }, id);
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

function getCurrentYear() {
    return new Date().getFullYear();
}

module.exports = router;
