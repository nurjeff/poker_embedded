package main

import (
	"encoding/json"
	"fmt"
	"time"
)

type Color struct {
	Red   int `json:"r"`
	Green int `json:"g"`
	Blue  int `json:"b"`
}

type GameState struct {
	GameRunning                 bool      `json:"game_running"`
	TotalRounds                 int       `json:"total_rounds"`
	CurrentGameId               int       `json:"current_game_id"`
	CurrentRoundId              int       `json:"current_round_id"`
	ElapsedSecondsThisRound     int       `json:"elapsed_seconds_this_round"`
	StartTime                   time.Time `json:"start_time"`
	StartTimeRound              time.Time `json:"-"`
	CurrentRoundDurationSeconds int       `json:"current_round_duration_seconds"`
	Paused                      bool      `json:"paused"`
	CurrentSmallBlind           int       `json:"current_small_blind"`
	CurrentBigBlind             int       `json:"current_big_blind"`
	NextSmallBlind              int       `json:"next_small_blind"`
	NextBigBlind                int       `json:"next_big_blind"`
	IsPauseRound                bool      `json:"is_pause_round"`
	NextIsPauseRound            bool      `json:"next_is_pause_round"`
	CurrentAccentColor          Color     `json:"current_accent_color"`
	SkipFlag                    bool      `json:"-"`
	PrevFlag                    bool      `json:"-"`
}

var syncMessage []byte

