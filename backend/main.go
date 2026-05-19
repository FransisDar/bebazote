package main

import (
	"encoding/json"
	"log"
	"net/http"
	"time"
)

type quoteRequest struct {
	Pickup   string `json:"pickup"`
	Dropoff  string `json:"dropoff"`
	RideType string `json:"rideType"`
}

type quoteResponse struct {
	ETAMinutes int     `json:"etaMinutes"`
	PriceKES   int     `json:"priceKes"`
	DistanceKM float64 `json:"distanceKm"`
}

type rideRequest struct {
	Pickup   string `json:"pickup"`
	Dropoff  string `json:"dropoff"`
	RideType string `json:"rideType"`
	RiderID  string `json:"riderId"`
}

type rideResponse struct {
	ID     string `json:"id"`
	Status string `json:"status"`
}

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", handleHealth)
	mux.HandleFunc("/quotes", handleQuote)
	mux.HandleFunc("/rides", handleRideRequest)

	server := &http.Server{
		Addr:              ":8080",
		Handler:           withCORS(mux),
		ReadHeaderTimeout: 5 * time.Second,
	}

	log.Println("bebazote backend listening on http://localhost:8080")
	log.Fatal(server.ListenAndServe())
}

func handleHealth(w http.ResponseWriter, _ *http.Request) {
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

func handleQuote(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	var req quoteRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}

	baseFare := 620
	switch req.RideType {
	case "boda":
		baseFare = 385
	case "comfort":
		baseFare = 835
	}

	writeJSON(w, http.StatusOK, quoteResponse{
		ETAMinutes: 5,
		PriceKES:   baseFare,
		DistanceKM: 6.8,
	})
}

func handleRideRequest(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		return
	}

	var req rideRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "invalid request body", http.StatusBadRequest)
		return
	}
	if req.Pickup == "" || req.Dropoff == "" {
		http.Error(w, "pickup and dropoff are required", http.StatusBadRequest)
		return
	}

	writeJSON(w, http.StatusAccepted, rideResponse{
		ID:     "ride_demo_001",
		Status: "matching_driver",
	})
}

func withCORS(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

func writeJSON(w http.ResponseWriter, status int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(payload); err != nil {
		log.Printf("write response: %v", err)
	}
}
