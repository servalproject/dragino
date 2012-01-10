#!/bin/sh
#script to download avr hex file from tftp server and 
#upload it to avr chip.  by Edwin Chen<edwin@dragino.com>


AVR_PART=atmega168		 # AVR part 
EFUSE=0x01			
HFUSE=0xdd			
LFUSE=0xff

if [ -z $1 ] || [ -z $2 ] 
then
	echo "Missing parameters."
	echo "Do you input the hex file and tftp server address?"
	echo "Usage: upgrade_avr.sh AVR_HEX_FILE TFTP_SERVER_ADDRESS"
	echo "example: upgrade_avr.sh hello.hex 192.168.1.5"
	exit 0
fi

atftp -g -r $1 $2

if [ ! -s $1 ] 
then 
	echo "Hex file $1 is a null file. Please check:"
	echo "1/ you have network connection to the TFTP server."
	echo "2/ the hex file is in the TFTP server root."  
	exit 0
fi

fdude -p $AVR_PART -c gpio -U flash:w:$1 -U efuse:w:$EFUSE:m \
	-U hfuse:w:$HFUSE:m -U lfuse:w:$LFUSE:m
