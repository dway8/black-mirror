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
    winston.verbose("Received params from MYB", params);

    if (params.new_user) {
        handleNewUser();
    } else if (params.new_order && params.amount) {
        handleNewOrder(params);
    } else if (params.order_cancelled && params.amount) {
        handleOrderCancelled(params);
    } else if (params.prod_event) {
        handleProdEvent();
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

app.get("/myb_data", (req, res) => {
    const mybData = getCurrentMybData();
    res.json(mybData);
});

app.listen(PORT, function() {
    console.log(`Listening on port ${PORT}!`);
});

// MYB DATA //////////////
//////////////////////////

function handleNewUser() {
    const currentMybData = _.cloneDeep(getCurrentMybData());

    const totalUsers = currentMybData.totalUsers + 1;
    const todayUsers = currentMybData.todayUsers + 1;

    updateTodayMybData({ totalUsers, todayUsers }, currentMybData.id);
}

function handleNewOrder(params) {
    const currentMybData = _.cloneDeep(getCurrentMybData());

    const totalOrders = currentMybData.totalOrders + 1;
    const va = currentMybData.va + parseFloat(params.amount);
    const avgCart = Math.round(va / 100 / totalOrders);
    const todayOrders = currentMybData.todayOrders + 1;

    updateTodayMybData(
        { totalOrders, todayOrders, va, avgCart },
        currentMybData.id
    );
}

function handleOrderCancelled(params) {
    const currentMybData = _.cloneDeep(getCurrentMybData());

    const totalOrders = currentMybData.totalOrders - 1;
    const va = currentMybData.va - parseFloat(params.amount);
    const avgCart = Math.round(va / 100 / totalOrders);

    let todayOrders = currentMybData.todayOrders;
    const orderDate = new Date(params.date * 1000);
    if (orderDate >= getTodayMidnight()) {
        todayOrders = currentMybData.todayOrders - 1;
    }

    updateTodayMybData(
        { totalOrders, todayOrders, va, avgCart },
        currentMybData.id
    );
}

function handleProdEvent() {
    const currentMybData = _.cloneDeep(getCurrentMybData());

    const totalProdEvents = currentMybData.totalProdEvents + 1;

    updateTodayMybData({ totalProdEvents }, currentMybData.id);
}

// HELPERS

function getTodayMidnight() {
    return new Date().setHours(0, 0, 0, 0);
}

// DB

function getCurrentMybData() {
    const rows = db
        .get("myb_data")
        .orderBy(["date"], ["desc"])
        .value();

    let mybData;

    if (rows.length === 0) {
        mybData = db
            .get("myb_data")
            .insert({
                totalUsers: 0,
                todayUsers: 0,
                totalOrders: 0,
                todayOrders: 0,
                va: 0,
                avgCart: 0,
                totalProdEvents: 0,
                date: getTodayMidnight(),
            })
            .write();
    } else {
        mybData = rows[0];
    }
    return mybData;
}
function updateTodayMybData(newData, id) {
    winston.verbose("Updating today MYB data with", newData);
    db.get("myb_data")
        .getById(id)
        .assign(newData)
        .write();
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
    let yesterdayMybData = _.cloneDeep(getCurrentMybData());

    let newData = {
        ...yesterdayMybData,
        todayOrders: 0,
        todayUsers: 0,
        date: getTodayMidnight(),
    };
    delete newData.id;

    winston.verbose("Inserting new row in MYB data", newData);
    db.get("myb_data")
        .insert(newData)
        .write();
}
