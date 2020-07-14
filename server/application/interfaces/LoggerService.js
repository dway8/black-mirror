/* eslint-disable no-unused-vars */

module.exports = class LoggerService {
    error(_msg, _obj) {
        return Promise.reject(new Error("not implemented"));
    }
};
