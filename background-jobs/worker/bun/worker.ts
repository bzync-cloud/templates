const interval = Number(process.env.WORKER_INTERVAL_MS ?? 30000);
const statusPort = Number(process.env.STATUS_PORT ?? 3000);

let lastRun = Date.now();

// run() is a placeholder heartbeat, safe to scale to any replica count
// as-is since it does nothing but log. If you replace it with real work
// (polling a queue or a database table), make sure each item is claimed by
// exactly one replica before processing it (e.g. `SELECT ... FOR UPDATE
// SKIP LOCKED`, or your broker's own ack/visibility-timeout semantics) —
// without that, N replicas will each pick up and process the same item.
async function run() {
  console.log("Bun worker heartbeat", new Date().toISOString());
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

Bun.serve({
  port: statusPort,
  fetch() {
    const stale = Date.now() - lastRun > staleAfterMs;
    return Response.json(
      {
        status: stale ? "error" : "ok",
        service: "worker",
        worker: stale ? "unreachable" : "reachable",
        lastRun: new Date(lastRun).toISOString(),
      },
      { status: stale ? 503 : 200 }
    );
  },
});
