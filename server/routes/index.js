const messages = require("./messages.js");

module.exports = app => {
    app.use("/api/messages", messages);
};
