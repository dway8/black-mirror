const { CronJob } = require("cron");
const worker = require("./reset.js");

const job = new CronJob({
    cronTime: "00 00 00 * * *", // everyday at midnight
    onTick: worker.start(),
    start: true,
    timeZone: "Europe/Paris",
});

job.start();
