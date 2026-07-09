import os
import time
import schedule
from datetime import datetime, timezone


def run_job() -> None:
    print(f"Python cron job ran {datetime.now(timezone.utc).isoformat()}", flush=True)


schedule.every(int(os.getenv("CRON_INTERVAL_SECONDS", "300"))).seconds.do(run_job)
run_job()

while True:
    schedule.run_pending()
    time.sleep(1)
