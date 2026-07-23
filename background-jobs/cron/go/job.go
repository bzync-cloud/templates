package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strconv"
	"sync/atomic"
	"time"
)

var lastRunUnixNano atomic.Int64

func main() {
	interval := 5 * time.Minute
	if s := os.Getenv("CRON_INTERVAL_SECONDS"); s != "" {
		if n, err := strconv.Atoi(s); err == nil {
			interval = time.Duration(n) * time.Second
		}
	}

	fmt.Printf("Go cron scheduled every %s\n", interval)

	runJob()
	go serveStatus(statusPort(), interval)

	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for range ticker.C {
		runJob()
	}
}

func runJob() {
	fmt.Printf("Go cron job ran %s\n", time.Now().UTC().Format(time.RFC3339))
	lastRunUnixNano.Store(time.Now().UnixNano())
}

func statusPort() string {
	if p := os.Getenv("STATUS_PORT"); p != "" {
		return p
	}
	return "3000"
}

// serveStatus reports whether the scheduler is still ticking, not just
// whether the process is running (Bzync Cloud's compute already checks
// that separately via container state + crash-loop detection) — same
// reachable/unreachable JSON convention as the redis/garage/seaweedfs
// templates' status sidecar. Unlike those, there's no separate backing
// service to probe: the check is "has runJob() fired recently enough,
// given the configured interval."
func serveStatus(port string, interval time.Duration) {
	staleAfter := interval*2 + 30*time.Second
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		last := time.Unix(0, lastRunUnixNano.Load())
		w.Header().Set("Content-Type", "application/json")
		if time.Since(last) > staleAfter {
			w.WriteHeader(http.StatusServiceUnavailable)
			_ = json.NewEncoder(w).Encode(map[string]string{
				"status": "error", "service": "cron", "cron": "unreachable",
				"lastRun": last.UTC().Format(time.RFC3339),
			})
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status": "ok", "service": "cron", "cron": "reachable",
			"lastRun": last.UTC().Format(time.RFC3339),
		})
	})
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		fmt.Fprintf(os.Stderr, "status server: %v\n", err)
	}
}
