#include <buffer.h>
#include "spi.h"
#include "Dragrove_SPI_TEST.h"

register uint8_t spi_status asm("r7");
const char model_no[] = "Dragrove by www.seeedstudio.com \r\n";
const char application[]="Software is for testing Dragino SPI \r\n";
const char software_ver[] = "Software Version: 0.1 \r\n"; 
const char hardware_ver[] = "Hardware Version: 0.1 \r\n"; 

ISR(SPI_STC_vect)        // SPI message handler 
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

	// we're in Rx mode
	switch (spi_rx = received_from_spi(0x00)) {
		case SPI_END_OF_RX:               // case "0x00", end of rx from i
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

void GetBoardInfo(void)                    // get daugther board infomation and put it in the tx string to SPI
{
  ctrlAddStringToTxBuffer((char *)model_no);
  ctrlAddStringToTxBuffer((char *)application);
  ctrlAddStringToTxBuffer((char *)software_ver);
  ctrlAddStringToTxBuffer((char *)hardware_ver);
}
//CTRL Decode
void ctrlDecode(void)
{
	unsigned int cmd[2];
	ctrlFlushTxBuffer();   //clear TX buffer
        ctrlAddToTxBuffer('a');	   // this bit will be ignored when transfer
        if (ctrlGetFromRxBuffer(cmd) && ctrlGetFromRxBuffer(cmd+1)) { // get the CMD from the databuffer
		//ctrlAddToTxBuffer(cmd[0]);
		//ctrlAddToTxBuffer(cmd[1]);        
		switch (cmd[0]) {                      // switch case here to do action according to different command. 
		case 'g':	// get 
			switch (cmd[1]) {
                        case 'b':                   //get daugther board version info
                                GetBoardInfo();    // get board info and add the info to tx buffer.                                 
                                break;
                        }
			break;
 
	//	case 'x':	            // customermize more command here.  
			//ctrlCmdSet(cmd[1]);
	//		break;
                default:
                        break;
		}
	}

	ctrlFlushRxBuffer();   // clear RX BUffer
}



void setup()
{
  setup_spi(SPI_MODE_2, SPI_MSB, SPI_INTERRUPT, SPI_SLAVE);       // initial SPI interface. 
  ctrlInit();          // initial databuffer
}

void loop()
{
  if (spi_status & SPI_NEW_CTRL_MSG) {
                        ctrlDecode();		//function to handle new control message. 
                        spi_status &= ~SPI_NEW_CTRL_MSG;
  }
}


