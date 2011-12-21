#!/bin/bash
#script to download avr hex file from tftp server and upload it to avr chip.  by edwin@dragino.com

SERVER_IP=192.168.1.190        #input your TFTP server address here. 
AVR_PART=atmega168		 # AVR part 
EFUSE=0x01			
HFUSE=0xdd			
lFUSE=0xff

if [ -z $1 ] 
then
	echo "Please input the hex file name"
	echo "usage: sh upgrade_avr.sh AVR_HEX_FILE"
	exit 0
fi
atftp -g -r $1 $SERVER_IP
fdude -p $AVR_PART -c gpio -U flash:w:$1 -U efuse:w:$EFUSE:m -U hfuse:w:$HFUSE:m -U lfuse:w:$LFUSE:m
