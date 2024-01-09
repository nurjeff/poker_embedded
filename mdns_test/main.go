package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"time"

	"github.com/grandcat/zeroconf"
)

func runServer() {
	service, err := zeroconf.Register(
		"pokerService",
		"_http._tcp",
		"local.",
		8080,
		[]string{"txtv=0.1", "lo=1", "la=2"},
		nil,
	)
	if err != nil {
		log.Fatal(err)
	}
	defer service.Shutdown()

	// Keep the service alive until terminated
	select {}
}

func runClient() {
	resolver, err := zeroconf.NewResolver(nil)
	if err != nil {
		log.Fatal(err)
	}

	entries := make(chan *zeroconf.ServiceEntry)
	go func(results <-chan *zeroconf.ServiceEntry) {
		for entry := range results {
			fmt.Printf("Found service: %+v\n", entry)
		}
		log.Println("No more services.")
	}(entries)

	ctx, cancel := context.WithTimeout(context.Background(), time.Second*5)
	defer cancel()
	err = resolver.Browse(ctx, "_http._tcp", "local.", entries)
	if err != nil {
		log.Fatal(err)
	}
	<-ctx.Done()
}

func main() {
	serverMode := flag.Bool("server", false, "Run in server mode")
	clientMode := flag.Bool("client", false, "Run in client mode")
	flag.Parse()

	if *serverMode {
		runServer()
	} else if *clientMode {
		runClient()
	} else {
		fmt.Println("Please specify --server or --client")
	}
}
