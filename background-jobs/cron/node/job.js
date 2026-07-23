import cron from "node-cron";
import http from "node:http";

const schedule = process.env.CRON_SCHEDULE ?? "*/5 * * * *";
const statusPort = Number(process.env.STATUS_PORT ?? 3000);

// Set at boot (not left unset) so the status endpoint doesn't report
// "unreachable" for however long it takes the schedule to first fire —
// node-cron only runs on its cron expression, unlike the other language
// templates' loops which run once immediately at start.
let lastRun = Date.now();

cron.schedule(schedule, () => {
  console.log("Node cron job ran", new Date().toISOString());
  lastRun = Date.now();
});

console.log(`Node cron scheduled: ${schedule}`);

// Reports whether the scheduler is still ticking, not just whether the
// process is running (Bzync Cloud's compute already checks that
// separately via container state + crash-loop detection) — same
// reachable/unreachable JSON convention as the redis/garage/seaweedfs
// templates' status sidecar. Cron expressions (unlike the other
// templates' fixed intervals) have no simple numeric period to compare
// against without a cron-parser dependency, so this uses a generous fixed
// staleness window instead — good enough to catch a genuinely stuck
// scheduler without false positives on infrequent schedules.
const staleAfterMs = 24 * 60 * 60 * 1000;

http
  .createServer((req, res) => {
    const stale = Date.now() - lastRun > staleAfterMs;
    res.writeHead(stale ? 503 : 200, { "Content-Type": "application/json" });
    res.end(
      JSON.stringify({
        status: stale ? "error" : "ok",
        service: "cron",
        cron: stale ? "unreachable" : "reachable",
        lastRun: new Date(lastRun).toISOString(),
      })
    );
  })
  .listen(statusPort);
