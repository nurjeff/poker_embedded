# Embedded Poker Application 🃏

Complete little poker-timer application for home use.
Fun side project over christmas.

The Application is supposed to run on a TV or any other device present in your poker room 😄
The System is controlled via an app.

Big-Screen App
![Big-Screen App](https://github.com/nurjeff/poker_embedded/blob/main/tvapp.gif?raw=true)

Controller-App
![Controller App](https://github.com/nurjeff/poker_embedded/blob/main/app.gif?raw=true)

This project consists of 4 components:
- Raspberry Pi (or any other linux compatible device)
- Arduino Uno Rev 3
- WS2812 LED Strip (NeoPixel)
- An App for the system

The LEDs are animated to signal raises, pauses etc.
Everything can be configured via the App and the data is stored persistently.
Uses mDNS to find the "Server" running on the Pi automatically from the App.

The software on the Pi has a few components:
- A "backend" written in Go serving an HTTP webservice with WebSockets for communication to the app and the frontend
- The frontend, which is a flutter application running on a minimal wayland compositor. I'm using sway for this (https://github.com/swaywm/sway).
- Asahi running for mDNS discovery

The Flutter app running on the Raspberry is not a generic Linux app since performance is horrendous with a whole desktop running. To solve this, im using the fantastic flutter-elinux library developed by Sony (https://github.com/sony/flutter-elinux) to run flutter with specialized bindings directly on top of the wayland compositor without useless overhead created by X11 or GTK. This lessens CPU/GPU usage 10x, from 80-100% to just 5-10% rendering to a 1080p@60 display (4K works too!).
The app also supports sounds and music for audio-cues and background ambience.

The wiring is done like this:

![Wiring](https://github.com/nurjeff/poker_embedded/blob/main/circuit.png?raw=true)

The Arduino is controlled via serial and animates the leds, since the WS2812 led strips are individually addressable.

This is definitely not a best-pratice project, in fact the whole code is obviously pretty hacky and dirty since i just did this for fun over the holidays and also as a christmas present. But maybe it serves as inspiration!