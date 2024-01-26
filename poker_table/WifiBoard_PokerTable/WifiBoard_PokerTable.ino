#include <ESP8266WiFi.h>

//The ESP-12 has a blue LED on GPIO2
#define LED 2

// Name and password of the WLAN access point
#define SSID "SSID"
#define PASSWORD "PW"

#define ErrorFlag_Wifi 2

// Set your Static IP address
IPAddress local_IP(192, 168, 178, 91); //IP address of poker table

// Set your Gateway IP address
IPAddress gateway(192, 168, 178, 1);

IPAddress subnet(255, 255, 0, 0);
IPAddress primaryDNS(80, 69, 96, 12);   //optional
IPAddress secondaryDNS(81, 210, 129, 4); //optional


// The server accepts connections on this port
#define PORT 5000
WiFiServer tcpServer(PORT);

// Objects for connections
#define MAX_TCP_CONNECTIONS 5
WiFiClient clients[MAX_TCP_CONNECTIONS];

// Buffer for incoming text
char tcp_buffer[MAX_TCP_CONNECTIONS][30];

void BlinkErrorState(int error){    
    digitalWrite(LED,LOW);
    delay(1000);
    for(int j=0;j<error;j++){
      digitalWrite(LED,HIGH);
      delay(600);
      digitalWrite(LED,LOW);
      delay(600);
    }
    digitalWrite(LED,HIGH);
}


//------------------------------Setup script-----------------------------------
void setup()
{
  // LED off
    pinMode(LED, OUTPUT);
    digitalWrite(LED, HIGH);
        
  if (!WiFi.config(local_IP, gateway, subnet, primaryDNS, secondaryDNS)) {
    BlinkErrorState(ErrorFlag_Wifi);
  }   

    // Initialize the serial port
    Serial.begin(9600);
    delay(500);

    

    // Start the TCP server    
    WiFi.mode(WIFI_STA);
    WiFi.begin(SSID, PASSWORD);
    tcpServer.begin();
}

///@brief
///Collect lines of text.
///Call this function repeatedly until it returns true, which indicates
///that you have now a line of text in the buffer. If the line does not fit
///(buffer to small), it will be truncated.
///
///@param source The source stream.
///@param buffer Target buffer, must contain '\0' initiallly before calling this function.
///@param bufSize Size of the target buffer.
///@param terminator The last character that shall be read, usually '\n'.
///@return True if the terminating character was received.

bool append_until(Stream& source, char* buffer, int bufSize, char terminator)
{
    int data=source.read();
    if (data>=0)
    {
        int len=static_cast<int>(strlen(buffer));
        do
        {
            if (len<bufSize-1)
            {
                buffer[len++]=static_cast<char>(data);
            }
            if (data==terminator)
            {
                buffer[len]='\0';
                return true;
            }
            data=source.read();
        }
        while (data>=0);
        buffer[len]='\0';  
    }
    return false;
}

void check_ap_connection()
{
    static wl_status_t preStatus = WL_DISCONNECTED;
    
    wl_status_t newStatus = WiFi.status();
    if (newStatus != preStatus)
    {
        if (newStatus == WL_CONNECTED)
        {
            digitalWrite(LED, LOW);            
        }
        else
        {
            digitalWrite(LED, HIGH);            
        }
        preStatus = newStatus;
    }
}

void handle_new_connections()
{
    WiFiClient client = tcpServer.available();
    if (client)
    {
        // Find a freee space in the array   
        for (int i = 0; i < MAX_TCP_CONNECTIONS; i++)
        {
            if (!clients[i].connected())
            {
                // Found free space
                clients[i] = client;
                tcp_buffer[i][0]='\0';
                //Serial.print(F("Channel="));
                //Serial.println(i);
                
                // Send a welcome message
                client.println(F("Hello Poker Lover!"));
                return;
            }
        }
        //Serial.println(F("To many connections"));
        client.stop();
    }
}


/// @brief The function interprets the received TCP message which is related to the color setting command.
/// The message string should have the format: "1,255,255,255" where 1 is indentifing the command followed by a comma and then the three RGB values in a range from 0 to 255
/// @param message //containing the TCP message in the format: "1,255,255,255"(commandNumber,red value [0-255],Green value [0-255], blue value[0-255] ) where 255 is in this example a placeholder for a number. 
/// @param r pointer to an uint8_t value which will be overwritten with the red result
/// @param g pointer to an uint8_t value which will be overwritten with the green result
/// @param b pointer to an uint8_t value which will be overwritten with the blue result
bool GetRGBFromTCP(String message, uint8_t * r,uint8_t * g, uint8_t * b){
    if(message.length()<7) //check if the received command has at least the expected amount of character: e.g. 1,255,255,255
    {
        return false;
    }
    clients[0].print(message);
    String remainingMessage = message;
    int startIndex = remainingMessage.indexOf(',');
    int secondComma = remainingMessage.substring(startIndex+1).indexOf(',')+startIndex+1;
    int thirdComma = remainingMessage.substring(secondComma+1).indexOf(',')+secondComma+1;

    String RedString = remainingMessage.substring(startIndex+1,secondComma);
    String GreenString = remainingMessage.substring(secondComma+1,thirdComma);
    String BlueString = remainingMessage.substring(thirdComma+1);
    



    *r = prepareInput(RedString.toInt());
    *g = prepareInput(GreenString.toInt());
    *b = prepareInput(BlueString.toInt());
    return true;
}


