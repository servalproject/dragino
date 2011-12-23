//////////////////////////////////////////////////////////////////
//  This program will send data to Dragino via  Dragrove's soft serial port (PD6, PD7)
//   
//  Dragino runs a lua script: dragrove_serial_example.lua. this script will parse the string
//  from Dragrove and send it to Pachube server and plot. 
//
//   created 21st Dec 2011
//   by Edwin Chen.
//   Shenzhen, China
//
////////////////////////////////////////////////////////////////// 

#include <NewSoftSerial.h>

NewSoftSerial mySerial(6, 7);   //PD6 and PD7 connect to Dragino UART port. 
int value1 = 1;
int value2 = 2;

void setup()  
{
  // set the data rate for the NewSoftSerial port
  mySerial.begin(9600);

}

void loop()                     // run over and over again
{
    mySerial.print("sensor1,");
    mySerial.print(value1);
    mySerial.print(" sensor2,");
    mySerial.println(value2);
    value1++;
    if (value1 == 254) value1 = 1;
    value2 = value2+2;
    if (value2 == 254) value2 = 1;
    delay(1000);
}
