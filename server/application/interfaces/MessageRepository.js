/* eslint-disable no-unused-vars */

module.exports = class MessageRepository {
    constructor() {}

    add(_message) {
        return Promise.reject(new Error("not implemented"));
    }

    getActive() {
        return Promise.reject(new Error("not implemented"));
    }

    delete(_message) {
        return Promise.reject(new Error("not implemented"));
    }

    getAll() {
        return Promise.reject(new Error("not implemented"));
    }
};
