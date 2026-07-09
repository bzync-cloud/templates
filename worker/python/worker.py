import os
import time
from datetime import datetime, timezone


interval = int(os.getenv("WORKER_INTERVAL_SECONDS", "30"))

while True:
    print(f"Python worker heartbeat {datetime.now(timezone.utc).isoformat()}", flush=True)
    time.sleep(interval)
