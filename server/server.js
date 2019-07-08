"use strict";
var express = require("express");
var cors = require("cors");
var request = require("request");
const CronJob = require("cron").CronJob;
const logger = require("./logger");
const winston = logger.loggers.general;
const low = require("lowdb");
const lodashId = require("lodash-id");
const path = require("path");
const auth = require("basic-auth");
const SSE = require("express-sse");
const sse = new SSE(["Connected!"]);

const FileSync = require("lowdb/adapters/FileSync");
const adapter = new FileSync("db.json");
const db = low(adapter);
//
// Constants
const PORT = 42425;
const isDevelopment = process.env.NODE_ENV !== "production";
const secret = isDevelopment ? "secret" : process.env.SECRET;

db._.mixin(lodashId);
const bodyParser = require("body-parser");

const _ = require("lodash");

db.defaults({ myb_data: [], messages: [] }).write();

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

app.get("/api/myb_data", (req, res) => {
    const mybData = getCurrentMybData();
    res.json(mybData);
});

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
    } else if (params.new_exhibitor) {
        handleNewExhibitor();
    } else if (params.new_prod_occurrence) {
        handleNewProdOccurrence(params);
    } else if (params.new_open_occurrence) {
        handleNewOpenOccurrence();
    }

    const currentMybData = getCurrentMybData();

    sse.send(currentMybData, "MYB-event");
});

app.get("/api/messages", (req, res) => {
    const messages = db
        .get("messages")
        .filter(m => m.active)
        .value();
    res.json(messages);
});

app.get("/api/sse", sse.init);

////// ADMIN ROUTES /////////////////

app.route("/api/admin/messages")
    .all(requireLoggedUser)
    .get((req, res) => {
        const messages = db.get("messages").value();
        res.json(messages);
    })
    .post((req, res) => {
        try {
            const { title, content } = req.body;
            winston.verbose("Creating a new message with params", {
                title,
                content,
            });
            const newMessage = db
                .get("messages")
                .insert({
                    title,
                    content,
                    createdAt: new Date().getTime(),
                    active: true,
                })
                .write();

            res.json({ success: true, data: newMessage });
        } catch (e) {
            winston.error("Error while creating a message", { e });
            res.json({ success: false, error: "Une erreur s'est produite" });
        }
    });

app.get("/api/admin/messages/archive/:id", requireLoggedUser, (req, res) => {
    try {
        const id = req.params.id;
        winston.verbose(`Archiving message ${id}`);
        const newMessage = db
            .get("messages")
            .getById(id)
            .assign({ active: false })
            .write();

        res.json({ success: true, data: newMessage });
    } catch (e) {
        winston.error("Error while archiving a message", { e });
        res.json({ success: false, error: "Une erreur s'est produite" });
    }
});

/////////////////////////////////////

// Serving compiled elm client
if (!isDevelopment) {
    app.get("/admin", requireLoggedUser, (req, res) =>
        res.sendFile(path.join(__dirname, "/../dist/admin.html"))
    );

    app.get("/admin.html", requireLoggedUser, (req, res) =>
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

function handleNewUser() {
    let { id, todayUsers, totalUsers } = _.cloneDeep(getCurrentMybData());

    todayUsers++;
    totalUsers++;

    updateTodayMybData({ totalUsers, todayUsers }, id);
}

function handleNewOrder(params) {
    let {
        id,
        todayOrders,
        totalOrders,
        todayExhibitors,
        totalExhibitors,
        va,
        avgCart,
    } = _.cloneDeep(getCurrentMybData());

    todayOrders++;
    totalOrders++;
    va = va + parseFloat(params.amount);
    avgCart = Math.round(va / 100 / totalOrders);

    if (params.is_new_exhibitor) {
        todayExhibitors++;
        totalExhibitors++;
    }

    updateTodayMybData(
        {
            todayOrders,
            totalOrders,
            todayExhibitors,
            totalExhibitors,
            va,
            avgCart,
        },
        id
    );
}

function handleOrderCancelled(params) {
    let { id, todayOrders, totalOrders, va, avgCart } = _.cloneDeep(
        getCurrentMybData()
    );

    totalOrders--;
    va = va - parseFloat(params.amount);
    avgCart = Math.round(va / 100 / totalOrders);

    const orderDate = new Date(params.date * 1000);
    if (orderDate >= getTodayMidnight()) {
        todayOrders--;
    }

    updateTodayMybData({ totalOrders, todayOrders, va, avgCart }, id);
}

function handleNewExhibitor() {
    let { id, todayExhibitors, totalExhibitors } = _.cloneDeep(
        getCurrentMybData()
    );

    todayExhibitors++;
    totalExhibitors++;

    updateTodayMybData({ totalExhibitors, todayExhibitors }, id);
}

function handleNewProdOccurrence(params) {
    let {
        id,
        todayClients,
        totalClients,
        todayProdOccurrences,
        totalProdOccurrences,
    } = _.cloneDeep(getCurrentMybData());

    todayProdOccurrences++;
    totalProdOccurrences++;

    if (params.is_new_client) {
        todayClients++;
        totalClients++;
    }

    updateTodayMybData(
        {
            todayProdOccurrences,
            totalProdOccurrences,
            todayClients,
            totalClients,
        },
        id
    );
}

function handleNewOpenOccurrence() {
    let { id, todayOpenOccurrences, totalOpenOccurrences } = _.cloneDeep(
        getCurrentMybData()
    );

    todayOpenOccurrences++;
    totalOpenOccurrences++;

    updateTodayMybData(
        {
            todayOpenOccurrences,
            totalOpenOccurrences,
        },
        id
    );
}

// HELPERS

function requireLoggedUser(req, res, next) {
    var credentials = auth(req);

    // Check credentials
    if (!credentials || !checkCredentials(credentials.name, credentials.pass)) {
        winston.verbose("Wrong credentials");
        res.statusCode = 401;
        res.setHeader("WWW-Authenticate", 'Basic realm="example"');
        res.end("Access denied");
    } else {
        winston.verbose("Credentials OK");
        next();
    }
}

function checkCredentials(name, pass) {
    return name === "adminSpottt" && pass === secret;
}

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
                todayUsers: 0,
                totalUsers: 0,
                todayOrders: 0,
                totalOrders: 0,
                todayExhibitors: 0,
                totalExhibitors: 0,
                todayClients: 0,
                totalClients: 0,
                todayProdOccurrences: 0,
                totalProdOccurrences: 0,
                todayOpenOccurrences: 0,
                totalOpenOccurrences: 0,
                va: 0,
                avgCart: 0,
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

process.on("SIGINT", () => {
    console.log("Bye bye!");
    process.exit();
});
