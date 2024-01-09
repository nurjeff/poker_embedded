package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"
)

var (
	upgrader = websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
	}
	clients      = make(map[*websocket.Conn]bool)
	clientsMutex sync.Mutex
)

func handleWebSocket(c *gin.Context) {
	w := c.Writer
	r := c.Request
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Failed to upgrade to WebSocket:", err)
		return
	}
	defer conn.Close()

	breakIdleFun()

	clientsMutex.Lock()
	clients[conn] = true
	fmt.Println("New WS connection:", conn.RemoteAddr(), conn.LocalAddr())
	clientsMutex.Unlock()

	conn.SetPongHandler(func(string) error {
		return conn.SetReadDeadline(time.Now().Add(60 * time.Second))
	})

	// Send pings periodically
	go func() {
		for {
			time.Sleep(15 * time.Second)
			clientsMutex.Lock()
			if _, ok := clients[conn]; ok {
				if err := conn.WriteMessage(websocket.PingMessage, nil); err != nil {
					log.Println("Ping failed:", err)
					conn.Close()
					delete(clients, conn)
				}
			}
			clientsMutex.Unlock()
		}
	}()

	message := make(map[string]string)
	message["event"] = "connection"
	data, err := json.Marshal(&message)
	if err != nil {
		fmt.Println(err)
	}
	go SendData(data, true)

	for {
		if _, _, err := conn.ReadMessage(); err != nil {
			clientsMutex.Lock()
			delete(clients, conn)
			clientsMutex.Unlock()
			break
		}
	}
}

func breakIdleFun() {
	isIdle = false

	if gameConfig.PlayMusic {
		if GlobalPlayer != nil {
			GlobalPlayer.Resume()
		} else {
			var err error
			GlobalPlayer, err = NewPlayer("jazz.wav")
			if err != nil {
				fmt.Println(err)
			}
		}
	}

	lastIdleTime = time.Now()
	if gameState.GameRunning {
		fmt.Println("breaking idle while running game?")
	} else {
		go arduinoController.WriteLED(accentColor, 1000)
	}
}

func SendData(data []byte, breakIdle bool) {
	if breakIdle {
		breakIdleFun()
	}
	clientsMutex.Lock()
	defer clientsMutex.Unlock()

	fmt.Println("Writing WS:", string(data))

	for client := range clients {
		if err := client.WriteMessage(websocket.TextMessage, data); err != nil {
			log.Printf("WebSocket send error: %s", err)
			client.Close()
			delete(clients, client)
		}
	}
}
