--[[

    pachube.lua - Lua Script to get message from UART port 
	and PUT the data to www.pachube.com in a pre-defined time interval
	user can also record data in a local file. 

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

local uci = require 'luci.model.uci'

local sensor = uci.cursor_state():get_all("sensor")

local datastreams = {}

for k, v in pairs(sensor) do
	if v[".type"] == "sensorport" then
		if v.name then
			datastreams[v.name]="null"     --put string "null" to stand for no data
		end
	end 
end

local PACHUBE_ENABLE = sensor.pachube.enable_update
local MIN_UPDATE_INTERVAL = tonumber(sensor.main.update_interval)   -- Pachube update interval. unit: Second.

if PACHUBE_ENABLE == "1" then
	feeds	= sensor.pachube.feed 							-- modify it to use YOUR_FEED. use csv format here.
	api_key	= sensor.pachube.apikey 		-- put YOUR_API key here. 

	pachube_api	= sensor.pachube.api_url    						 
	my_feeds	= pachube_api .. feeds .. '.csv'			-- use csv format by defult.						
	my_api_key	= '\"X-PachubeApiKey: ' .. api_key .. '\" '
end						

local LOCAL_RECORD_ENABLE = sensor.main.enable_local_record						-- enable record to local file , set to nil to disable
local LOCAL_RECORD_FILE = sensor.main.record_file				-- local record file 
local RECORD_FILE_SIZE = tonumber(sensor.main.record_file_size)						-- local record file size is 100k. 


function update_datastreams (raw_string)					-- update datastreams
	local new_data_flag = 0
	for  k,v in pairs(datastreams) do
		_,_,value = string.find(raw_string,'<'..k..'>(%-*%d+%.*%d*)')     -- data format: <datastream_id>value .. .. 
		if value then
			datastreams[k] = value
			new_data_flag = new_data_flag + 1
		end
	end
	return new_data_flag
end

function fsize (file)		     -- function to get file size
	local current = file:seek()     -- get current position
    	local size = file:seek("end")   -- get file size
    	file:seek("set", current)       -- restore position
    	return size
end

serialin=io.open("/dev/ttyS0","r")
local old_time = os.time()
while 1 do	
	while line==nil do        -- read data from serial. 
        	serialin:flush()
        	line=serialin:read() 
	end
	if update_datastreams(line) > 0 and (os.time()-old_time) >= MIN_UPDATE_INTERVAL then	
		local d = os.date("%c")
		for k,v in pairs(datastreams) do 
			if v~="null" then 	
				if csv_string == nil then
					csv_string = k .. ',' ..v
				else
					csv_string = csv_string .. '\r' .. k .. ',' ..v
				end
				if LOCAL_RECORD_ENABLE == "1" then 		-- data to be record to local file
					d = d .." "..k..":"..v
				end
				datastreams[k] = "null"			--clear datastreams buffer
			end
		end
		csv_string = '\"' .. csv_string .. '\"'
		
		if PACHUBE_ENABLE == "1" then					--update pachube feeds
			CMD_UPDATE_FEED_TO_PACHUBE	=  'curl --request PUT --data-binary ' .. csv_string .. ' --header ' ..  my_api_key .. my_feeds
			os.execute(CMD_UPDATE_FEED_TO_PACHUBE)			--update feeds
		end

		if LOCAL_RECORD_ENABLE == "1" then					--record in a local file. 
			f = io.open(LOCAL_RECORD_FILE, "r")
			if f then
				if fsize(f) >= RECORD_FILE_SIZE then	--make sure the file is not too big
					f:close()
					os.execute("mv "..LOCAL_RECORD_FILE.." "..LOCAL_RECORD_FILE..".bak")	
				else
					f:close()
				end
			end
			os.execute("echo "..d .. " >> " .. LOCAL_RECORD_FILE)	
		end
		csv_string = nil
		old_time = os.time()
	end
	line=nil
end


