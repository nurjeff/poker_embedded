package main

import (
	"log"
	"os"
	"sync"
	"time"

	"github.com/faiface/beep"
	"github.com/faiface/beep/effects"
	"github.com/faiface/beep/speaker"
	"github.com/faiface/beep/wav"
)

type Player struct {
	streamer beep.StreamSeekCloser
	format   beep.Format
	ctrl     *beep.Ctrl
	mixer    *beep.Mixer
	mutex    sync.Mutex
	sr       beep.SampleRate
}

var GlobalPlayer *Player

func NewPlayer(filePath string) (*Player, error) {
	f, err := os.Open(filePath)
	if err != nil {
		return nil, err
	}

	sr := beep.SampleRate(48000)

	streamer, format, err := wav.Decode(f)
	if err != nil {
		f.Close()
		return nil, err
	}

	err = speaker.Init(sr, sr.N(time.Second/10))
	if err != nil {
		streamer.Close()
		return nil, err
	}

	mixer := &beep.Mixer{}
	ctrl := &beep.Ctrl{Streamer: beep.Loop(-1, streamer), Paused: true}

	volume := &effects.Volume{
		Streamer: ctrl,
		Base:     2,
		Volume:   -2.0,
		Silent:   false,
	}
	mixer.Add(volume)

	speaker.Play(mixer)

	return &Player{
		streamer: streamer,
		format:   format,
		ctrl:     ctrl,
		mixer:    mixer,
		sr:       sr,
	}, nil

}

func (p *Player) Pause() {
	p.mutex.Lock()
	defer p.mutex.Unlock()
	p.ctrl.Paused = true
}

func (p *Player) Resume() {
	p.mutex.Lock()
	defer p.mutex.Unlock()

	p.ctrl.Paused = false
}

func (p *Player) Stop() {
	p.mutex.Lock()
	defer p.mutex.Unlock()
	speaker.Clear()
	p.streamer.Close()
}

func (p *Player) PlayOneShot(filePath string) error {
	if !gameConfig.PlaySounds {
		return nil
	}
	go func() {
		f, _ := os.Open(filePath)
		defer f.Close()
		streamer, format, err := wav.Decode(f)
		if err != nil {
			f.Close()
			log.Fatal(err)
		}

		defer streamer.Close()

		p.mixer.Add(beep.Resample(3, format.SampleRate, p.sr, streamer))
		time.Sleep(time.Second * 10)
	}()
	return nil
}
