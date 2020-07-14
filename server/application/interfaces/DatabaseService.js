module.exports = class DatabaseService {
    constructor() {
        this.messageRepository = null;
    }

    initDatabase() {
        return Promise.reject(new Error("not implemented"));
    }
};
