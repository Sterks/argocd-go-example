package main

import (
	"log"
	"net/http"

	"github.com/derunov/argocd-go-example/internal/handler"
)

func main() {
	mux := http.NewServeMux()

	// Регистрируем обработчики
	mux.HandleFunc("/health", handler.HealthCheck)
	mux.HandleFunc("/api/info", handler.Info)

	port := ":8080"
	log.Printf("Starting server on port %s", port)
	if err := http.ListenAndServe(port, mux); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
