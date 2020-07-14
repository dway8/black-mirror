const SSEService = require("../../application/interfaces/SSEService");
const { sse } = require("./sse.js");

module.exports = class ExpressSSEService extends SSEService {
    notify({ data, event }) {
        sse.send(data, event);
    }
};
