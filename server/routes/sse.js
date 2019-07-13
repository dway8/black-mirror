const Router = require("express-promise-router");
const SSE = require("express-sse");
const sse = new SSE(["Connected!"]);

const router = new Router();

router.get("/", sse.init);

module.exports = { router, sse };
