--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: ddns.lua 7810 2011-10-28 15:15:27Z jow $
]]--

module("luci.controller.ddns", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/ddns") then
		return
	end
	luci.i18n.loadc("admin-core")
	local i18n = luci.i18n.translate
	
	entry({"ddns"}, cbi("ddns/ddns", {autoapply=true}), i18n("ddns","Dynamic DNS"), 60).i18n="sensor"
end
