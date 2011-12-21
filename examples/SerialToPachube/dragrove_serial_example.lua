--[[

    Dragrove_Serial_example.lua - Lua Script to show how to get message from Dragrove 
         via UART port and PUT the data to www.pachube.com

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

local DATASTREAMS_ID	= {'sensor1','sensor2','sensor3'}		-- Valid DATASTREAM_ID,we limit the id here to avoid creating wrong ID in Pachube
local datastreams = {sensor1,sensor2,sensor3}
local FEEDS	= '40xxx' 						-- modify it to use YOUR_FEED. use csv format here.
local API_KEY	= 'NkYHeIFJaC4DPkGDX2OZiW2xxxxxxxxxxxxxxxxdujfg' 	-- put YOUR_API key here. 

local PACHUBE_API	= ' http://api.pachube.com/v2/feeds/'    						 
local MY_FEEDS	= PACHUBE_API .. FEEDS .. '.csv'			-- use csv format by defult.						
local MY_API_KEY	= '\"X-PachubeApiKey: ' .. API_KEY .. '\"'



local MIN_UPDATE_INTERVAL = 60						-- Pachube update interval. unit: Second.

function update_datastreams (raw_string)					-- update datastreams
	for  k,v in pairs(DATASTREAMS_ID) do
		_,_,value = string.find(raw_string,v..',(%d+)')
		if value then
			datastreams[v] = value		
		end
	end
end


serialin=io.open("/dev/ttyS0","r")
local old_time = os.time()
local new_time
while 1 do	
	while line==nil do        -- read data from serial. 
        	serialin:flush()
        	line=serialin:read() 
	end
	update_datastreams(line)
	if datastreams and (os.time()-old_time) >= MIN_UPDATE_INTERVAL then	
		for k,v in pairs(datastreams) do 
			if csv_string == nil then
				csv_string = k .. ',' ..v
			else
				csv_string = csv_string .. '\r' .. k .. ',' ..v
			end
		end
		csv_string = '\"' .. csv_string .. '\"'
		old_time = os.time()
		CMD_UPDATE_FEED_TO_PACHUBE	=  'curl --request PUT --data-binary ' .. csv_string .. ' --header ' ..  MY_API_KEY .. MY_FEEDS
		io.write(os.execute(CMD_UPDATE_FEED_TO_PACHUBE))			--update feeds
		csv_string = nil
	end
	line=nil
end