// Main game state logic loop
func (g *GameState) Run() {
	message := map[string]string{"event": "sync"}
	data, _ := json.Marshal(&message)
	syncMessage = data

	gameStateMutex.Lock()
	g.StartTime = time.Now()
	g.CurrentRoundDurationSeconds = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].DurationMinutes * 60
	g.CurrentSmallBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].SmallBlind
	g.CurrentBigBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].BigBlind
	g.IsPauseRound = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].IsPause

	if (g.CurrentRoundId) > len(gameConfig.Games[g.CurrentGameId].Entries)-1 {
		g.NextSmallBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId-2].SmallBlind
		g.NextBigBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId-2].BigBlind
		g.NextIsPauseRound = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId-2].IsPause
	} else {
		g.NextSmallBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId+1].SmallBlind
		g.NextBigBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId+1].BigBlind
		g.NextIsPauseRound = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId+1].IsPause
	}

	fmt.Println(gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId+1].BigBlind)

	g.StartTimeRound = g.StartTime
	var pauseStartTime time.Time
	totalPauseDuration := 0

	gameStateMutex.Unlock()

	syncInterval := 2

	for {
		syncInterval--
		if syncInterval <= 0 {
			syncInterval = 2
			go SendData(syncMessage, false)
		}
		time.Sleep(time.Millisecond * 250)
		gameStateMutex.Lock()

		if !g.GameRunning {
			gameStateMutex.Unlock()
			g.resetGameState()
			return
		}

		if g.SkipFlag {
			g.SkipFlag = false
			g.StartTimeRound = time.Now()
			totalPauseDuration = 0
			g.ElapsedSecondsThisRound = 0
			g.TotalRounds++
			g.CurrentRoundId++

			if g.CurrentRoundId == len(gameConfig.Games[g.CurrentGameId].Entries) {
				g.CurrentRoundId -= 2
			}

			g.CurrentRoundDurationSeconds = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].DurationMinutes * 60

			g.CurrentSmallBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].SmallBlind
			g.CurrentBigBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].BigBlind
			g.IsPauseRound = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].IsPause

			if (g.CurrentRoundId) == len(gameConfig.Games[g.CurrentGameId].Entries)-1 {
				g.NextSmallBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId-1].SmallBlind
				g.NextBigBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId-1].BigBlind
				g.NextIsPauseRound = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId-1].IsPause
			} else {
				g.NextSmallBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId+1].SmallBlind
				g.NextBigBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId+1].BigBlind
				g.NextIsPauseRound = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId+1].IsPause
			}

			message := map[string]string{"event": "round_changed"}
			data, _ := json.Marshal(&message)
			go SendData(data, true)

			go animateRoundChange(gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].IsPause)
			gameStateMutex.Unlock()
			continue
		}

		if g.PrevFlag {
			g.PrevFlag = false
			if g.CurrentRoundId <= 0 {
				gameStateMutex.Unlock()
				continue
			}
			g.StartTimeRound = time.Now()
			totalPauseDuration = 0
			g.ElapsedSecondsThisRound = 0
			g.TotalRounds++
			g.CurrentRoundId--

			g.CurrentRoundDurationSeconds = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].DurationMinutes * 60

			g.CurrentSmallBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].SmallBlind
			g.CurrentBigBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].BigBlind
			g.IsPauseRound = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].IsPause

			if (g.CurrentRoundId) == len(gameConfig.Games[g.CurrentGameId].Entries)-1 {
				g.NextSmallBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId-1].SmallBlind
				g.NextBigBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId-1].BigBlind
				g.NextIsPauseRound = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId-1].IsPause
			} else {
				g.NextSmallBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId+1].SmallBlind
				g.NextBigBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId+1].BigBlind
				g.NextIsPauseRound = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId+1].IsPause
			}

			message := map[string]string{"event": "round_changed"}
			data, _ := json.Marshal(&message)
			go SendData(data, true)

			go animateRoundChange(gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].IsPause)
			gameStateMutex.Unlock()
			continue
		}

		if g.Paused {
			if pauseStartTime.IsZero() {
				pauseStartTime = time.Now()
			}
			gameStateMutex.Unlock()
			continue
		}

		if !pauseStartTime.IsZero() {
			totalPauseDuration += int(time.Since(pauseStartTime).Seconds())
			pauseStartTime = time.Time{}
		}

		g.ElapsedSecondsThisRound = int(time.Since(g.StartTimeRound).Seconds()) - totalPauseDuration

		if g.ElapsedSecondsThisRound >= gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].DurationMinutes*60 {
			g.StartTimeRound = time.Now()
			totalPauseDuration = 0
			g.ElapsedSecondsThisRound = 0
			g.TotalRounds++
			g.CurrentRoundId++

			if g.CurrentRoundId == len(gameConfig.Games[g.CurrentGameId].Entries) {
				g.CurrentRoundId -= 2
			}

			g.CurrentRoundDurationSeconds = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].DurationMinutes * 60

			g.CurrentSmallBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].SmallBlind
			g.CurrentBigBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].BigBlind
			g.IsPauseRound = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].IsPause

			if g.IsPauseRound {
				go GlobalPlayer.PlayOneShot("pauseround.wav")
			} else {
				go GlobalPlayer.PlayOneShot("raisenew.wav")
			}

			if (g.CurrentRoundId) == len(gameConfig.Games[g.CurrentGameId].Entries)-1 {
				g.NextSmallBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId-1].SmallBlind
				g.NextBigBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId-1].BigBlind
				g.NextIsPauseRound = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId-1].IsPause
			} else {
				g.NextSmallBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId+1].SmallBlind
				g.NextBigBlind = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId+1].BigBlind
				g.NextIsPauseRound = gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId+1].IsPause
			}

			message := map[string]string{"event": "round_changed"}
			data, _ := json.Marshal(&message)
			go SendData(data, true)

			go animateRoundChange(gameConfig.Games[g.CurrentGameId].Entries[g.CurrentRoundId].IsPause)
		}

		gameStateMutex.Unlock()
	}
}

func (g *GameState) resetGameState() {
	g.CurrentRoundId = 0
	g.CurrentGameId = 0
	g.ElapsedSecondsThisRound = 0
	g.TotalRounds = 0
}

type GameConfig struct {
	Games       []Game `json:"games"`
	AccentColor Color  `json:"accent_color"`
	PlayMusic   bool   `json:"play_music"`
	PlaySounds  bool   `json:"play_sounds"`
	EnableLEDs  bool   `json:"enable_leds"`
}

type Game struct {
	Name         string      `json:"name"`
	CanBeDeleted bool        `json:"can_be_deleted"`
	Entries      []GameEntry `json:"game_entries"`
}

