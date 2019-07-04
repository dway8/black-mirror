/*
 * ---- WINSTON ----
 */
const util = require("util");
const winston = require("winston");
const { LEVEL, MESSAGE, SPLAT } = require("triple-beam");
require("winston-daily-rotate-file");

let isDev = process.env.CONTEXT !== "PROD";

let meta = {
    context: process.env.CONTEXT,
};

let default_output_format = winston.format.printf(msg => {
    let output = `[${meta.context}]\t[${
        msg.timestamp
    }]\t${msg.level.toUpperCase()}\t${msg.message}`;

    let rest = { ...msg };
    delete rest.timestamp;
    delete rest.level;
    delete rest.message;
    if (Object.keys(rest).length > 0) {
        output += ` ${JSON.stringify(rest)}`;
    }

    return output.replace(/\n/g, "\n\t\t\t\t\t\t");
});

let short_output_format = winston.format.printf(msg => {
    let output = `${msg.timestamp.split(" ")[1]}\t${msg.level.toUpperCase()}\t${
        msg.message
    }`;

    let rest = { ...msg };
    delete rest.timestamp;
    delete rest.level;
    delete rest.message;
    delete rest[LEVEL];
    delete rest[SPLAT];
    delete rest[MESSAGE];
    if (Object.keys(rest).length > 0) {
        output += `\n${util.inspect(rest, { colors: true })}`;
    }

    return output.replace(/\n/g, "\n\t\t\t");
});

let rotate_transport_defaults = {
    format: winston.format.combine(default_output_format),
    datePattern: "YYYY-MM-DD",
    zippedArchive: true,
};

let console_transport_defaults = {
    format: winston.format.combine(
        winston.format.colorize({ message: true }),
        isDev ? short_output_format : default_output_format
    ),
};

winston.configure({
    level: isDev ? "silly" : "verbose",
    format: winston.format.combine(
        winston.format.timestamp({
            format: "YYYY-MM-DD HH:mm:ss",
        }),
        winston.format.errors({ stack: true }),
        winston.format.splat()
    ),
    transports: [
        new winston.transports.Console({
            ...console_transport_defaults,
        }),
    ],
});

if (!isDev) {
    winston.add(
        new winston.transports.DailyRotateFile({
            filename: "logs/general-%DATE%.log",
            ...rotate_transport_defaults,
        })
    );
}

let access_logger_levels = {
    levels: {
        in: 0,
        out: 1,
    },
    colors: {
        in: "gray",
        out: "gray",
    },
};

winston.addColors(access_logger_levels.colors);

let access_logger = winston.createLogger({
    level: "out",
    levels: access_logger_levels.levels,
    format: winston.format.combine(
        winston.format.timestamp({
            format: "YYYY-MM-DD HH:mm:ss",
        })
    ),
    transports: [
        new winston.transports.Console({
            ...console_transport_defaults,
        }),
    ],
});

if (!isDev) {
    access_logger.add(
        new winston.transports.DailyRotateFile({
            filename: "logs/access-%DATE%.log",
            ...rotate_transport_defaults,
        })
    );
}

function create_access_logger_stream(level) {
    return {
        write: function(msg) {
            access_logger.log(level, msg.substr(0, msg.length - 1));
        },
    };
}

/*
 * ---- MODULE ----
 */
module.exports = {
    loggers: {
        general: winston,
        access: access_logger,
    },
};
