/* eslint-disable no-unused-vars */

module.exports = class SSEService {
    notify({ data, event }) {
        return Promise.reject(new Error("not implemented"));
    }
};
