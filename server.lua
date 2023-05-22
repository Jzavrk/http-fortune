#!/usr/bin/env lua
--[[
A simple HTTP server

Usage: lua server.lua
]]

local http_server = require "http.server"
local http_headers = require "http.headers"
local http_tls = require "http.tls"
local fortune = require "fortune"

local function reply(myserver, stream) -- luacheck: ignore 212
	-- Read in headers
	local req_headers = assert(stream:get_headers())
	local req_method = req_headers:get ":method"

	-- Log request to stdout
	assert(io.stdout:write(string.format('[%s] "%s %s HTTP/%g"  "%s" "%s"\n',
		os.date("%d/%b/%Y:%H:%M:%S %z"),
		req_method or "",
		req_headers:get(":path") or "",
		stream.connection.version,
		req_headers:get("referer") or "-",
		req_headers:get("user-agent") or "-"
	)))

	-- Build response headers
	local res_headers = http_headers.new()
	res_headers:append(":status", "200")
	res_headers:append("content-type", "text/plain")
	-- Send headers to client; end the stream immediately if this was a HEAD request
	assert(stream:write_headers(res_headers, req_method == "HEAD"))
	if req_method ~= "HEAD" then
		-- Send body, ending the stream
		local fortune_cookie = select(2, fortune.get_random_fortune())
		assert(stream:write_chunk(fortune_cookie, true))
	end
end

fortune.setup()
local custom_context = http_tls.new_server_context()
local myserver = assert(http_server.listen {
	-- host = "0.0.0.0",
	path = '/srv/http/fortune.socket',
	ctx = custom_context,
	unlink = true,
	mode = "0750",
	-- mask = "0750",
	onstream = reply,
	onerror = function(myserver, context, op, err, errno) -- luacheck: ignore 212
		local msg = op .. " on " .. tostring(context) .. " failed"
		if err then
			msg = msg .. ": " .. tostring(err)
		end
		assert(io.stderr:write(msg, "\n"))
	end,
})

-- Manually call :listen() so that we are bound before calling :localname()
assert(myserver:listen())
do
	local path = select(2, myserver:localname())
	assert(io.stderr:write(string.format("Listening on socket %s\n", path)))
end
-- Start the main server loop
assert(myserver:loop())
-- myserver:close()
