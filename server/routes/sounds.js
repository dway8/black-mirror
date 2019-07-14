const Router = require("express-promise-router");
const db = require("../db/index.js");
const logger = require("../logger");
const winston = logger.loggers.general;
const requireAuth = require("../middlewares/auth.js");
const { sse } = require("./sse.js");

const router = new Router();

// const NEW_ORDER = "new_order";
// const NEW_PROD_OCCURRENCE = "new_prod_occurrence";
// const NEW_USER = "new_user";

router.get("/admin", requireAuth, async (req, res) => {
    const sounds = await getAllSounds();
    res.send(sounds);
});

router.get("/admin/trigger/:id", requireAuth, async (req, res) => {
    const { id } = req.params;
    const { rows } = await db.query("SELECT url FROM sounds WHERE id = $1", [
        id,
    ]);
    if (rows.length > 0) {
        const url = rows[0].url;
        sse.send(url, "trigger-sound");
        res.send();
    }
});

async function getAllSounds() {
    let sounds = [];

    try {
        const { rows } = await db.query("SELECT * FROM sounds");
        sounds = rows;
    } catch (err) {
        winston.error(err.stack);
    }
    return sounds;
}

module.exports = router;
