package main

import (
	"os"
	"fmt"
	"log"
	"net/http"
	"sync/atomic"
	// "time" // commented out since time is not used anymore
)

var counter int64

// commented out since we are using atomic operations so we don't need this unused variable
// var lock sync.Mutex
// var leak = []string{}

func handler(w http.ResponseWriter, r *http.Request) {
	// we don't need locking since we will use atomic operations

	newVal := atomic.AddInt64(&counter, 1) // increment counter atomically
	// lock.Lock()
	// counter++
	// lock.Unlock()

	log.Printf("Handled request: path=%s counter=%d", r.URL.Path, newVal)

	// remove latency: this line forced every request to take at least 2 seconds
	// time.Sleep(2 * time.Second)

	// simulate memory leak by appending to a global slice
	// leak = append(leak, fmt.Sprintf("req-%d", counter))

	fmt.Fprintf(w, "counter=%d", newVal)
}

func health(w http.ResponseWriter, r *http.Request) {

	// the below if statement returned 500 when the current unix time was even

	// if time.Now().Unix()%2 == 0 {
	// 	w.WriteHeader(500)
	// 	return
	// }

	w.WriteHeader(http.StatusOK) // this will return status 200 OK
	w.Write([]byte("ok"))
}

func main() {

	f, err := os.OpenFile("/var/log/test2/app.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		log.Fatal(err)
	}
	defer f.Close()
	log.SetOutput(f)
	log.Println("App started")

	http.HandleFunc("/", handler)
	http.HandleFunc("/healthz", health)

	log.Println("Starting server on :8080")
	http.ListenAndServe(":8080", nil)
}
