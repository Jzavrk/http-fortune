#!/usr/bin/env lua
--[[
A simple HTTP server

Usage: lua server.lua
]]

local http_server = require "http.server"
local http_headers = require "http.headers"
local http_tls = require "http.tls"
local fortune = require "fortune"

local help_msg = [[Fortune Teller

List categories: /categories
Generate by category: /category (lower-case)

example: https://getfortune.click/linux
]]

local function reply(app, stream) -- luacheck: ignore 212
	-- Read in headers
	local req_headers = assert(stream:get_headers())
	local req_method = req_headers:get ":method"
	local req_path = req_headers:get ":path"

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
	local res_body = ""
	res_headers:append(":status", "200")
	res_headers:append("content-type", "text/plain; charset=utf-8")
	if req_method == "GET" then
		if req_path == "/" then
			local fortune_head, fortune_body = fortune.get_random_fortune()
			res_body = string.format("%s\n\n%s", fortune_head:gsub("^%l", string.upper), fortune_body)
		elseif req_path == "/categories" then
			res_body = fortune.printable_list
		elseif req_path == "/help" then
			res_body = help_msg
		else	-- "/*"
			local category = string.sub(req_path, 2)
			if fortune.fortune_list[category] then
				res_body = select(2, fortune.get_fortune(category)) or ""
			else
				res_headers:upsert(":status", "404")
				res_body = "Not found"
			end
		end
		-- Send headers to client; end the stream immediately if this was a HEAD request
		assert(stream:write_headers(res_headers, req_method == "HEAD"))
		assert(stream:write_body_from_string(res_body))
	end
end

fortune.init()
local custom_context = http_tls.new_server_context()
local app = assert(http_server.listen({
	path = "/srv/http/fortune.socket",
	ctx = custom_context,
	unlink = true,
	mode = "0770",
	onstream = reply,
	onerror = function(app, context, op, err, errno) -- luacheck: ignore 212
		local msg = op .. " on " .. tostring(context) .. " failed"
		if err then
			msg = msg .. ": " .. tostring(err)
		end
		assert(io.stderr:write(msg, "\n"))
	end,
}))

-- Manually call :listen() so that we are bound before calling :localname()
assert(app:listen())
do
	local path = select(2, app:localname())
	assert(io.stderr:write(string.format("Listening on socket %s\n", path)))
end
-- Start the main server loop
assert(app:loop())
-- app:close()
