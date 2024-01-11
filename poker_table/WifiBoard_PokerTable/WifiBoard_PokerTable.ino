#include <ESP8266WiFi.h>

//The ESP-12 has a blue LED on GPIO2
#define LED 2

// Name and password of the WLAN access point
#define SSID "Custom_SSID"
#define PASSWORD "Custom_password"

#define ErrorFlag_Wifi 2

// Set your Static IP address
IPAddress local_IP(192, 168, 0, 91); //IP address of poker table

// Set your Gateway IP address
IPAddress gateway(192, 168, 0, 1);

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

/**
 * Collect lines of text.
 * Call this function repeatedly until it returns true, which indicates
 * that you have now a line of text in the buffer. If the line does not fit
 * (buffer to small), it will be truncated.
 *
 * @param source The source stream.
 * @param buffer Target buffer, must contain '\0' initiallly before calling this function.
 * @param bufSize Size of the target buffer.
 * @param terminator The last character that shall be read, usually '\n'.
 * @return True if the terminating character was received.
 */
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


/** 
 * Put new connections into the array and
 * send a welcome message.
 */
void handle_new_connections()
{
    WiFiClient client = tcpServer.available();
    if (client)
    {
        //Serial.print(F("New connection from "));
        //Serial.println(client.remoteIP().toString());
        
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


/** Receive TCP messages and send echo back */
void process_incoming_tcp()
{   
    static int i=0; //always take the first client.
    
    if (clients[i].available())
    {
        // Collect characters until line break
        if (append_until(clients[i],tcp_buffer[i],sizeof(tcp_buffer[i]),'\n'))
        {   
          String Message(tcp_buffer[i]);
          if((strstr(tcp_buffer[i], "R")!=NULL)&&(strstr(tcp_buffer[i], "G")!=NULL)&&(strstr(tcp_buffer[i], "B")!=NULL)){
            String RedString = Message.substring(Message.indexOf('R')+2,Message.indexOf('R')+5);
            String GreenString = Message.substring(Message.indexOf('G')+2,Message.indexOf('G')+5);
            String BlueString = Message.substring(Message.indexOf('B')+2,Message.indexOf('B')+5);

            uint8_t red = prepareInput(RedString.toInt());
            uint8_t green = prepareInput(GreenString.toInt());
            uint8_t blue = prepareInput(BlueString.toInt());
            
            uint8_t command[7] = { 0x01,0x07,0x01,red,green,blue,0x02};
            Serial.write(command,7);
            clients[i].println(F("ColorSet"));
            clients[i].print("R:"+String(red)+"; G:"+String(green)+"; B:"+String(blue));
          }
            
            
            // Send an echo back
            clients[i].print(F("Echo: "));
            clients[i].print(tcp_buffer[i]);


            
            // Execute some test commands
            if (strstr(tcp_buffer[i], "on"))
            {
                uint8_t command[7] = { 0x01,0x07,0x01,0xFF,0xFF,0xFF,0x02};
                Serial.write(command,7);
                clients[i].println(F("LED is on"));                
            }
            else if (strstr(tcp_buffer[i], "off"))
            {
                uint8_t command[7] = { 0x01,0x07,0x01,0x00,0x00,0x00,0x02};
                Serial.write(command,7);
                clients[i].println(F("LED is off"));
            }    
            
            // Clear the buffer to receive the next line
            tcp_buffer[i][0]='\0';
        }
    }
    
    // Switch to the next connection for the next call
    if (++i >= MAX_TCP_CONNECTIONS)
    {
        i=0;
    }
}


/*void ProcessTcpMessage(uint8_t Message[], int MessageLength) {
  int expectedDataBytes = (int) Message[1];
  uint8_t command = Message[2];

  switch (command):
  case 0x01:
      uint8_t command[7] = { 0x01,0x07,0x01,Message[3],Message[4],Message[5],0x02}; //set colour
      Serial.write(command,7);
    break;
  case 0x02:
      uint8_t command[7] = { 0x01,0x04,0x02,0x02 }; //Message 
  default:
  break;
}
*/


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
