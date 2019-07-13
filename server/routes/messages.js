const Router = require("express-promise-router");
const db = require("../db/index.js");
const logger = require("../logger");
const winston = logger.loggers.general;

const router = new Router();

router.get("/admin", async (req, res) => {
    const messages = await getAllMessages();
    res.send(messages);
});

module.exports = router;

async function getAllMessages() {
    let messages = [];

    try {
        winston.verbose("db", { db });
        const { rows } = await db.query(
            "SELECT id, title, content, active, ROUND((EXTRACT(epoch FROM created_at)* 1000)) as created_at FROM messages"
        );
        messages = rows.map(row => {
            return dbToMessagesKeys(row);
        });
    } catch (err) {
        winston.error(err.stack);
    }
    return messages;
}

function dbToMessagesKeys(data) {
    const dbToMessages = {
        created_at: "createdAt",
    };
    const newData = {};

    for (let [key, value] of Object.entries(data)) {
        const newKey = dbToMessages[key] || key;
        newData[newKey] = value;
    }

    return newData;
}
