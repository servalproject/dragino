--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: ddns.lua 6588 2010-11-29 15:14:50Z jow $
]]--

local is_mini = (luci.dispatcher.context.path[1] == "mini")


m = Map("ddns", translate("ddns"),
	translate("ddns_desc"))

s = m:section(TypedSection, "service", "")
s.addremove = true
s.anonymous = false

s:option(Flag, "enabled", translate("ddns_enable"))

svc = s:option(ListValue, "service_name", translate("ddns_service_name"))
svc.rmempty = false


local services = { }
local fd = io.open("/usr/lib/ddns/services", "r")
if fd then
	local ln
	repeat
		ln = fd:read("*l")
		local s = ln and ln:match('^%s*"([^"]+)"')
		if s then services[#services+1] = s end
	until not ln
	fd:close()
end

local v
for _, v in luci.util.vspairs(services) do
	svc:value(v)
end

function svc.cfgvalue(...)
	local v = Value.cfgvalue(...)
	if not v or #v == 0 then
		return "-"
	else
		return v
	end
end

function svc.write(self, section, value)
	if value == "-" then
		m.uci:delete("ddns", section, self.option)
	else
		Value.write(self, section, value)
	end
end

svc:value("-", "-- ".."custom".." --")


url = s:option(Value, "update_url", translate("ddns_service_updateurl"))
url:depends("service_name", "-")
url.rmempty = true

s:option(Value, "domain", translate("ddns_service_domain")).rmempty = true
s:option(Value, "username", translate("ddns_service_username")).rmempty = true
pw = s:option(Value, "password", translate("ddns_service_password"))
pw.rmempty = true
pw.password = true


if is_mini then
	s.defaults.ip_source = "network"
	s.defaults.ip_network = "wan"
else
	require("luci.tools.webadmin")

	src = s:option(ListValue, "ip_source",
		translate("ddns_service_ipsource"))
	src:value("network", translate("network"))
	src:value("interface", translate("interface"))
	src:value("web", translate("url"))

	iface = s:option(ListValue, "ip_network", translate("ddns_source_network"))
	iface:depends("ip_source", "network")
	iface.rmempty = true
	luci.tools.webadmin.cbi_add_networks(iface)

	iface = s:option(ListValue, "ip_interface", translate("ddns_source_interface"))
	iface:depends("ip_source", "interface")
	iface.rmempty = true
	for k, v in pairs(luci.sys.net.devices()) do
		iface:value(v)
	end

	web = s:option(Value, "ip_url", translate("ddns_source_url"))
	web:depends("ip_source", "web")
	web.rmempty = true
end


s:option(Value, "check_interval",
	translate("ddns_service_checkinterval")).default = 10
unit = s:option(ListValue, "check_unit", translate("ddns_service_checkunit"))
unit.default = "minutes"
unit:value("minutes", translate("min"))
unit:value("hours", translate("h"))

s:option(Value, "force_interval", translate("ddns_service_forceinterval")).default = 72
unit = s:option(ListValue, "force_unit", translate("ddns_service_forceunit"))
unit.default = "hours"
unit:value("minutes", translate("min"))
unit:value("hours", translate("h"))


return m
