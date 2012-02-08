#! /usr/bin/env lua

--[[

    SPI_TEST.lua - Lua Script to test the Dragino SPI interface. Send Message via SPI interface and 
	get feedback from SPI interface.  

    Usage: lua SPI_TEST.lua COMMAND_DEFINE_IN_PLUG_IN_BOARD

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

require("dragino.spid")
msg = arg[1]
result = dragino.spid.CommandToMCU(msg)
print(result)