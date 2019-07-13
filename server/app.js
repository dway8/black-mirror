"use strict";
var express = require("express");
var cors = require("cors");
var request = require("request");
const CronJob = require("cron").CronJob;
const logger = require("./logger");
const winston = logger.loggers.general;
const path = require("path");
const SSE = require("express-sse");
const sse = new SSE(["Connected!"]);
const db = require("./db/index.js");
const mountRoutes = require("./routes");
const requireAuth = require("./middlewares/auth.js");

// Constants
const PORT = 42425;
const isDevelopment = process.env.NODE_ENV !== "production";

const bodyParser = require("body-parser");

const whitelist = ["http://localhost", "http://localhost:42424"];
const corsOptions = {
    origin: function(origin, callback) {
        const originIsWhitelisted = whitelist.indexOf(origin) !== -1;
        callback(null, originIsWhitelisted);
    },
    credentials: true,
};

const app = express();

app.use(cors(corsOptions));

// parse application/x-www-form-urlencoded
app.use(bodyParser.urlencoded({ extended: false, limit: "50mb" }));

// parse application/json
app.use(bodyParser.json({ limit: "50mb" }));
app.use(bodyParser.raw({ type: "text/plain" }));

mountRoutes(app);

// ROUTES ////////////////
//////////////////////////

app.get("/api/forecast/:coords", (req, res) => {
    request.get(
        {
            url: `https://api.darksky.net/forecast/537e53749d634ff0707fa5acadb2eab3/${req.params.coords}`,
            qs: req.query,
            json: true,
            headers: { "User-Agent": "request" },
        },
        (error, response, body) => {
            if (error) {
                console.log("Error:", error);
            } else if (response.statusCode !== 200) {
                console.log("Status:", response.statusCode);
            } else {
                res.send(body);
            }
        }
    );
});

app.get("/api/last_tweet", (req, res) => {
    request.get(
        {
            url: "https://api.twitter.com/1.1/statuses/user_timeline.json",
            oauth: {
                consumer_key: "dC3j3ePjUib6m2fdZvTKPS7Mb",
                consumer_secret:
                    "lojT6tjtND5O6KJsWZr1xbQNR76SifTpDo0pz0ID47M3ke0mva",
            },
            qs: {
                user_id: "740520993911898113",
                count: 1,
                tweet_mode: "extended",
            },
            json: true,
            headers: { "User-Agent": "request" },
        },
        (error, response, body) => {
            if (error) {
                console.log("Error:", error);
            } else if (response.statusCode !== 200) {
                console.log("Status:", response.statusCode);
            } else {
                res.send(body);
            }
        }
    );
});

app.get("/api/myb_data", async (req, res) => {
    const mybData = await getCurrentMybData();
    winston.verbose("mybData: ", mybData);
    res.json(mybData);
});

app.post("/mmi", async (req, res) => {
    res.json({ message: "OK" });
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

    const currentMybData = getCurrentMybData();

    sse.send({ data: currentMybData, event }, "MYB-event");
});

app.get("/api/messages", (req, res) => {
    res.json({});
    // const messages = db
    //     .get("messages")
    //     .filter(m => m.active)
    //     .value();
    // res.json(messages);
});

app.get("/api/sse", sse.init);

// Serving compiled elm client
if (!isDevelopment) {
    app.get("/admin", requireAuth, (req, res) =>
        res.sendFile(path.join(__dirname, "/../dist/admin.html"))
    );

    app.get("/admin.html", requireAuth, (req, res) =>
        res.sendFile(path.join(__dirname, "/../dist/admin.html"))
    );
    app.use(express.static(path.join(__dirname, "/../dist")));

    app.get("/", (req, res) =>
        res.sendFile(path.join(__dirname, "/../dist/public.html"))
    );
}

const port = process.env.PORT || PORT;
app.listen(port, function() {
    console.log(`Listening on port ${port}!`);
});

// MYB DATA //////////////
//////////////////////////

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

// CRON

const resetDataCron = new CronJob("00 00 00 * * *", () => {
    winston.verbose("Resetting day data");
    try {
        resetDayMybData();
    } catch (e) {
        winston.error("Error when resetting day data", { e });
    }
});
resetDataCron.start();

function resetDayMybData() {
    let yesterdayMybData = getCurrentMybData();

    let newData = {
        ...yesterdayMybData,
        todayUsers: 0,
        todayOrders: 0,
        todayExhibitors: 0,
        todayClients: 0,
        todayProdOccurrences: 0,
        todayOpenOccurrences: 0,
        date: getTodayMidnight(),
    };
    delete newData.id;

    winston.verbose("Inserting new row in MYB data", newData);
    db.get("myb_data")
        .insert(newData)
        .write();
}

// HELPERS

function getTodayMidnight() {
    return new Date().setHours(0, 0, 0, 0);
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

////

process.on("SIGINT", () => {
    console.log("Bye bye!");
    process.exit();
});
