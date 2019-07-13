const messages = require("./messages.js");
const mybData = require("./mybData.js");
const sse = require("./sse.js");
const forecast = require("./forecast.js");
const tweets = require("./tweets.js");

module.exports = app => {
    app.use("/api/messages", messages);
    app.use("/api/myb-data", mybData);
    app.use("/api/sse", sse.router);
    app.use("/api/forecast", forecast);
    app.use("/api/last_tweet", tweets);
};
