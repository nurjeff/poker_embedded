#include <Adafruit_NeoPixel.h>

#define PIN            6 
#define NUMPIXELS      30 
#define UPDATE_FREQ    10 

Adafruit_NeoPixel strip = Adafruit_NeoPixel(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);

void setup() {
  strip.begin();
  strip.show();
  Serial.begin(9600);
}

void loop() {
  if (Serial.available() > 0) {
    String input = Serial.readStringUntil('\n');

    int firstComma = input.indexOf(',');
    int secondComma = input.indexOf(',', firstComma + 1);
    int thirdComma = input.indexOf(',', secondComma + 1);

    int targetRed = input.substring(0, firstComma).toInt();
    int targetGreen = input.substring(firstComma + 1, secondComma).toInt();
    int targetBlue = input.substring(secondComma + 1, thirdComma).toInt();
    int totalDuration = input.substring(thirdComma + 1).toInt();

    animateStrip(targetRed, targetGreen, targetBlue, totalDuration);
  }
}

void animateStrip(int targetRed, int targetGreen, int targetBlue, int totalDuration) {
  int steps = totalDuration / UPDATE_FREQ;
  int pixelStartDelay = steps / NUMPIXELS;

  for (int step = 0; step <= steps; step++) {
    for (int i = 0; i < strip.numPixels(); i++) {
      int pixelStep = step - (i * pixelStartDelay);
      if (pixelStep >= 0) {
        if (pixelStep > steps) {
          pixelStep = steps;
        }

        uint32_t currentColor = strip.getPixelColor(i);
        int currentRed = (int)(currentColor >> 16);
        int currentGreen = (int)(currentColor >> 8 & 0xFF);
        int currentBlue = (int)(currentColor & 0xFF);

        int newRed = (int)(currentRed + ((targetRed - currentRed) * (float)pixelStep / steps));
        int newGreen = (int)(currentGreen + ((targetGreen - currentGreen) * (float)pixelStep / steps));
        int newBlue = (int)(currentBlue + ((targetBlue - currentBlue) * (float)pixelStep / steps));

        strip.setPixelColor(i, newRed, newGreen, newBlue);
      }
    }
    strip.show();
    delay(UPDATE_FREQ);
  }

  for (int i = 0; i < strip.numPixels(); i++) {
    strip.setPixelColor(i, targetRed, targetGreen, targetBlue);
  }
  strip.show();
}
