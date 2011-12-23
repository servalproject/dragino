#define SPI_NO_OP_1		0x01
#define SPI_NO_OP_2		0x02
#define SPI_START_TX		0x04
#define SPI_TRANSMIT		0x08
#define SPI_NEW_CTRL_MSG	0x40

#define SPI_END_OF_RX			0x00
#define SPI_END_OF_MESSAGE		'.'

// defination for the ctrl command part. 
#ifndef CTRL_RX_BUFFER_SIZE                //define SPI rx and tx buffer size, 
#define CTRL_RX_BUFFER_SIZE 32             
#endif
#ifndef CTRL_TX_BUFFER_SIZE
#define CTRL_TX_BUFFER_SIZE 255
#endif

#ifndef WIN32
	// true/false defines
	#define FALSE	0
	#define TRUE	-1
#endif

cBuffer ctrlRxBuffer; // ctrl receive buffer
cBuffer ctrlTxBuffer; // ctrl transmit buffer
static char ctrlRxData[CTRL_RX_BUFFER_SIZE];
static char ctrlTxData[CTRL_TX_BUFFER_SIZE];

void ctrlInit(void)
{
	// initialize the CTRL receive buffer
	bufferInit(&ctrlRxBuffer, (unsigned char*) ctrlRxData, CTRL_RX_BUFFER_SIZE);
	// initialize the CTRL transmit buffer
	bufferInit(&ctrlTxBuffer, (unsigned char*) ctrlTxData, CTRL_TX_BUFFER_SIZE);
}

void ctrlFlushRxBuffer(void)
{
	ctrlRxBuffer.datalength = 0;
}

void ctrlFlushTxBuffer(void)
{
	ctrlTxBuffer.datalength = 0;
}

unsigned int ctrlGetFromTxBuffer(unsigned int* data) {
	// make sure we have data in the Tx buffer
	if(ctrlTxBuffer.datalength) {
		// get byte from beginning of buffer
		*data = bufferGetFromFront(&ctrlTxBuffer);
		return TRUE;
	}
	else {
		// no data
		return FALSE;
	}
}

unsigned int ctrlGetFromRxBuffer(unsigned int* pdata)
{
	// make sure we have data in the Rx buffer
	if(ctrlRxBuffer.datalength) {
		// get byte from beginning of buffer
		*pdata = bufferGetFromFront(&ctrlRxBuffer);  
		return TRUE;
	}
	else {
		// no data
		return FALSE;
	}
}

unsigned int ctrlAddToRxBuffer(unsigned int data)
{
	return bufferAddToEnd(&ctrlRxBuffer, data);
}

unsigned int ctrlAddToTxBuffer(unsigned int data)
{
	return bufferAddToEnd(&ctrlTxBuffer, data);
}

void ctrlAddStringToTxBuffer(char *str)
{      
    for (int i=0;str[i] != '\0';i++){
          ctrlAddToTxBuffer(str[i]);
        }
}
