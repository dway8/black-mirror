const Router = require("express-promise-router");
const SSE = require("express-sse");
let sse = new SSE(["Connected!"]);

const router = new Router();

router.get("/", (req, res) => {
    console.log("Init sse");

    req.on("close", () => {
        console.log("Connection closed");
        res.end();
        // res.emit("close");
    });

    return sse.init(req, res);
});

module.exports = { router, sse };
