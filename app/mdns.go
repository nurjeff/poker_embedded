package main

import (
	"log"
	"time"

	"github.com/grandcat/zeroconf"
)

func runMDNS() {
	service, err := zeroconf.Register(
		"pokerService",
		"_http._tcp",
		"local.",
		49266,
		[]string{"txtv=0.1", "lo=1", "la=2"},
		nil,
	)
	if err != nil {
		log.Fatal(err)
	}
	defer service.Shutdown()

	for {
		time.Sleep(time.Minute)
	}
}
