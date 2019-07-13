"use strict";
var express = require("express");
var cors = require("cors");
const path = require("path");
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

// CRON

// const resetDataCron = new CronJob("00 00 00 * * *", () => {
//     winston.verbose("Resetting day data");
//     try {
//         resetDayMybData();
//     } catch (e) {
//         winston.error("Error when resetting day data", { e });
//     }
// });
// resetDataCron.start();
//
// function resetDayMybData() {
//     let yesterdayMybData = getCurrentMybData();
//
//     let newData = {
//         ...yesterdayMybData,
//         todayUsers: 0,
//         todayOrders: 0,
//         todayExhibitors: 0,
//         todayClients: 0,
//         todayProdOccurrences: 0,
//         todayOpenOccurrences: 0,
//         date: getTodayMidnight(),
//     };
//     delete newData.id;
//
//     winston.verbose("Inserting new row in MYB data", newData);
//     db.get("myb_data")
//         .insert(newData)
//         .write();
// }

process.on("SIGINT", () => {
    console.log("Bye bye!");
    process.exit();
});
