"use strict";
var express = require("express");
var cors = require("cors");
var request = require("request");
const CronJob = require("cron").CronJob;
const logger = require("./logger");
const winston = logger.loggers.general;
const path = require("path");
const auth = require("basic-auth");
const SSE = require("express-sse");
const sse = new SSE(["Connected!"]);

const { Client } = require("pg");

const db = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: true,
});

db.connect();

//
// Constants
const PORT = 42425;
const isDevelopment = process.env.NODE_ENV !== "production";
const secret = isDevelopment ? "secret" : process.env.SECRET;

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

app.post("/mmi", (req, res) => {
    res.json({ message: "OK" });
    const params = req.body;
    winston.verbose("Received params from MYB", params);

    let event;
    if (params.new_user) {
        handleNewUser();
        event = "new_user";
    } else if (params.new_order && params.amount) {
        handleNewOrder(params);
        event = "new_order";
    } else if (params.order_cancelled && params.amount) {
        handleOrderCancelled(params);
        event = "order_cancelled";
    } else if (params.new_exhibitor) {
        handleNewExhibitor();
        event = "new_exhibitor";
    } else if (params.new_prod_occurrence) {
        handleNewProdOccurrence(params);
        event = "new_prod_occurrence";
    } else if (params.new_open_occurrence) {
        handleNewOpenOccurrence();
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
    let { id, todayUsers, totalUsers } = getCurrentMybData();

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
        todayVA,
        totalVA,
        avgCart,
    } = getCurrentMybData();

    todayOrders++;
    totalOrders++;
    todayVA = todayVA + parseFloat(params.amount);
    totalVA = totalVA + parseFloat(params.amount);
    avgCart = Math.round(totalVA / 100 / totalOrders);

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
            todayVA,
            totalVA,
            avgCart,
        },
        id
    );
}

function handleOrderCancelled(params) {
    let {
        id,
        todayOrders,
        totalOrders,
        todayVA,
        totalVA,
        avgCart,
    } = getCurrentMybData();

    totalOrders--;
    totalVA = totalVA - parseFloat(params.amount);
    avgCart = Math.round(totalVA / 100 / totalOrders);

    const orderDate = new Date(params.date * 1000);
    if (orderDate >= getTodayMidnight()) {
        todayVA = todayVA - parseFloat(params.amount);
        todayOrders--;
    }

    updateTodayMybData(
        { totalOrders, todayOrders, todayVA, totalVA, avgCart },
        id
    );
}

function handleNewExhibitor() {
    let { id, todayExhibitors, totalExhibitors } = getCurrentMybData();
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
    } = getCurrentMybData();

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
    let {
        id,
        todayOpenOccurrences,
        totalOpenOccurrences,
    } = getCurrentMybData();
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

async function getCurrentMybData() {
    try {
        const res = await db.query(
            "SELECT * FROM myb_data ORDER BY date DESC LIMIT 1"
        );
        return res.rows[0];
    } catch (err) {
        winston.error(err.stack);

        return null;
    }
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

process.on("SIGINT", () => {
    console.log("Bye bye!");
    process.exit();
});
