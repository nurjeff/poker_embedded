package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os/exec"
	"sync"
	"time"

	"github.com/gin-gonic/gin"
)

// Game State management
var gameState *GameState
var gameStateMutex *sync.Mutex

// Connector for ws2812 hardware controller
var arduinoController *ArduinoController

// State management
var lastIdleTime time.Time
var isIdle = false
var canChangeLights = true
var updating = false

func checkIdle() {
	for {
		if time.Since(lastIdleTime).Minutes() > 10 && !gameState.GameRunning && !isIdle {
			message := make(map[string]string)
			message["event"] = "idle"
			data, err := json.Marshal(&message)
			if err != nil {
				fmt.Println(err)
			}
			go SendData(data, false)

			arduinoController.TurnOffLED(2000)
			isIdle = true
			GlobalPlayer.Pause()
		}
		time.Sleep(time.Second * 1)
	}
}

func main() {
	gameStateMutex = &sync.Mutex{}
	writeMutex = &sync.Mutex{}

	// Reset idle
	lastIdleTime = time.Now()

	// Scan for Arduino and run
	arduinoController = NewArduinoController()
	go arduinoController.Run()
	go checkIdle()

	gin.SetMode(gin.ReleaseMode)
	port := flag.String("port", "49267", "Port to run the server on")
	flag.Parse()

	// Read config and setup base state
	gameConfig = readConfig("game_config.json")
	accentColor = gameConfig.AccentColor
	gameState = &GameState{GameRunning: false, TotalRounds: 0, CurrentGameId: 0, CurrentRoundId: 0, ElapsedSecondsThisRound: 0, CurrentAccentColor: accentColor}

	// Spin up audioplayer on default device and play music in loop
	var err error
	GlobalPlayer, err = NewPlayer("jazz.wav")
	if err != nil {
		fmt.Println(err)
	}

	// Wait for player to hook, then start music and sounds
	time.Sleep(time.Second * 2)
	if gameConfig.PlayMusic {
		GlobalPlayer.Resume()
	}

	if gameConfig.PlaySounds {
		go func() {
			time.Sleep(time.Second * 10)
			GlobalPlayer.PlayOneShot("welcome.wav")
		}()
	}

	r := gin.Default()
	// Setup Routes
	apiRoutes := r.Group("/api/v1/poker")
	{
		apiRoutes.GET("/config", func(c *gin.Context) {
			c.JSON(200, gameConfig)
		})
		apiRoutes.GET("/state", func(c *gin.Context) {
			c.JSON(200, gameState)
		})
		apiRoutes.GET("/awake", func(c *gin.Context) {
			sendAwake()
			c.JSON(200, gameState)
		})
		apiRoutes.POST("/start", handleStartGame)
		apiRoutes.POST("/stop", handleStopGame)
		apiRoutes.POST("/pause-resume", handlePauseResume)
		apiRoutes.POST("/color", changeAccentColor)
		apiRoutes.POST("/toggle-music", toggleMusic)
		apiRoutes.POST("/toggle-sounds", toggleSounds)
		apiRoutes.POST("/toggle-leds", toggleLeds)
		apiRoutes.POST("/next-round", nextRound)
		apiRoutes.POST("/prev-round", previousRound)
		apiRoutes.POST("/update-system", updateSystem)
		apiRoutes.POST("/create", createNewGameConfig)
		apiRoutes.POST("/update", updateGameConfig)
		apiRoutes.POST("/delete", deleteGameConfig)
		// Shutdown and reboot commands
		apiRoutes.POST("/shutdown", func(c *gin.Context) {
			GlobalPlayer.PlayOneShot("shutdown.wav")
			message := make(map[string]string)
			message["event"] = "shutdown"
			data, err := json.Marshal(&message)
			if err == nil {
				go SendData(data, true)
			}

			c.JSON(200, "")
			cmd := exec.Command("sudo", "shutdown", "now")

			arduinoController.WriteLED(Color{0, 0, 0}, 3000)
			canChangeLights = false
			time.Sleep(time.Second * 10)
			err = cmd.Run()
			if err != nil {
				fmt.Println("Error executing shutdown command:", err)
				return
			}

			fmt.Println("Shutdown command executed successfully")
		})
		apiRoutes.POST("/reboot", func(c *gin.Context) {
			GlobalPlayer.PlayOneShot("reboot.wav")
			message := make(map[string]string)
			message["event"] = "reboot"
			data, err := json.Marshal(&message)
			if err == nil {
				go SendData(data, true)
			}

			c.JSON(200, "")
			cmd := exec.Command("sudo", "reboot")

			arduinoController.WriteLED(Color{0, 0, 0}, 3000)
			canChangeLights = false
			time.Sleep(time.Second * 10)
			// Run the command
			err = cmd.Run()
			if err != nil {
				fmt.Println("Error executing reboot command:", err)
				return
			}

			fmt.Println("Reboot command executed successfully")
		})
	}

	// Add Websocket handler for rtc
	apiRoutes.GET("/ws", handleWebSocket)
	r.Run(fmt.Sprintf(":%s", *port))
}
