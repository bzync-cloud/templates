import cron from "node-cron";

const schedule = process.env.CRON_SCHEDULE ?? "*/5 * * * *";

cron.schedule(schedule, () => {
  console.log("Node cron job ran", new Date().toISOString());
});

console.log(`Node cron scheduled: ${schedule}`);
