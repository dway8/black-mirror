const Router = require("express-promise-router");
const request = require("request");
const logger = require("../logger");
const winston = logger.loggers.general;

const router = new Router();

router.get("/", (req, res) => {
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
                winston.error("Error:", error);
            } else if (response.statusCode !== 200) {
                winston.error("Status:", response.statusCode);
            } else {
                res.send(body);
            }
        }
    );
});

module.exports = router;
