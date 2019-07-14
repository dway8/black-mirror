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

router.get("/", requireAuth, async (req, res) => {
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

router.post("/admin/url", requireAuth, async (req, res) => {
    try {
        const { id, url } = req.body;
        winston.verbose(`Changing the url of sound ${id} to ${url}`);
        try {
            await db.query("UPDATE sounds SET url=$1 WHERE id=$2", [url, id]);

            const sounds = await getAllSounds();

            await pushSoundsToClients(sounds);
            res.json({ success: true, data: sounds });
        } catch (err) {
            winston.error(err.stack);
            res.send({
                success: false,
                error: "Une erreur s'est produite",
            });
        }
    } catch (e) {
        winston.error("Error while creating a message", { e });
        res.send({ success: false, error: "Une erreur s'est produite" });
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
async function pushSoundsToClients(sounds) {
    sse.send(sounds, "sounds-event");
}
module.exports = router;
