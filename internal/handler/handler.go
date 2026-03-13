package handler

import (
	"encoding/json"
	"net/http"
	"time"
)

// HealthCheck возвращает статус здоровья приложения
func HealthCheck(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"status":    "healthy",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}

// Info возвращает информацию о приложении
func Info(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"name":        "argocd-go-example",
		"version":     "1.0.0",
		"description": "Пример Go-приложения для развёртывания через ArgoCD",
		"timestamp":   time.Now().UTC().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(response)
}
