//////////////////////////////////////////////////////////////////
//   This program intend to see how to set the Arduino into slave mode, and get the data from Dragino and display it via serial interface. 
//
//   created 19th Aug 2011
//   by Edwin Chen.
//   Shenzhen, China
//
//  This example code is in the public domain.
//  http://www.dragino.com/downloads/examples/spi_incoming
////////////////////////////////////////////////////////////////// 
 
#include <spi.h>                                  //inlcude the SPI library from Andrew Smallbone. download spi.c and spi.h and put them in arduino\libraries\SPI directory
#define BUFSIZE 200                               // receive buffer. 

volatile char incoming[BUFSIZE];                  //Temporary stored the received bytes. 
volatile short int received=0;                    //Received Bytes counter. 
char rx_string[BUFSIZE];                          //Store the incoming string
boolean End_of_Rx =0;                             //Flag to show end of RX. 
long int receive_count=1;                         //Number of strings received from Dragino

// called by the SPI system when there is data ready.
// Just store the incoming data in a buffer, when we receive the second
// terminating byte (0x00) we copy the incoming buffer to the rx string and set rx end flag to 1. 
ISR(SPI_STC_vect)
{
  incoming[received++] = received_from_spi(0x00);            //read a byte from SPI bufferand store it

  if (received >= BUFSIZE || incoming[received-1] == 0x00) {
    if (incoming[received-2] == 0x00)                        // The string received from MS12 is end with two 0x00. we consider the second 0x00 as end of the receive. 
    {
      End_of_Rx = 1;                                         // Set rx end flag
     for (int i=0; i<= received-3;i++){                      // Copy incoming bytes to rx string, omit the two end byte 0x00
      rx_string[i]=incoming[i];      
     }
     rx_string[received-2]= '\0';                                 // add '\0' as the end of the string.
     received=0;                                             //clear the receive byte counter
    }
  }
}

void setup()
{
  setup_spi(SPI_MODE_2, SPI_MSB, SPI_INTERRUPT, SPI_SLAVE);  //Set up Arduino SPI interface in slave mode. 
  Serial.begin(9600);                                       // Set up Arduino Serial Port baud rate.
}


void loop()
{
  if (End_of_Rx == 1){                                      // Check if end of rx. 
    Serial.print("number of arrive strings:");
    Serial.println(receive_count);                        // Print how many strings we have received. 
    receive_count++;
    Serial.println(rx_string);                            // Print the string content. 
    End_of_Rx = 0;                                         // Clear the rx_end flag
  }
} 

