--[[
    
    sensor.lua - LuCI cbi model for the Dragino sensor page

    Copyright (C) 2012 Edwin Chen <edwin@dragino.com>

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


local uci = require "luci.model.uci".cursor()

local dd = uci:get_all("sensor")
local data_stream ={}

m = Map("sensor",translate("d_s_m_settings"), translate("d_s_m_configure"))

s = m:section(NamedSection, "main", "settings", translate("d_s_g_settings"))
s:option(Flag, "enable_local_record", translate("d_s_g_local_enable"))
s:option(DummyValue, "record_file", translate("d_s_g_local_location"))

interval = s:option(Value, "update_interval", translate("d_s_g_interval"))
s.default = 60
function interval.validate(self,value)
	if not tonumber(value) then return nil end
	if tonumber(value) < 60 then return nil end
	return value
end

s = m:section(NamedSection, "pachube", "settings", translate("d_s_p_settiings"))

pachube_enable = s:option(Flag, "enable_update", translate("d_s_p_enable"))
pachube_enable.rmempty = false

pachube_user = s:option(Value, "user", translate("d_s_p_user"))
pachube_user:depends({enable_update=1})

pachube_feed = s:option(Value, "feed", translate("d_s_p_feed"))
pachube_feed:depends({enable_update=1})

api_key = s:option(Value, "apikey", translate("d_s_p_secure"))
api_key:depends({enable_update=1})


--[[
scan = s:option(Button, "_scan", "scan")
scan.inputstyle = "find"

t ={{test="test1",result="yes"},{test="test2",result="no"}}
t = {}
str = "this is a test line"
t2 = m:section(Table, {}, "Status", "Check connection to Pachube")
function scan.write(self, section)
	m.autoapply = false
	t2.render = t2._render
	table.insert (t, {test = str})
	luci.util.update(t2.data, t)
end

t2._render = t2.render
t2.render = function() end


t2:option(DummyValue, "test", "show_test")
--t2:option(DummyValue, "result", "show_result")
--comment = t2:option(DummyValue, "_comment", "show_comment")
--function comment.cfgvalue(self, section)
--	local sc = self.map:get(section, "result")
--	return sc == "yes" and "good" or "bad" 
--end
]]--

s = m:section(TypedSection, "sensorport",translate("d_s_s_configure"))
s:option(Value, "name", translate("d_s_s_ID"))
s:option(Value, "description", translate("d_s_s_description"))

--[[
s = m:section(TypedSection, "cmd","command set to avr")
s:option(Value, "name", "command")
s:option(Value, "description", "Description of this command")]]--

return m