type GameEntry struct {
	IsPause         bool `json:"is_pause"`
	DurationMinutes int  `json:"duration_minutes"`
	SmallBlind      int  `json:"small_blind"`
	BigBlind        int  `json:"big_blind"`
}

var defaultGameEntries []GameEntry = []GameEntry{
	{IsPause: false, DurationMinutes: 20, SmallBlind: 25, BigBlind: 50},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 50, BigBlind: 100},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 75, BigBlind: 150},
	{IsPause: true, DurationMinutes: 15, SmallBlind: 0, BigBlind: 0},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 100, BigBlind: 200},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 125, BigBlind: 250},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 150, BigBlind: 300},
	{IsPause: true, DurationMinutes: 15, SmallBlind: 0, BigBlind: 0},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 175, BigBlind: 350},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 200, BigBlind: 400},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 250, BigBlind: 500},
	{IsPause: true, DurationMinutes: 15, SmallBlind: 0, BigBlind: 0},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 300, BigBlind: 600},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 400, BigBlind: 800},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 500, BigBlind: 1000},
	{IsPause: true, DurationMinutes: 15, SmallBlind: 0, BigBlind: 0},
	{IsPause: false, DurationMinutes: 10, SmallBlind: 600, BigBlind: 1200},
	{IsPause: false, DurationMinutes: 10, SmallBlind: 700, BigBlind: 1500},
	{IsPause: false, DurationMinutes: 10, SmallBlind: 1000, BigBlind: 2000},
	{IsPause: true, DurationMinutes: 15, SmallBlind: 0, BigBlind: 0},
	{IsPause: false, DurationMinutes: 10, SmallBlind: 2500, BigBlind: 5000},
	{IsPause: false, DurationMinutes: 10, SmallBlind: 5000, BigBlind: 10000},
	{IsPause: false, DurationMinutes: 10, SmallBlind: 10000, BigBlind: 20000},
	{IsPause: true, DurationMinutes: 15, SmallBlind: 0, BigBlind: 0},
}

var defaultGameEntriesSecondary []GameEntry = []GameEntry{
	{IsPause: false, DurationMinutes: 20, SmallBlind: 25, BigBlind: 50},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 50, BigBlind: 100},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 75, BigBlind: 150},
	{IsPause: true, DurationMinutes: 15, SmallBlind: 0, BigBlind: 0},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 100, BigBlind: 200},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 125, BigBlind: 250},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 150, BigBlind: 300},
	{IsPause: true, DurationMinutes: 15, SmallBlind: 0, BigBlind: 0},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 175, BigBlind: 350},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 200, BigBlind: 400},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 225, BigBlind: 450},
	{IsPause: true, DurationMinutes: 15, SmallBlind: 0, BigBlind: 0},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 250, BigBlind: 500},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 300, BigBlind: 600},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 350, BigBlind: 700},
	{IsPause: true, DurationMinutes: 15, SmallBlind: 0, BigBlind: 0},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 400, BigBlind: 800},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 450, BigBlind: 900},
	{IsPause: false, DurationMinutes: 20, SmallBlind: 500, BigBlind: 1000},
	{IsPause: true, DurationMinutes: 15, SmallBlind: 0, BigBlind: 0},
	{IsPause: false, DurationMinutes: 10, SmallBlind: 600, BigBlind: 1200},
	{IsPause: false, DurationMinutes: 10, SmallBlind: 750, BigBlind: 1500},
	{IsPause: false, DurationMinutes: 10, SmallBlind: 1000, BigBlind: 2000},
	{IsPause: true, DurationMinutes: 15, SmallBlind: 0, BigBlind: 0},
}

func getDefaultGameConfig() GameConfig {
	var config GameConfig
	config.Games = []Game{}

	config.Games = append(config.Games, Game{Name: "Standard", CanBeDeleted: false, Entries: defaultGameEntries})
	config.Games = append(config.Games, Game{Name: "Alt", CanBeDeleted: false, Entries: defaultGameEntriesSecondary})
	config.AccentColor = Color{Red: 182, Green: 82, Blue: 0}
	config.PlayMusic = true
	config.PlaySounds = true
	config.EnableLEDs = true

	return config
}
