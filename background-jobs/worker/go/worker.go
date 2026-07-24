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
	interval := 30 * time.Second
	if s := os.Getenv("WORKER_INTERVAL_MS"); s != "" {
		if n, err := strconv.Atoi(s); err == nil {
			interval = time.Duration(n) * time.Millisecond
		}
	}

	run()
	go serveStatus(statusPort(), interval)

	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for range ticker.C {
		run()
	}
}

// run is a placeholder heartbeat, safe to scale to any replica count as-is
// since it does nothing but log. If you replace it with real work (polling
// a queue or a database table), make sure each item is claimed by exactly
// one replica before processing it (e.g. `SELECT ... FOR UPDATE SKIP
// LOCKED`, or your broker's own ack/visibility-timeout semantics) —
// without that, N replicas will each pick up and process the same item.
func run() {
	fmt.Printf("Go worker heartbeat %s\n", time.Now().UTC().Format(time.RFC3339))
	lastRunUnixNano.Store(time.Now().UnixNano())
}

func statusPort() string {
	if p := os.Getenv("STATUS_PORT"); p != "" {
		return p
	}
	return "3000"
}

// serveStatus reports whether the worker loop is still ticking, not just
// whether the process is running (Bzync Cloud's compute already checks
// that separately via container state + crash-loop detection) — same
// reachable/unreachable JSON convention as the redis/garage/seaweedfs
// templates' status sidecar.
func serveStatus(port string, interval time.Duration) {
	staleAfter := interval*2 + 30*time.Second
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		last := time.Unix(0, lastRunUnixNano.Load())
		w.Header().Set("Content-Type", "application/json")
		if time.Since(last) > staleAfter {
			w.WriteHeader(http.StatusServiceUnavailable)
			_ = json.NewEncoder(w).Encode(map[string]string{
				"status": "error", "service": "worker", "worker": "unreachable",
				"lastRun": last.UTC().Format(time.RFC3339),
			})
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]string{
			"status": "ok", "service": "worker", "worker": "reachable",
			"lastRun": last.UTC().Format(time.RFC3339),
		})
	})
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		fmt.Fprintf(os.Stderr, "status server: %v\n", err)
	}
}
