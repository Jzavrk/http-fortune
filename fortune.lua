---@module fortune
---@author Jzavrk

local M = {
	fortune_list = {},
	printable_list = "",
}

--- List possible categories
function M.init()
	local categories = assert(io.popen("fortune -f 2>&1 1> /dev/null"), "fortune is missing")
	-- Discard first line (path to fortune_list)
	local _ = categories:read("l")
	for it in categories:lines("l") do
		local category = string.match(it, "[-_%a]+")
		table.insert(M.fortune_list, category)
		M.fortune_list[category] = true
		M.printable_list = M.printable_list .. category .. "\n"
	end
	io.close(categories)
end

--- Get fortune by category
---@param category string
---@return string|nil,string|nil category name and fortune body
function M.get_fortune(category)
	local handler = assert(io.popen("fortune -a " .. category), "fortune is missing")
	local fortune = handler:read("a")
	io.close(handler)

	return category, fortune
end

--- Get random fortune
---@return string,string category and fortune body
function M.get_random_fortune()
	local handler = assert(io.popen("fortune -ac"), "fortune is missing")
	local category = handler:read("l"):match("[-_%a]+")
	local _ = handler:read("l")
	local fortune = handler:read("a")
	io.close(handler)

	return category, fortune
end

return M
