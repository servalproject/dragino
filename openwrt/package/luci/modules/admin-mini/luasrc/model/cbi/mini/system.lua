--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: system.lua 5314 2009-08-27 17:54:51Z jow $
]]--

require("luci.sys")
require("luci.sys.zoneinfo")
require("luci.tools.webadmin")
require("luci.fs")
require("dragino.spid")

local uci = require "luci.model.uci".cursor()

m = Map("system", translate("system"), "")
--m.pageaction = false

s = m:section(TypedSection, "system", translate("general"))
s.anonymous = true
s.addremove = false


local system,model, memtotal, memcached, membuffers, memfree = luci.sys.sysinfo()
local uptime = luci.sys.uptime()
local FirmwareVersion = luci.sys.exec("cat /etc/banner | grep 'Dragino'")
s:option(DummyValue, "_firmwareinfo", translate("m_i_firmwareversion")).value = FirmwareVersion

dd=uci:get("luci","main","showsensorboard")
if dd then 
local bi = dragino.spid.CommandToMCU("gb")
local BoardInfo = {}
for k, v in string.gmatch(bi, "<(.-)=(.-)>") do
       BoardInfo[k] = v
end
s:option(DummyValue, "_shieldmodel", translate("m_i_shieldmodel")).value = BoardInfo["m"] or "unknown"
s:option(DummyValue, "_shieldapp", translate("m_i_shieldapp")).value = BoardInfo["a"] or "unknown"
s:option(DummyValue, "_shieldsketch", translate("m_i_shieldsketch")).value = BoardInfo["s"] or "unknown"
s:option(DummyValue, "_shieldhardware", translate("m_i_shieldhardware")).value = BoardInfo["h"] or "unknown"
end

local load1, load5, load15 = luci.sys.loadavg()
s:option(DummyValue, "_la", translate("load")).value = 
 string.format("%.2f, %.2f, %.2f", load1, load5, load15)

s:option(DummyValue, "_memtotal", translate("m_i_memory")).value =
 string.format("%.2f MB (%.0f%% %s, %.0f%% %s, %.0f%% %s)",
  tonumber(memtotal) / 1024,
  100 * memcached / memtotal,
  tostring(translate("mem_cached", "")),
  100 * membuffers / memtotal,
  tostring(translate("mem_buffered", "")),
  100 * memfree / memtotal,
  tostring(translate("mem_free", ""))
)

tz = s:option(ListValue, "zonename", translate("timezone"))
tz:value("UTC")

for i, zone in ipairs(luci.sys.zoneinfo.TZ) do
	tz:value(zone[1])
end

function tz.write(self, section, value)
	local function lookup_zone(title)
		for _, zone in ipairs(luci.sys.zoneinfo.TZ) do
			if zone[1] == title then return zone[2] end
		end
	end

	AbstractValue.write(self, section, value)
	self.map.uci:set("system", section, "timezone", lookup_zone(value) or "GMT0")
end
 
s:option(DummyValue, "_systime", translate("m_i_systemtime")).value =
 os.date("%c")
 
s:option(DummyValue, "_uptime", translate("m_i_uptime")).value = 
 luci.tools.webadmin.date_format(tonumber(uptime))

s:option(DummyValue, "_hostname", translate("hostname")).value =                   
 luci.sys.hostname(value)                                                          


-- Wifi Data init -- 
local uci = luci.model.uci.cursor()
if not uci:get("network", "wan") then
	uci:section("network", "interface", "wan", {proto="none", ifname=" "})
	uci:save("network")
	uci:commit("network")
end

local wlcursor = luci.model.uci.cursor_state()
local wireless = wlcursor:get_all("wireless")
local wifidata = luci.sys.wifi.getiwconfig()
local wifidevs = {}
local ifaces = {}

for k, v in pairs(wireless) do
	if v[".type"] == "wifi-iface" then
		table.insert(ifaces, v)
	end
end

wlcursor:foreach("wireless", "wifi-device",
	function(section)
		table.insert(wifidevs, section[".name"])
	end)


-- Wifi Status Table --
s = m:section(Table, ifaces, translate("wifi"))

link = s:option(DummyValue, "_link", translate("link"))
function link.cfgvalue(self, section)
	local ifname = self.map:get(section, "ifname")
	return wifidata[ifname] and wifidata[ifname]["Link Quality"] or "-"
end

essid = s:option(DummyValue, "ssid", "ESSID")

