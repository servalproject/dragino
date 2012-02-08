//////////////////////////////////////////////////////////////////
//  This program will send data to Dragino via  Dragrove's soft serial port (PD6, PD7)
//   
//  Dragino runs a daemon which will check all data get from its UART interface and check 
//  if it match this format: <Sensor ID>VALUE [… … … …]. If it match, then Dragino will 
//  store this value as the latest value of this sensor ID. It will store the data on local 
//  location or upload to Pachube in periodically and then clear the data buffer. 
//
//  Examples of data format:  
//  1)	<sensor1>89 <sensor2>133 <sensor3>67 
//  2)	<sensor1>100 <sensor3>43 <gas>78
//  In 1), Dragino will store: sensor1=89, sensor2=133 and sensor3=67
//  2), Dragino will store sensor1=100, sensor3=43, but no gas since gas is not a valid sensor ID.
//
//   created 21st Dec 2011
//   by Edwin Chen.
//   Shenzhen, China
//
////////////////////////////////////////////////////////////////// 

//Hardware UART (TXD,RXD) in Dragrove are used for other purpose so we use software UART to conenct
//to Dragino and send data
#include <NewSoftSerial.h>

//
NewSoftSerial mySerial(6, 7);   //PD6 and PD7 are connected to Dragino UART port. 


int value1 = 1;
int value2 = 2;

void setup()  
{
  // set the data rate for the NewSoftSerial port
  mySerial.begin(9600);

}

void loop()                     // run over and over again
{
    mySerial.print("<sensor3>");
    mySerial.print(value1);
    mySerial.print(" <water>");  // an extra space between different value pair. 
    mySerial.println(value2);
    value1++;
    if (value1 == 254) value1 = 1; 
    value2 = value2+2;
    delay(1000);
}
