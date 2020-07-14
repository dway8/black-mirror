const auth = require("basic-auth");
const logger = require("../logger");
const winston = logger.loggers.general;

const isDevelopment = process.env.NODE_ENV !== "production";
const secret = isDevelopment ? "secret" : process.env.SECRET;
function requireAuth(req, res, next) {
    var credentials = auth(req);

    // Check credentials
    if (!credentials || !checkCredentials(credentials.name, credentials.pass)) {
        winston.verbose("Wrong credentials");
        res.statusCode = 401;
        res.setHeader("WWW-Authenticate", 'Basic realm="example"');
        res.end("Access denied");
    } else {
        next();
    }
}

function checkCredentials(name, pass) {
    return name === "adminSpottt" && pass === secret;
}

module.exports = { requireAuth };