bssid = s:option(DummyValue, "_bsiid", "BSSID")
function bssid.cfgvalue(self, section)
	local ifname = self.map:get(section, "ifname")
	return (wifidata[ifname] and (wifidata[ifname].Cell 
	 or wifidata[ifname]["Access Point"])) or "-"
end

protocol = s:option(DummyValue, "_mode", translate("protocol"))
function protocol.cfgvalue(self, section)
	local mode = wireless[self.map:get(section, "device")].mode
	return mode and "802." .. mode
end

mode = s:option(DummyValue, "mode", translate("mode"))
encryption = s:option(DummyValue, "encryption", translate("iwscan_encr"))

power = s:option(DummyValue, "_power", translate("power"))
function power.cfgvalue(self, section)
	local ifname = self.map:get(section, "ifname")
	return wifidata[ifname] and wifidata[ifname]["Tx-Power"] or "-"
end

scan = s:option(Button, "_scan", translate("scan"))
scan.inputstyle = "find"

function scan.cfgvalue(self, section)
	return self.map:get(section, "ifname") or false
end

-- Wifi-Scan-Table --
t2 = m:section(Table, {}, translate("iwscan"), translate("iwscan1"))

function scan.write(self, section)
	m.autoapply = false
	t2.render = t2._render
	local ifname = self.map:get(section, "ifname")
	luci.util.update(t2.data, luci.sys.wifi.iwscan(ifname))
end

t2._render = t2.render
t2.render = function() end

t2:option(DummyValue, "Quality", translate("iwscan_link"))
essid = t2:option(DummyValue, "ESSID", "ESSID")
function essid.cfgvalue(self, section)
	return self.map:get(section, "ESSID")
end

t2:option(DummyValue, "Address", "BSSID")
t2:option(DummyValue, "Mode", translate("mode"))
chan = t2:option(DummyValue, "channel", translate("channel"))
function chan.cfgvalue(self, section)
	return self.map:get(section, "Channel")
	    or self.map:get(section, "Frequency")
	    or "-"
end 

t2:option(DummyValue, "Encryption key", translate("iwscan_encr"))

t2:option(DummyValue, "Signal level", translate("iwscan_signal"))

t2:option(DummyValue, "Noise level", translate("iwscan_noise"))

-- Interface Data Init--
local network = luci.model.uci.cursor_state():get_all("network")

local netstat = luci.sys.net.deviceinfo()
local ifaces = {}

for k, v in pairs(network) do
	if v[".type"] == "interface" and k ~= "loopback" then
		table.insert(ifaces, v)
	end
end

-- Interfaces Status Table--
s = m:section(Table, ifaces, translate("interfaces"))
s.parse = function() end

s:option(DummyValue, ".name", translate("interface"))

hwaddr = s:option(DummyValue, "_hwaddr",
 translate("network_interface_hwaddr"), translate("network_interface_hwaddr_desc"))
function hwaddr.cfgvalue(self, section)
	local ix = self.map:get(section, "ifname") or ""
	return luci.fs.readfile("/sys/class/net/" .. ix .. "/address")
		or luci.util.exec("ifconfig " .. ix):match(" ([A-F0-9:]+)%s*\n")
		or "n/a"
end


s:option(DummyValue, "ipaddr", translate("ipaddress"))

s:option(DummyValue, "netmask", translate("netmask"))


txrx = s:option(DummyValue, "_txrx",
 translate("network_interface_txrx"), translate("network_interface_txrx_desc"))

function txrx.cfgvalue(self, section)
	local ix = self.map:get(section, "ifname")

	local rx = netstat and netstat[ix] and netstat[ix][1]
	rx = rx and luci.tools.webadmin.byte_format(tonumber(rx)) or "-"

	local tx = netstat and netstat[ix] and netstat[ix][9]
	tx = tx and luci.tools.webadmin.byte_format(tonumber(tx)) or "-"

	return string.format("%s / %s", tx, rx)
end

errors = s:option(DummyValue, "_err",
 translate("network_interface_err"), translate("network_interface_err_desc"))

function errors.cfgvalue(self, section)
	local ix = self.map:get(section, "ifname")

	local rx = netstat and netstat[ix] and netstat[ix][3]
	local tx = netstat and netstat[ix] and netstat[ix][11]

	rx = rx and tostring(rx) or "-"
	tx = tx and tostring(tx) or "-"

	return string.format("%s / %s", tx, rx)
end


return m
