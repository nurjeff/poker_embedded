package main

import (
	"fmt"
	"strings"
	"sync"
	"time"

	"go.bug.st/serial"
	"go.bug.st/serial/enumerator"
)

type ArduinoController struct {
	portName         string
	port             serial.Port
	currentColor     Color
	colorChangeMutex *sync.Mutex
	previousColor    Color
}

func NewArduinoController() *ArduinoController {
	return &ArduinoController{colorChangeMutex: &sync.Mutex{}}
}

var colorWhite Color = Color{Red: 255, Green: 255, Blue: 255}
var colorDimWhite Color = Color{Red: 10, Green: 10, Blue: 10}
var accentColor Color = Color{Red: 182, Green: 82, Blue: 0}

func AnimateStart() {
	time.Sleep(time.Second * 2)
	arduinoController.WriteLED(colorWhite, 1000)
	time.Sleep(time.Millisecond * 1500)
	arduinoController.WriteLED(accentColor, 1000)
}

func (ac *ArduinoController) Run() {
	for {
		if ac.port == nil {
			fmt.Println("Scanning for Arduino...")
			err := ac.connect()
			if err != nil {
				fmt.Println("Error:", err)
				time.Sleep(1 * time.Second)
				continue
			}
			go AnimateStart()
		}

		if _, err := ac.port.Write([]byte("")); err != nil {
			fmt.Println("Lost connection, attempting to reconnect...")
			ac.port = nil
			continue
		}

		time.Sleep(5 * time.Second)
	}
}

func (ac *ArduinoController) TurnOffLED(duration int) {
	ac.WriteLED(Color{Red: 0, Green: 0, Blue: 0}, duration)
}

func (ac *ArduinoController) FlashColor(color Color, setAccent bool) {
	ac.WriteLED(color, 500)
}

func (ac *ArduinoController) WriteLED(color Color, duration int) {
	if ac.port == nil {
		fmt.Println("Arduino not connected")
		return
	}
	if !canChangeLights {
		return
	}
	if !gameConfig.EnableLEDs {
		ac.colorChangeMutex.Lock()
		defer ac.colorChangeMutex.Unlock()
		command := fmt.Sprintf("%d,%d,%d,%d\n", 0, 0, 0, 1000)
		_, err := ac.port.Write([]byte(command))
		if err == nil {
			time.Sleep(time.Duration(duration) * time.Millisecond)
			ac.previousColor = ac.currentColor
			ac.currentColor = color
		}
		return
	}

	go func() error {
		ac.colorChangeMutex.Lock()
		defer ac.colorChangeMutex.Unlock()
		command := fmt.Sprintf("%d,%d,%d,%d\n", color.Red, color.Green, color.Blue, duration)
		_, err := ac.port.Write([]byte(command))
		if err == nil {
			time.Sleep(time.Duration(duration) * time.Millisecond)
			ac.previousColor = ac.currentColor
			ac.currentColor = color
		}
		return err
	}()
}

func (ac *ArduinoController) connect() error {
	portName, err := findArduinoPort()
	if err != nil {
		return err
	}

	mode := &serial.Mode{
		BaudRate: 9600,
	}
	port, err := serial.Open(portName, mode)
	if err != nil {
		return err
	}

	ac.port = port
	ac.portName = portName
	fmt.Println("Connected to Arduino on port", portName)
	return nil
}

func findArduinoPort() (string, error) {
	ports, err := enumerator.GetDetailedPortsList()
	if err != nil {
		return "", err
	}
	if len(ports) == 0 {
		return "", fmt.Errorf("no serial ports found")
	}

	for _, port := range ports {
		if port.IsUSB && strings.Contains(port.VID, "2341") && strings.Contains(port.PID, "0043") {
			return port.Name, nil
		}
	}

	return "", fmt.Errorf("no Arduino port found")
}

func animateRoundChange(toPause bool) {
	go arduinoController.WriteLED(colorDimWhite, 500)
	time.Sleep(time.Millisecond * 500)
	go arduinoController.WriteLED(colorWhite, 2000)
	time.Sleep(time.Millisecond * 2200)
	if toPause {
		go arduinoController.WriteLED(colorWhite, 2000)
	} else {
		go arduinoController.WriteLED(colorDimWhite, 1000)
		time.Sleep(time.Second * 1)
		go arduinoController.WriteLED(accentColor, 3000)
	}
}
