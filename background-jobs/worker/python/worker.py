import json
import os
import threading
import time
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

interval = int(os.getenv("WORKER_INTERVAL_SECONDS", "30"))
status_port = int(os.getenv("STATUS_PORT", "3000"))

last_run = time.monotonic()

# Reports whether the worker loop is still ticking, not just whether the
# process is running (Bzync Cloud's compute already checks that
# separately via container state + crash-loop detection) — same
# reachable/unreachable JSON convention as the redis/garage/seaweedfs
# templates' status sidecar.
stale_after = interval * 2 + 30


class StatusHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        stale = time.monotonic() - last_run > stale_after
        body = json.dumps(
            {
                "status": "error" if stale else "ok",
                "service": "worker",
                "worker": "unreachable" if stale else "reachable",
            }
        ).encode()
        self.send_response(503 if stale else 200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass  # Don't spam job logs with health check request lines.


def serve_status() -> None:
    ThreadingHTTPServer(("0.0.0.0", status_port), StatusHandler).serve_forever()


threading.Thread(target=serve_status, daemon=True).start()

while True:
    print(f"Python worker heartbeat {datetime.now(timezone.utc).isoformat()}", flush=True)
    last_run = time.monotonic()
    time.sleep(interval)
