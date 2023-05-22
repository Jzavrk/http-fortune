---@module fortune
---@author Jzavrk

local M = {
	fortunes = {},
	printable_list = "",
}

--- List possible categories
function M.setup()
	local fortunes = assert(io.popen("fortune -f 2>&1 1> /dev/null"), "fortune is missing")
	-- Discard first line (path to fortunes)
	local _ = fortunes:read("l")
	for it in fortunes:lines("l") do
		local categorie = string.match(it, "[-_%a]+")
		M.fortunes[categorie] = true
		M.printable_list = M.printable_list .. categorie .. "\n"
	end
	io.close(fortunes)
end

--- Get fortune by categorie
---@param categorie string
---@return string|nil,string|nil categorie name and fortune body
function M.get_fortune(categorie)
	if not M.fortunes[categorie] then
		return nil, nil
	end
	local handler = assert(io.popen("fortune -a " .. categorie), "fortune is missing")
	local fortune = handler:read("a")
	io.close(handler)

	return categorie, fortune
end

--- Get random fortune
---@return string,string Categorie and fortune body
function M.get_random_fortune()
	local handler = assert(io.popen("fortune -ac"), "fortune is missing")
	local categorie = handler:read("l"):match("[-_%a]+")
	local _ = handler:read("l")
	local fortune = handler:read("a")
	io.close(handler)

	return categorie, fortune
end

return M
