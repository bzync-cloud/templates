import http from "node:http";

const interval = Number(process.env.WORKER_INTERVAL_MS ?? 30000);
const statusPort = Number(process.env.STATUS_PORT ?? 3000);

let lastRun = Date.now();

async function run() {
  console.log("Node worker heartbeat", new Date().toISOString());
  lastRun = Date.now();
}

await run();
setInterval(run, interval);

// Reports whether the worker loop is still ticking, not just whether the
// process is running (Bzync Cloud's compute already checks that
// separately via container state + crash-loop detection) — same
// reachable/unreachable JSON convention as the redis/garage/seaweedfs
// templates' status sidecar.
const staleAfterMs = interval * 2 + 30000;

http
  .createServer((req, res) => {
    const stale = Date.now() - lastRun > staleAfterMs;
    res.writeHead(stale ? 503 : 200, { "Content-Type": "application/json" });
    res.end(
      JSON.stringify({
        status: stale ? "error" : "ok",
        service: "worker",
        worker: stale ? "unreachable" : "reachable",
        lastRun: new Date(lastRun).toISOString(),
      })
    );
  })
  .listen(statusPort);
