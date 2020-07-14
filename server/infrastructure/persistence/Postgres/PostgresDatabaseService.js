const DatabaseService = require("../../../application/interfaces/DatabaseService");
const PostgresMessageRepository = require("./PostgresMessageRepository");

const { Client } = require("pg");

module.exports = class PostgresDatabaseService extends DatabaseService {
    constructor() {
        super();
        this.messageRepository = null;
    }

    async initDatabase() {
        const client = new Client({
            connectionString: process.env.DATABASE_URL,
            ssl: true,
        });

        client.connect();
        this.messageRepository = new PostgresMessageRepository(client);
    }
};
