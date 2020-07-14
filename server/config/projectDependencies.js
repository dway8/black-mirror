const PostgresDatabaseService = require("../infrastructure/PostgresDatabaseService");
const ExpressSSEService = require("../infrastructure/ExpressSSEService");
const WinstonLoggerService = require("../infrastructure/WinstonLoggerService");
const AuthMiddleware = require("../infrastructure/web/middlewares/auth");

module.exports = (() => {
    return {
        DatabaseService: new PostgresDatabaseService(),
        SSEService: new ExpressSSEService(),
        LoggerService: new WinstonLoggerService(),
        AuthMiddleware,
    };
})();
