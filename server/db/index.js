const { Client } = require("pg");
// const logger = require("../logger");
// const winston = logger.loggers.general;

const client = new Client({
    connectionString: process.env.DATABASE_URL,
    ssl: true,
});

client.connect();

module.exports = {
    query: (text, params) => {
        return client.query(text, params);
    },
};
