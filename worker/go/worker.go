package main

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

func main() {
	interval := 30 * time.Second
	if s := os.Getenv("WORKER_INTERVAL_MS"); s != "" {
		if n, err := strconv.Atoi(s); err == nil {
			interval = time.Duration(n) * time.Millisecond
		}
	}

	run()
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for range ticker.C {
		run()
	}
}

func run() {
	fmt.Printf("Go worker heartbeat %s\n", time.Now().UTC().Format(time.RFC3339))
}
