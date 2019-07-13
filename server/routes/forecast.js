const Router = require("express-promise-router");
const request = require("request");
const logger = require("../logger");
const winston = logger.loggers.general;

const router = new Router();

router.get("/:coords", (req, res) => {
    const { coords } = req.params;
    request.get(
        {
            url: `https://api.darksky.net/forecast/537e53749d634ff0707fa5acadb2eab3/${coords}`,
            qs: req.query,
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
