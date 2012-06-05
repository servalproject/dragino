--[[
LuCI - Lua Configuration Interface

Copyright 2008 Steven Barth <steven@midlink.org>
Copyright 2008 Jo-Philipp Wich <xm@leipzig.freifunk.net>
Copyright 2012 Edwin Chen <edwin@dragino.com>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

	http://www.apache.org/licenses/LICENSE-2.0

$Id: upgrade.lua 3672 2008-10-31 09:35:11Z Cyrus $
]]--

module("luci.controller.mini.upgrade", package.seeall)

function index()
	luci.i18n.loadc("admin-core")
	local i18n = luci.i18n.translate

	entry({"upgrade"}, call("action_upgrade"), i18n("admin_upgrade_system"), 1).i18n="upgrade"
end

function action_upgrade()
	require("luci.model.uci")
	require("luci.fs")

	local tmpfile = "/tmp/firmware.img"
	
	local function image_supported()
		-- XXX: yay...
		return ( 0 == os.execute(
			". /etc/functions.sh; " ..
			"include /lib/upgrade; " ..
			"platform_check_image %q >/dev/null"
				% tmpfile
		) )
	end
	
	local function image_checksum()
		return (luci.sys.exec("md5sum %q" % tmpfile):match("^([^%s]+)"))
	end
	
	local function storage_size()
		local size = 0
		if luci.fs.access("/proc/mtd") then
			for l in io.lines("/proc/mtd") do
				local d, s, e, n = l:match('^([^%s]+)%s+([^%s]+)%s+([^%s]+)%s+"([^%s]+)"')
				if n == "linux" then
					size = tonumber(s, 16)
					break
				end
			end
		elseif luci.fs.access("/proc/partitions") then
			for l in io.lines("/proc/partitions") do
				local x, y, b, n = l:match('^%s*(%d+)%s+(%d+)%s+([^%s]+)%s+([^%s]+)')
				if b and n and not n:match('[0-9]') then
					size = tonumber(b) * 1024
					break
				end
			end
		end
		return size
	end


	-- Install upload handler
	local file
	luci.http.setfilehandler(
		function(meta, chunk, eof)
			if not luci.fs.access(tmpfile) and not file and chunk and #chunk > 0 then
				file = io.open(tmpfile, "w")
			end
			if file and chunk then
				file:write(chunk)
			end
			if file and eof then
				file:close()
			end
		end
	)


	-- Determine state
	local keep_avail   = true
	local step         = tonumber(luci.http.formvalue("step") or 1)
	local has_image    = luci.fs.access(tmpfile)
	local has_support  = image_supported()
	local has_platform = luci.fs.access("/lib/upgrade/platform.sh")
	local has_upload   = luci.http.formvalue("image")
	
	-- This does the actual flashing which is invoked inside an iframe
	-- so don't produce meaningful errors here because the the 
	-- previous pages should arrange the stuff as required.
	if step == 4 then
		if has_platform and has_image and has_support then
			-- Next line is to bypass luci.http layer
			luci.http.context.eoh = true

			-- Now invoke sysupgrade
			local keepcfg = keep_avail and luci.http.formvalue("keepcfg") == "1"
			os.execute("/sbin/luci-flash %s %q" %{
				keepcfg and "-k %q" % _keep_pattern() or "", tmpfile
			})

			-- Make sure the device is rebooted
			luci.sys.reboot()
		end


	--
	-- This is step 1-3, which does the user interaction and
	-- image upload.
	--

	-- Step 1: file upload, error on unsupported image format
	elseif not has_image or not has_support or step == 1 then
		-- If there is an image but user has requested step 1
		-- or type is not supported, then remove it.
		if has_image then
			luci.fs.unlink(tmpfile)
		end
			
		luci.template.render("mini/upgrade", {
			step=1,
			bad_image=(has_image and not has_support or false),
			keepavail=keep_avail,
			supported=has_platform
		} )

	-- Step 2: present uploaded file, show checksum, confirmation
	elseif step == 2 then
		luci.template.render("mini/upgrade", {
			step=2,
			checksum=image_checksum(),
			filesize=luci.fs.stat(tmpfile).size,
			flashsize=storage_size(),
			keepconfig=(keep_avail and luci.http.formvalue("keepcfg") == "1")
		} )
	
	-- Step 3: load iframe which calls the actual flash procedure
	elseif step == 3 then
		luci.template.render("mini/upgrade", {
			step=3,
			keepconfig=(keep_avail and luci.http.formvalue("keepcfg") == "1")
		} )
	end	
end

function _keep_pattern()
	local kpattern = ""
	local files = luci.model.uci.cursor():get_all("luci", "flash_keep")
	if files then
		kpattern = ""
		for k, v in pairs(files) do
			if k:sub(1,1) ~= "." and luci.fs.glob(v) then
				kpattern = kpattern .. " " ..  v
			end
		end
	end
	return kpattern
end