/// @brief The function interprets the received TCP message which is related to the blink in color command.
/// @param message Message of the format e.g."2,255,255,255,1000,1" the positioned argumends are: commandId,RedValue,GreenValue,BlueValue,Duration,Frequenz
/// @param r pointer to an integer variable, the function will write the received red value to that variable. (0-255)
/// @param g  pointer to an integer variable, the function will write the received green value to that variable. (0-255)
/// @param b  pointer to an integer variable, the function will write the received blue value to that variable. (0-255)
/// @param durationMS pointer to an integer variable, the function will write the received duration of the blink process to that variable. (0-65535)
/// @param frequenz pointer to an integer variable, the function will write the received frequenz in which the light should blink.(0-65535)
/// @return true, if everything runs as expected, false, when there is an issue detected
bool GetBlinkingFromTCP(String message,uint8_t * r,uint8_t * g, uint8_t * b, int* durationMS, int* frequenz){
    if(!GetRGBFromTCP(message,r,g,b)){
        return false;
    }
    
    int startIndex=0;

    for(int i=0;i<4;i++){ //discard the beginning of the message, which contains the color information, which was already retrieved through the previous function call
        startIndex = message.indexOf(',');
        message = message.substring(startIndex+1);
    }
    int commaPosition = message.indexOf(',');
    String durationString = message.substring(0,commaPosition);
    String frequenzString = message.substring(commaPosition+1);
    clients[0].print("Duration:");
    clients[0].print(durationString);
    clients[0].print(frequenzString);
    *durationMS = durationString.toInt();
    *frequenz = frequenzString.toInt();
    return true;
}

uint8_t getCommandNumber(String message){
    int command = -1;
    int end = message.indexOf(',');
    message = message.substring(0,end);
    command = message.toInt();
    if((command<=0)||(command>255)){
        command = 255;
    }
    return (uint8_t) command;    

}

void Command1_Execution(String Message){
     uint8_t red=0, green=0 ,blue =0;
                GetRGBFromTCP(Message,&red,&green,&blue);
                uint8_t command[7] = { 0x01,0x07,0x01,red,green,blue,0x02};
                Serial.write(command,7);
                //clients[i].println(F("ColorSet")); //optional for debug purpose
                //clients[i].print("R:"+String(red)+"; G:"+String(green)+"; B:"+String(blue));//optional for debug purpose
                clients[0].print("Command 1 Executed");
}

void Command2_Excecution(String Message){
                uint8_t red=0, green=0 ,blue =0;
                int duration =0, frequenz=0;
                GetBlinkingFromTCP(Message,&red,&green,&blue,&duration,&frequenz);
                uint8_t duration_MSB = ((duration >> 8) & 0xFF);
                uint8_t duration_LSB = duration & 0xFF;
                
                uint8_t frequenz_MSB = ((frequenz >> 8) & 0xFF);
                uint8_t frequenz_LSB = frequenz & 0xFF;

                uint8_t command[11] = { 0x01,0x0B,0x02,red,green,blue,duration_MSB,duration_LSB,frequenz_MSB,frequenz_LSB,0x02};
                Serial.write(command,11);
                //clients[i].println(F("Blinking set")); //optional for debug purpose
                clients[0].print("Command 2 Executed");
}


/// @brief Function that implements the functionality of Command 3:
/// The color will be transmitted and will be saved on the EEPROM of the Arduino, o load the same color
/// @param Message 
void Command3_Excecition(String Message){
    uint8_t red=0, green=0 ,blue =0;
    GetRGBFromTCP(Message,&red,&green,&blue);
    uint8_t command[7] = { 0x01,0x07,0x03,red,green,blue,0x02};
    Serial.write(command,7);
    clients[0].print("Command 3 Executed");
}

void process_incoming_tcp()
{   
    static int i=0; //always take the first client.
    
    if (clients[i].available())
    {
        // Collect characters until line break
        if (append_until(clients[i],tcp_buffer[i],sizeof(tcp_buffer[i]),'\n'))
        {   
            clients[i].print("Message Received");
            String Message(tcp_buffer[i]);
        
            uint8_t commandNumber = getCommandNumber(Message);
          
            clients[i].println("Command: "+ String(commandNumber)); //optional for debug purpose          
            switch (commandNumber){
                case 1:
                        Command1_Execution(Message);
                    break;

                case 2:
                        Command2_Excecution(Message);
                    break;
                case 3:
                        Command3_Excecition(Message);
                        break;

                default:
                    break;
          }
          
            tcp_buffer[i][0]='\0';
        }
    }
    
    // Switch to the next connection for the next call
    if (++i >= MAX_TCP_CONNECTIONS)
    {
        i=0;
    }
}

//ensure valid values for color setting
int prepareInput(uint8_t colorValue){
  if(colorValue>255){
    colorValue =255;
  }
  if(colorValue <0){
    colorValue=0;
  }
  return colorValue;
}

/** Main loop, executed repeatedly */
void loop()
{
    handle_new_connections();
    process_incoming_tcp();
    check_ap_connection();
}
