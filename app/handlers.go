package main

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
)

func handleStartGame(c *gin.Context) {
	if updating {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	val := c.Query("config")

	parsed, succ := strconv.ParseInt(val, 10, 64)
	if succ != nil {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	if int(parsed) < 0 || int(parsed) > len(gameConfig.Games) {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	gameStateMutex.Lock()
	defer gameStateMutex.Unlock()
	if gameState.GameRunning {
		c.AbortWithStatus(http.StatusConflict)
		return
	}

	gameState = &GameState{GameRunning: true, CurrentGameId: int(parsed), StartTime: time.Now(), CurrentAccentColor: accentColor}
	go gameState.Run()

	message := make(map[string]string)
	message["event"] = "game_started"
	data, err := json.Marshal(&message)
	if err != nil {
		gameState = &GameState{CurrentAccentColor: accentColor}
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	go arduinoController.WriteLED(accentColor, 3000)

	GlobalPlayer.PlayOneShot("firststart.wav")

	go SendData(data, true)
	c.JSON(http.StatusOK, gameState)
}

func handleStopGame(c *gin.Context) {
	if updating {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	gameStateMutex.Lock()
	defer gameStateMutex.Unlock()
	if !gameState.GameRunning {
		c.AbortWithStatus(http.StatusConflict)
		return
	}

	gameState.GameRunning = false
	gameState.Paused = false

	message := make(map[string]string)
	message["event"] = "game_stopped"
	data, err := json.Marshal(&message)
	if err != nil {
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	go arduinoController.WriteLED(accentColor, 1000)

	go SendData(data, true)
	GlobalPlayer.PlayOneShot("game_stopped.wav")
	c.JSON(http.StatusOK, gameState)
}

func handlePauseResume(c *gin.Context) {
	if updating {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	gameStateMutex.Lock()
	defer gameStateMutex.Unlock()
	if !gameState.GameRunning {
		c.AbortWithStatus(http.StatusConflict)
		return
	}

	gameState.Paused = !gameState.Paused

	message := make(map[string]string)
	if gameState.Paused {
		message["event"] = "game_paused"
		go arduinoController.WriteLED(colorDimWhite, 2000)
		GlobalPlayer.PlayOneShot("game_paused.wav")
	} else {
		message["event"] = "game_resumed"
		go arduinoController.WriteLED(accentColor, 2000)
		GlobalPlayer.PlayOneShot("game_started.wav")
	}

	data, err := json.Marshal(&message)
	if err != nil {
		c.AbortWithStatus(http.StatusInternalServerError)
		return
	}

	sendAwake()

	go SendData(data, true)
	c.JSON(http.StatusOK, gameState)
}

func changeAccentColor(c *gin.Context) {
	if updating {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	color := Color{}
	if err := c.Bind(&color); err != nil {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	arduinoController.FlashColor(color, true)
	accentColor = color

	gameConfig.AccentColor = accentColor
	gameStateMutex.Lock()
	gameState.CurrentAccentColor = accentColor
	gameStateMutex.Unlock()
	go writeDefaultConfig("game_config.json", *gameConfig)

	b, _ := json.Marshal(&accentColor)

	message := make(map[string]string)
	message["event"] = "accent_changed"
	message["data"] = string(b)
	data, err := json.Marshal(&message)
	if err == nil {
		go SendData(data, true)
	}

	sendAwake()

	GlobalPlayer.PlayOneShot("color_changed.wav")

	c.JSON(http.StatusOK, "")
}

func nextRound(c *gin.Context) {
	if updating {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	gameStateMutex.Lock()
	defer gameStateMutex.Unlock()
	if !gameState.GameRunning {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	gameState.SkipFlag = true
	c.JSON(http.StatusOK, "")
	message := make(map[string]string)
	message["event"] = "skip_round"
	data, err := json.Marshal(&message)
	if err == nil {
		go SendData(data, true)
	}

	GlobalPlayer.PlayOneShot("skip_round.wav")

}

func createNewGameConfig(c *gin.Context) {
	if updating {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	game := Game{}
	if err := c.Bind(&game); err != nil {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	gameConfig.Games = append(gameConfig.Games, game)
	writeDefaultConfig("game_config.json", *gameConfig)
	c.JSON(http.StatusOK, &gameConfig)
}

func updateGameConfig(c *gin.Context) {
	if updating {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	game := Game{}
	if err := c.Bind(&game); err != nil {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	val := c.Query("config")
	parsed, succ := strconv.ParseInt(val, 10, 64)
	if succ != nil {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	if int(parsed) < 0 || int(parsed) > len(gameConfig.Games) {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	if !gameConfig.Games[parsed].CanBeDeleted {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	gameConfig.Games[parsed] = game
	writeDefaultConfig("game_config.json", *gameConfig)
	c.JSON(http.StatusOK, &gameConfig)
}

func deleteGameConfig(c *gin.Context) {
	if updating {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	val := c.Query("config")
	parsed, succ := strconv.ParseInt(val, 10, 64)
	if succ != nil {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	if int(parsed) < 0 || int(parsed) > len(gameConfig.Games) {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	if !gameConfig.Games[parsed].CanBeDeleted {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	gameConfig.Games = removeAtIndex[Game](gameConfig.Games, int(parsed))
	writeDefaultConfig("game_config.json", *gameConfig)
	c.JSON(http.StatusOK, &gameConfig)
}

func removeAtIndex[T any](s []T, index int) []T {
	if index < 0 || index >= len(s) {
		return s
	}
	return append(s[:index], s[index+1:]...)
}

func updateSystem(c *gin.Context) {
	if updating {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	gameStateMutex.Lock()
	defer gameStateMutex.Unlock()
	if gameState.GameRunning {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}

	updating = true
	arduinoController.WriteLED(Color{0, 0, 0}, 1000)
	arduinoController.WriteLED(Color{255, 0, 0}, 2000)
	canChangeLights = false
	c.JSON(http.StatusOK, "")

	message := make(map[string]string)
	message["event"] = "update_system"
	data, err := json.Marshal(&message)
	if err == nil {
		go SendData(data, true)
	}

	if err := runGitAndScript("/home/poker/src/poker_app/poker_tv", "deploy.sh"); err != nil {
		fmt.Println(err)
		message := make(map[string]string)
		message["event"] = "update_failed"
		data, err := json.Marshal(&message)
		if err == nil {
			go SendData(data, true)
		}
		updating = false
		canChangeLights = true
		return
	}
	if err := runGitAndScript("/home/poker/src/poker_app/app", "deploy.sh"); err != nil {
		fmt.Println(err)
		message := make(map[string]string)
		message["event"] = "update_failed"
		data, err := json.Marshal(&message)
		if err == nil {
			go SendData(data, true)
		}
		updating = false
		canChangeLights = true
		return
	}

	canChangeLights = true
}

func runGitAndScript(dir, scriptName string) error {
	err := os.Chdir(dir)
	if err != nil {
		return fmt.Errorf("failed to change directory: %w", err)
	}

	gitPullCmd := exec.Command("git", "pull")
	gitPullCmd.Stdout = os.Stdout
	gitPullCmd.Stderr = os.Stderr
	err = gitPullCmd.Run()
	if err != nil {
		return fmt.Errorf("git pull failed: %w", err)
	}

	scriptPath := filepath.Join(dir, scriptName)

	scriptCmd := exec.Command(scriptPath)
	scriptCmd.Stdout = os.Stdout
	scriptCmd.Stderr = os.Stderr
	err = scriptCmd.Run()
	if err != nil {
		return fmt.Errorf("script execution failed: %w", err)
	}

	return nil
}

func previousRound(c *gin.Context) {
	if updating {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	gameStateMutex.Lock()
	defer gameStateMutex.Unlock()
	if !gameState.GameRunning {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	gameState.PrevFlag = true
	c.JSON(http.StatusOK, "")
	message := make(map[string]string)
	message["event"] = "prev_round"
	data, err := json.Marshal(&message)
	if err == nil {
		go SendData(data, true)
	}

	GlobalPlayer.PlayOneShot("prev_round.wav")
}

func toggleMusic(c *gin.Context) {
	if updating {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	gameConfig.PlayMusic = !gameConfig.PlayMusic
	go writeDefaultConfig("game_config.json", *gameConfig)

	if gameConfig.PlayMusic {
		GlobalPlayer.Resume()
	} else {
		GlobalPlayer.Pause()
	}

	sendAwake()

	message := make(map[string]string)
	message["event"] = "music_changed"
	data, err := json.Marshal(&message)
	if err == nil {
		go SendData(data, true)
	}

	GlobalPlayer.PlayOneShot("music_changed.wav")
	c.JSON(http.StatusOK, gameConfig)
}

func toggleSounds(c *gin.Context) {
	if updating {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	gameConfig.PlaySounds = !gameConfig.PlaySounds
	go writeDefaultConfig("game_config.json", *gameConfig)

	sendAwake()

	message := make(map[string]string)
	message["event"] = "sounds_changed"
	data, err := json.Marshal(&message)
	if err == nil {
		go SendData(data, true)
	}

	if gameConfig.PlaySounds {
		GlobalPlayer.PlayOneShot("sounds_on.wav")
	}

	c.JSON(http.StatusOK, gameConfig)
}

func toggleLeds(c *gin.Context) {
	if updating {
		c.AbortWithStatus(http.StatusBadRequest)
		return
	}
	gameConfig.EnableLEDs = !gameConfig.EnableLEDs
	go arduinoController.WriteLED(accentColor, 1000)
	go writeDefaultConfig("game_config.json", *gameConfig)

	sendAwake()

	message := make(map[string]string)
	message["event"] = "leds_changed"
	data, err := json.Marshal(&message)
	if err == nil {
		go SendData(data, true)
	}

	GlobalPlayer.PlayOneShot("leds_changed.wav")

	c.JSON(http.StatusOK, gameConfig)
}

func sendAwake() {
	message := make(map[string]string)
	message["event"] = "awake"
	data, err := json.Marshal(&message)
	if err != nil {
		fmt.Println(err)
		return
	}
	go SendData(data, true)
}
