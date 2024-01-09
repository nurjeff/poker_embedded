package main

import (
	"encoding/json"
	"io"
	"log"
	"os"
	"sync"
)

var gameConfig *GameConfig

// readConfig reads a JSON file and returns a GameConfig struct
func readConfig(filePath string) *GameConfig {
	var config GameConfig

	// Open the file
	file, err := os.Open(filePath)
	if err != nil {
		log.Printf("Error opening file, creating default config: %v\n", err)
		config = getDefaultGameConfig()
		writeDefaultConfig(filePath, config)
		return &config
	}
	defer file.Close()

	// Read and unmarshal JSON data
	data, err := io.ReadAll(file)
	if err != nil {
		log.Printf("Error reading file, creating default config: %v\n", err)
		config = getDefaultGameConfig()
		writeDefaultConfig(filePath, config)
		return &config
	}

	err = json.Unmarshal(data, &config)
	if err != nil {
		log.Printf("Error parsing JSON, creating default config: %v\n", err)
		config = getDefaultGameConfig()
		writeDefaultConfig(filePath, config)
		return &config
	}

	sendAwake()

	return &config
}

var writeMutex *sync.Mutex

// writeDefaultConfig writes the default game configuration to a JSON file
func writeDefaultConfig(filePath string, config GameConfig) {
	writeMutex.Lock()
	defer writeMutex.Unlock()
	file, err := os.Create(filePath)
	if err != nil {
		log.Fatalf("Error creating default config file: %v\n", err)
	}
	defer file.Close()

	encoder := json.NewEncoder(file)
	encoder.SetIndent("", "    ")
	err = encoder.Encode(config)
	if err != nil {
		log.Fatalf("Error writing to default config file: %v\n", err)
	}
}
