#! /usr/bin/env lua

--[[

    SPI_ECHO_TEST.lua - Lua Script to test the Dragino SPI interface. Send Message via SPI interface and 
	get feedback from SPI interface.  

    Copyright (C) 2011 edwin chen <edwin@dragino.com>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

]]--


local SPI_MAX_CLK_SPEED_HZ	= 1e6		
local SPI_MIN_BYTE_DELAY_US	= 250
local SPI_TX_RX_DELAY_NS	= 2e7
local SPI_CT_DELAY_NS	= 5e8
local SPI_MAX_READ_BYTES = 1024
local END_OF_MESSAGE = '.'

local nixio = require 'nixio'
local SPI_DEV			= '/dev/spidev0.0'

local O_RDWR_NONBLOCK		= nixio.open_flags('rdwr', 'nonblock')

local msg = arg[1]

local spidev = nixio.open(SPI_DEV, O_RDWR_NONBLOCK)
nixio.spi.setspeed(spidev, SPI_MAX_CLK_SPEED_HZ, SPI_MIN_BYTE_DELAY_US)     --Initial Dragino SPI interface. 
spidev:lock('lock') -- blocks until it can place a write lock on the spidev device

	msg = msg .. END_OF_MESSAGE				-- add end of message
	spidev:write(msg)                          	-- Write Message to the SPI interface	

	incoming_msg = spidev:read(SPI_MAX_READ_BYTES)                          	-- Read Message from SPI interface	
	if incoming_msg == '' then incoming_msg = nil end
	if incoming_msg then
		print(incoming_msg)
	end				-- Print the number of message have been sent, check if Arduino miss some strings. 