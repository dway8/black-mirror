const db = require("./db/index.js");
const logger = require("./logger");
const winston = logger.loggers.general;
const { getCurrentMybData, mybDataToDbKeys } = require("./services/mybData.js");

async function resetDayMybData() {
    try {
        winston.verbose("Calling reset!");

        let yesterdayMybData = await getCurrentMybData();

        let newData = {
            ...yesterdayMybData,
            todayUsers: 0,
            todayOrders: 0,
            todayExhibitors: 0,
            todayClients: 0,
            todayProdOccurrences: 0,
            todayOpenOccurrences: 0,
            todayVA: 0,
        };
        delete newData.id;
        delete newData.date;
        newData = mybDataToDbKeys(newData);

        winston.verbose("Inserting new row in MYB data", newData);
        const keys = Object.keys(newData).join(", ");
        const values = Object.values(newData).join(", ");

        try {
            await db.query(`INSERT INTO myb_data(${keys}) VALUES(${values})`);
        } catch (err) {
            winston.error(err.stack);
        }
    } catch (e) {
        winston.error("Error when resetting day data", { e });
    }
}

resetDayMybData();
