"use strict";
var express = require("express");
var cors = require("cors");
var request = require("request");
const CronJob = require("cron").CronJob;
const logger = require("./logger");
const winston = logger.loggers.general;
const low = require("lowdb");
const lodashId = require("lodash-id");

const FileSync = require("lowdb/adapters/FileSync");
const adapter = new FileSync("db.json");
const db = low(adapter);
//
// Constants
const PORT = 42425;
const HOST = "0.0.0.0";

db._.mixin(lodashId);
const bodyParser = require("body-parser");

const _ = require("lodash");

db.defaults({ myb_data: [] }).write();

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

var forceReadDB = function(req, res, next) {
    db.read();
    next();
};

app.use(forceReadDB);

// ROUTES ////////////////
//////////////////////////

app.post("/mmi", (req, res) => {
    res.json({ message: "OK" });
    var params = req.body;
    winston.verbose("Received params:", params);

    if (params.new_user) {
        handleNewUser(params);
    } else if (params.new_order && params.amount) {
        handleNewOrder(params);
    } else if (params.order_cancelled && params.amount) {
        handleOrderCancelled(params);
    } else if (params.prod_event) {
        handleProdEvent(params);
    }
});

app.get("/forecast/:coords", (req, res) => {
    request.get(
        {
            url: `https://api.darksky.net/forecast/537e53749d634ff0707fa5acadb2eab3/${
                req.params.coords
            }`,
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

app.get("/last_tweet", (req, res) => {
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

app.listen(PORT, function() {
    console.log(`Listening on port ${PORT}!`);
});

// MYB DATA //////////////
//////////////////////////

function handleNewUser(params) {
    const currentRow = getCurrentMybData();
    var newData = {
        countUsers: currentRow.countUsers + parseInt(params.new_user),
    };

    if (isToday(currentRow)) {
        newData.todayUsers = currentRow.todayUsers + 1;
        updateTodayData(newData, currentRow.id);
    } else {
        winston.verbose("No insertion yet for today");
        newData.countOrders = currentRow.countOrders;
        newData.totalEvents = currentRow.totalEvents;
        newData.va = currentRow.va;
        newData.avgCart = currentRow.avgCart;
        newData.ads = currentRow.ads;
        newData.todayUsers = 1;
        insertNewData(newData);
    }
}

function handleNewOrder(params) {
    const currentRow = getCurrentMybData();

    const newCountOrders = currentRow.countOrders + 1;
    const newVa = currentRow.va + parseFloat(params.amount);
    const newAvgCart = Math.round(newVa / 100 / newCountOrders);
    const newData = {
        countOrders: newCountOrders,
        va: newVa,
        avgCart: newAvgCart,
    };

    if (isToday(currentRow)) {
        newData.todayOrders = currentRow.todayOrders + 1;
        updateTodayData(newData, currentRow.id);
    } else {
        winston.verbose("no insertion yet for today");
        newData.countUsers = currentRow.countUsers;
        newData.totalEvents = currentRow.totalEvents;
        newData.ads = currentRow.ads;
        newData.todayOrders = 1;
        insertNewData(newData);
    }
}

function handleOrderCancelled(params) {
    const currentRow = getCurrentMybData();

    const newCountOrders = currentRow.countOrders - 1;
    const newVa = currentRow.va - parseFloat(params.amount);
    const newAvgCart = Math.round(newVa / 100 / newCountOrders);
    const newData = {
        countOrders: newCountOrders,
        va: newVa,
        avgCart: newAvgCart,
    };

    if (isToday(currentRow)) {
        let newTodayOrders = currentRow.todayOrders;
        const orderDate = new Date(params.date * 1000);
        if (orderDate >= getTodayMidnight()) {
            newTodayOrders = currentRow.todayOrders - 1;
        }
        newData.todayOrders = newTodayOrders;

        updateTodayData(newData, currentRow.id);
    } else {
        winston.verbose("No insertion yet for today");
        newData.countUsers = currentRow.countUsers;
        newData.totalEvents = currentRow.totalEvents;
        newData.ads = currentRow.ads;
        newData.todayOrders = 0;
        insertNewData(newData);
    }
}

function handleProdEvent(params) {
    const currentRow = getCurrentMybData();

    const newTotalEvents = currentRow.totalEvents + parseInt(params.prod_event);
    const newData = {
        totalEvents: newTotalEvents,
    };

    if (isToday(currentRow)) {
        newData.prodEvents =
            currentRow.prodEvents + parseInt(params.prod_event);
        updateTodayData(newData, currentRow.id);
    } else {
        winston.verbose("No insertion yet for today");
        // no insertion yet for today
        newData.countUsers = currentRow.countUsers;
        newData.countOrders = currentRow.countOrders;
        newData.va = currentRow.va;
        newData.avgCart = currentRow.avgCart;
        newData.ads = currentRow.ads;
        insertNewData(newData);
    }
}

// HELPERS

function isToday(row) {
    const today = getTodayMidnight();
    const currentRowDate = new Date(row.createdAt).setHours(0, 0, 0, 0);

    return currentRowDate >= today;
}

function getTodayMidnight() {
    return new Date().setHours(0, 0, 0, 0);
}

// DB

function getCurrentMybData() {
    return db.get("myb_data").value()[0];
}
function updateTodayData(newData, id) {
    winston.verbose("Updating today MYB data", { newData });
    db.get("myb_data")
        .getById(id)
        .assign(newData)
        .write();
}

function insertNewData(newData) {
    winston.verbose("Inserting new row in MYB data", { newData });
    db.get("myb_data")
        .insert(newData)
        .write();
}

function resetDayData() {
    let currentRow = db.get("myb_data").value()[0];
    let yesterdayData = _.cloneDeep(currentRow);
    delete yesterdayData.createdAt;
    let newData = yesterdayData;
    newData.todayOrders = 0;
    newData.todayUsers = 0;
    newData.todayAds = 0;
    insertNewData(newData);
}
// CRON

const resetDataCron = new CronJob("00 00 00 * * *", () => {
    winston.verbose("Resetting day data");
    try {
        resetDayData();
    } catch (e) {
        winston.error("Error when resetting day data", { e });
    }
});
resetDataCron.start();
