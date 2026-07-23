package main

import (
	"fmt"
	"os"
	"strconv"
	"time"
)

func main() {
	interval := 5 * time.Minute
	if s := os.Getenv("CRON_INTERVAL_SECONDS"); s != "" {
		if n, err := strconv.Atoi(s); err == nil {
			interval = time.Duration(n) * time.Second
		}
	}

	fmt.Printf("Go cron scheduled every %s\n", interval)

	runJob()
	ticker := time.NewTicker(interval)
	defer ticker.Stop()
	for range ticker.C {
		runJob()
	}
}

func runJob() {
	fmt.Printf("Go cron job ran %s\n", time.Now().UTC().Format(time.RFC3339))
}
