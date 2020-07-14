const MessageRepository = require("../../../application/interfaces/MessageRepository");

module.exports = class PostgresMessageRepository extends MessageRepository {
    constructor(db) {
        super();
        this.db = db;
    }

    async add(message) {
        try {
            await this.db.query(
                "INSERT INTO messages(title, content, active) VALUES($1, $2, $3)",
                [message.title, message.content, true]
            );
        } catch (error) {
            throw new Error("Error Occurred");
        }

        return message;
    }

    async getActive() {
        const messages = (await this.getAll()).filter(m => m.active);
        return messages;
    }

    async delete(studentId) {
        try {
            const studentIndex = this.students.findIndex(
                x => x.id === studentId
            );
            if (studentIndex !== -1) {
                this.students.splice(studentIndex, 1);
            }
        } catch (error) {
            throw new Error("Error Occurred");
        }

        return true;
    }

    async getById(studentId) {
        let student;
        try {
            const id = parseInt(studentId);
            student = this.students.find(x => x.id === id);
        } catch (err) {
            throw new Error("Error Occurred");
        }

        return student;
    }

    async getByEmail(studentEmail) {
        let student;
        try {
            student = this.students.find(x => x.email === studentEmail);
        } catch (err) {
            throw new Error("Error Occurred");
        }

        return student;
    }

    async getAll() {
        let messages = [];

        try {
            const { rows } = await this.db.query(
                "SELECT id, title, content, active, ROUND((EXTRACT(epoch FROM created_at)* 1000)) as created_at FROM messages"
            );
            messages = rows.map(row => {
                return this.dbToMessagesKeys(row);
            });
        } catch (err) {
            throw new Error("Error Occurred");
        }
        return messages;
    }

    dbToMessagesKeys(data) {
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
};
