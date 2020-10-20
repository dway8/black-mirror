"use strict";
var express = require("express");
var cors = require("cors");
const path = require("path");
const mountRoutes = require("./infrastructure/web/routes");
const requireAuth = require("./infrastructure/web/middlewares/auth.js");
const projectDependencies = require("./config/projectDependencies");
const ErrorHandler = require("./frameworks/common/ErrorHandler");

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

// load app only if db is alive and kicking
projectDependencies.DatabaseService.initDatabase().then(
    () => {
        app.use(cors(corsOptions));

        // parse application/x-www-form-urlencoded
        app.use(bodyParser.urlencoded({ extended: false, limit: "50mb" }));

        // parse application/json
        app.use(bodyParser.json({ limit: "50mb" }));
        app.use(bodyParser.raw({ type: "text/plain" }));

        // load routes
        mountRoutes(projectDependencies, app);

        // generic error handler
        app.use(ErrorHandler(projectDependencies.LoggerService));

        // Serving compiled elm client
        if (!isDevelopment) {
            app.get("/admin", requireAuth, (_req, res) =>
                res.sendFile(path.join(__dirname, "/../dist/admin.html"))
            );

            app.get("/admin.html", requireAuth, (_req, res) =>
                res.sendFile(path.join(__dirname, "/../dist/admin.html"))
            );
            app.use(express.static(path.join(__dirname, "/../dist")));

            app.get("/", (_req, res) =>
                res.sendFile(path.join(__dirname, "/../dist/public.html"))
            );
        }

        const port = process.env.PORT || PORT;
        app.listen(port, function() {
            console.log(`Listening on port ${port}!`);
        });
    },
    err => {
        console.log(`db is not ready, err:${err}`);
    }
);

process.on("SIGINT", () => {
    console.log("Bye bye!");
    process.exit();
});
