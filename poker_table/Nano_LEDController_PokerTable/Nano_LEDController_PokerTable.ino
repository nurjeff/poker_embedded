#include <stdint.h>

//Initializing LED Pin
#define led_red 3
#define led_green 5
#define led_blue 6
#define UART_rx_size 64          // Nur Werte 2^n zulässig !
#define UART_rx_mask (UART_rx_size-1)
#define UART_Befehl_FiFo 16

int incomingByte =0;

struct UART_rx        //Receive Buffer
{
  uint8_t data[UART_rx_size];
  uint8_t read;
  uint8_t write;
}UART_rx= {{}, 0, 0};


/// @brief A struct that contains the three color channel R,G,B from 0-255
struct ColorSet{
  uint8_t R_value=0;
  uint8_t G_value=0;
  uint8_t B_value=0;
} PreviousColor,CurrentColor;


void setup() {
  
  //Declaring LED pins as output
  pinMode(led_red, OUTPUT);
  pinMode(led_green, OUTPUT);
  pinMode(led_blue, OUTPUT);
  Serial.begin(9600);
}
void loop() {

  while(Serial.available()>0){
    //read the incoming bytes
    incomingByte = Serial.read();
    UART_rx_in(incomingByte);
    Serial.println("ByteReceived: "+String(incomingByte,HEX));
        
  }
  UART_rx_work();
  Serial.println("readPointer: "+String(UART_rx.read,HEX)+"; writePointer: "+String(UART_rx.write,HEX));
  
  //delay(1000);
}

int UART_rx_in (uint8_t input){
  uint8_t temp= ((UART_rx.write+1)&UART_rx_mask); //
  if (temp==UART_rx.read)              //FiFo voll ?
  { 
    return 0;                   //return 0 -> Fifo voll
  }
  UART_rx.data[UART_rx.write]=(uint8_t)input;   //Daten ins Array legen
  UART_rx.write = temp;                //write auf nächste Specicherzelle schieben
  return 1;                     //return 1 -> Fifo abspeichern erfolgreich 
}

int UART_rx_out (void){
  if(UART_rx.read==UART_rx.write)         //FiFo leer ? 
    {
      return 0;                 //return 0 -> FiFo ist leer
    }
  int temp = (int)UART_rx.data[UART_rx.read];       //FiFo Inhalt in Data schreiben
  UART_rx.read = (UART_rx.read +1) & UART_rx_mask; //read auf nächste Speicherzelle schreiben
  return temp;                    //return Data
}

int UART_rx_empty(void){                //1 wenn FIFO leer, 0 wenn fifo voll
  if(UART_rx.read==UART_rx.write)         //FiFo leer ? 
  {
    return 1;                   //return 1 -> FiFo ist leer
  }
  else
  {
    return 0;
  }
}

int UART_rx_complete(void){
  int receivedBytes;
  //Finish Character 0x02 ?
  if(UART_rx.data[(UART_rx.write -1)&UART_rx_mask] == 0x02){
    //Start Character 0x01?
    if(UART_rx.data[(UART_rx.read)] == 0x01)
    {
      //Calculate distance between read and write counter
      if(UART_rx.write >= UART_rx.read){
        receivedBytes = (UART_rx.write-UART_rx.read);
      }
      else{
        receivedBytes = ((UART_rx_mask - UART_rx.read)+UART_rx.write);
      }

      //Distance between read and write == length?
      if(receivedBytes >= (UART_rx.data[(UART_rx.read+1)&UART_rx_mask]))
      {
        if(UART_rx.data[(UART_rx.write -1)&UART_rx_mask] != 0x02){//Error in current Buffer, erase complete Buffer
          while(UART_rx.read != UART_rx.write){
            UART_rx.read = (UART_rx.read+1)& UART_rx_mask;
          }
          return 0;
        }
       return 1;
      }      
    }
    else{
      //no start signal skip the bytes in buffer till next start bit
      if(UART_rx.read != UART_rx.write){
        while(UART_rx.data[(UART_rx.read)] != 0x01){
          UART_rx.read = (UART_rx.read+1)& UART_rx_mask;
        }    
      }
    }
  }
  return 0;
}

int UART_rx_work(){
  if(UART_rx_complete())
  {
    Serial.println("Command Complete");
    char Befehl[UART_Befehl_FiFo] = {};      // This will be the buffer for the command. { 0x01 LengthOfCommand(1Byte) Command(1Byte) DataByte(nByte) 0x02}
    
    //Fill the Command Buffer
    volatile int stop = UART_rx.data[((UART_rx.read+1)&UART_rx_mask)];
    for(int i=0; i<stop; i++) //UART_rx.data[UART_rx.read+1] = Command Length
    {
      char temp = UART_rx_out();
      Befehl[i] = temp;
    }

    //--------------Start of command evaluation-----------
    //comand is color set
    
    if(Befehl[2]==0x01){
      Serial.println("Command: 0x01");
      Serial.println("Colors: R:"+String(Befehl[3])+" G:"+String(Befehl[4])+" B:"+String(Befehl[3]));
      SetRgbValues(Befehl[3],Befehl[4],Befehl[5]);
    }

    if(Befehl[2]==0x02){
      Serial.println("Command: 0x02");
      SetBlinking(Befehl[3],Befehl[4],Befehl[5],Befehl[6],Befehl[7],Befehl[8],Befehl[9]);
    }


    return 1;
  }
  return 0;
}

/// @brief Set the connected LED strip into a blinking mode for a given duration and switch back to the original color afterwards. During that time, the color switches back and forth between the orignal set color and the entered color in the function. If the same color is set for blinking, no blinking will occur.
/// @param red red channel for the blinking color (0-255)
/// @param green green channel for the blinking color (0-255)
/// @param blue blue channel for the blinking color (0-255)
/// @param duration_MSB MSB of the duration in milli seconds.
/// @param duration_LSB LSB of the duration in milli seconds.
/// @param frequenz_MSB LSB of the frequency
/// @param frequenz_LSB MSB of the frequency
void SetBlinking(uint8_t red, uint8_t green, uint8_t blue, uint8_t duration_MSB,uint8_t duration_LSB, uint8_t frequenz_MSB, uint8_t frequenz_LSB){
  
    uint16_t duration = ((duration_MSB<<8) & 0xFF00) | (duration_LSB);
    uint16_t frequenz = ((frequenz_MSB<<8) & 0xFF00) | (frequenz_LSB);
    
    int halfPeriod = 1000/frequenz; //calculate the time to be off and on for the blinking;
    int repetitions = duration * frequenz / 1000; //duration is expected in ms

    for(int i=0;i<repetitions;i++){
        SetRgbValues(red,green,blue);
        delay(halfPeriod);
        CurrentColor = PreviousColor;
        SetRgbValues(0,0,0);
        delay(halfPeriod);
        CurrentColor = PreviousColor;
    }
    SetRgbValues(CurrentColor.R_value ,CurrentColor.G_value,CurrentColor.B_value);
}

/// @brief function that sets a connected RGB strip to a new color, given by the three color channels
/// @param red red channel for the blinking color (0-255)
/// @param green green channel for the blinking color (0-255)
/// @param blue blue channel for the blinking color (0-255)
void SetRgbValues(uint8_t red,uint8_t green,uint8_t blue){
  PreviousColor = CurrentColor;
  CurrentColor.R_value = red;
  CurrentColor.G_value = green;
  CurrentColor.B_value = blue;

  analogWrite(led_red,red);
  analogWrite(led_green,green);
  analogWrite(led_blue,blue);
}