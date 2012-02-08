//////////////////////////////////////////////////////////////////
//  This program is a demo program to show how to program Dragrove to work with Dragino via
//  SPI and UART interface. 
//  
//  SPI: Dragino works in SPI master mode and Dragrove works in SPI slave mode. Dragino use SPI
//  interface to control Dragrove for different task
//  Dragino sends command to Dragrove and Dragrove will parse the command and implement corresponding 
//  function.  
//
//  UART interface is used to send value of sensor to Dragino
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
//   created Feb.8 2012
//   by Edwin Chen.
//   Shenzhen, China
//
////////////////////////////////////////////////////////////////// 

#include "buffer.h"     // we use buffer to handle the SPI message to make the interupt time as short as
                        // possible
#include "spi.h"
#include "Dragrove_SPI_TEST.h"

//Hardware UART (TXD,RXD) in Dragrove are used for other purpose so we use software UART to conenct
//to Dragino and send data
#include <NewSoftSerial.h>

NewSoftSerial mySerial(6, 7);   //PD6 and PD7 connect to Dragino UART port. 
int value1 = 1;          // Sensor Value 1
int value2 = 2;          // Sensor Value 2 
int time_count = 0;
register uint8_t spi_status asm("r7");

////////////////////////////////////
//plug-in board model defination. Dragino will auto parse these paramters and
//show related info in system part of Dragino web interface. Related part will shown "unknown" if 
// no defination here...parameters(m,a,s,h) and data format should be same as below. 
const char model_no[] = "<m=Dragrove by www.seeedstudio.com>";    // m: Define Shield Model
const char application[]="<a=Demo Sketch to show how to program>";// a: Define Shield Application Info
const char software_ver[] = "<s=0.1>";                            // s: Shield Sketch Version
const char hardware_ver[] = "<h=0.1>";                            // h: Shield Hardware Version
///////////////////////////////////

const char invalid[] = "Invalid Command";         

unsigned int tcnt2;  //TCNT2 initial value for Timer2

// SPI message handler
ISR(SPI_STC_vect)        
{
	unsigned int spi_rx, spi_tx, rx, tx; 

	// the SPI is double-buffered, requiring two NO_OPs when switching from Tx to Rx
	if (spi_status & (SPI_NO_OP_1 | SPI_NO_OP_2)) {
		spi_status--;
		goto finish;
	}

	// are we in Tx mode?
	if (spi_status & SPI_TRANSMIT) {
			if (ctrlGetFromTxBuffer(&tx)) {
				received_from_spi(tx);
				goto finish;
			}
	}

	// we're in Rx mode. if byte we receive from SPI is not a null (0x00) nor END_OF_MESSAGE (.),we
        // will push it to the rx buffer
	switch (spi_rx = received_from_spi(0x00)) {
		case SPI_END_OF_RX:               // case "0x00", end of rx
			spi_status |= SPI_TRANSMIT; 
			break;
		case SPI_END_OF_MESSAGE:            // case ".", end of a message. 
			spi_status |= SPI_NEW_CTRL_MSG;   // a new control message
			break;
		default:
			ctrlAddToRxBuffer(spi_rx);    //store incoming byte to rx buffer. 
			goto finish;
	}

finish:
        ;
}

// get daugther board infomation and put it into tx string to SPI interface. 
void GetBoardInfo(void)     
{
  ctrlAddStringToTxBuffer((char *)model_no);
  ctrlAddStringToTxBuffer((char *)application);
  ctrlAddStringToTxBuffer((char *)software_ver);
  ctrlAddStringToTxBuffer((char *)hardware_ver);
}

// get sensor value and send them to Dragino via UART interface 
void SendDataToUart(void)
{
  mySerial.print("<sensor3>");
  mySerial.print(value1);
  mySerial.print(" <water>");
  mySerial.println(value2);
}

//CTRL Decode, parse the command get from Dragino
void ctrlDecode(void)
{
	unsigned int cmd[2];
	ctrlFlushTxBuffer();   //clear TX buffer
        ctrlAddToTxBuffer(' ');	   // this bit will be ignored when transfer
        if (ctrlGetFromRxBuffer(cmd) && ctrlGetFromRxBuffer(cmd+1)) { // get the CMD from the databuffer      
		switch (cmd[0]) {                      // switch case here to do action according to different command. 
		case 'g':	// get 
			switch (cmd[1]) {
                        case 'b':                  
                                GetBoardInfo();    // gb: get board info and add them to tx buffer.                                 
                                break;
                        case 'd':                  
                                SendDataToUart(); //gd: send sensor data to UART
                                break;
                        default:
                                ctrlAddStringToTxBuffer((char *)invalid);
                        break;
                        }
                        break;
 
	//	case 'x':	            // customermize more command here.  
			//ctrlCmdSet(cmd[1]);
	//		break;
                default:
                        ctrlAddStringToTxBuffer((char *)invalid);
                        break;
		}
	}
        else 
          ctrlAddStringToTxBuffer((char *)invalid);

	ctrlFlushRxBuffer();   // clear RX BUffer
}


//Initial Timer2
void TimerInit()
{
   /* First disable the timer overflow interrupt while we're configuring */  
  TIMSK2 &= ~(1<<TOIE2);   
  /* Configure timer2 in normal mode (pure counting, no PWM etc.) */  
  TCCR2A &= ~((1<<WGM21) | (1<<WGM20));   
  TCCR2B &= ~(1<<WGM22);   
  /* Select clock source: internal I/O clock */  
  ASSR &= ~(1<<AS2);   
 
  /* Disable Compare Match A interrupt enable (only want overflow) */  
  TIMSK2 &= ~(1<<OCIE2A);   
 
  /* Now configure the prescaler to CPU clock divided by 1024 */  
  TCCR2B |= (1<<CS22)  | (1<<CS20 | 1<<CS21); // Set bits     

  /* We need to calculate a proper value to load the timer counter.  
  * The following loads the value 131 into the Timer 2 counter register  
  * The math behind this is:  
  * (CPU frequency) / (prescaler value) = 15625 Hz = 64us.  
  * (desired period/125) / 64us = 125.  to get 8ms interupt
  * MAX(uint8) + 1 - 125 = 131;  
  */  
  /* Save value globally for later reload in ISR */  
  tcnt2 = 131;    

  /* Finally load end enable the timer */  
  TCNT2 = tcnt2;   
  TIMSK2 |= (1<<TOIE2); 
}

// Timer2 Overflow Handler, called every 8ms. 
ISR(TIMER2_OVF_vect) {
  /* Reload the timer */
  TCNT2 = tcnt2;
  time_count++;
  if (time_count == 125) {    // change "sensor" value every 1 second
  value1++;
  if (value1 == 254) value1 = 1;
  value2 = value2+2;
  if (value2 == 254) value2 = 1;
  time_count=0;
  }  
}

void setup()
{
  setup_spi(SPI_MODE_2, SPI_MSB, SPI_INTERRUPT, SPI_SLAVE);       // initial SPI interface. 
  mySerial.begin(9600);
  ctrlInit();          // initial databuffer
  TimerInit();         // initial timer2
}

void loop()
{
  if (spi_status & SPI_NEW_CTRL_MSG) {
                        ctrlDecode();		//function to handle new control message. 
                        spi_status &= ~SPI_NEW_CTRL_MSG;
  }
}


