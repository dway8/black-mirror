module.exports = class DatabaseService {
    constructor() {
        this.messageRepository = null;
        this.mybDataRepository = null;
        this.mybOpeningRepository = null;
    }

    initDatabase() {
        return Promise.reject(new Error("not implemented"));
    }
};
