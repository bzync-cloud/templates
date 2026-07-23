package main

import (
	"encoding/json"
	"net/http"
	"os"

	"github.com/go-chi/chi/v5"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	r := chi.NewRouter()
	r.Get("/", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, map[string]string{"message": "Chi API running on Bzync Cloud"})
	})
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, map[string]string{"status": "ok"})
	})
	if err := http.ListenAndServe(":"+port, r); err != nil {
		panic(err)
	}
}

func writeJSON(w http.ResponseWriter, payload map[string]string) {
	w.Header().Set("content-type", "application/json")
	_ = json.NewEncoder(w).Encode(payload)
}
