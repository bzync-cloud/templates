const interval = Number(process.env.WORKER_INTERVAL_MS ?? 30000);

async function run() {
  console.log("Node worker heartbeat", new Date().toISOString());
}

await run();
setInterval(run, interval);
