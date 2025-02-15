local astal = require("astal")
local Variable = require("astal").Variable
local GLib = astal.require("GLib")

local M = {}

function M.src(path)
	local str = debug.getinfo(2, "S").source:sub(2)
	local src = str:match("(.*/)") or str:match("(.*\\)") or "./"
	return src .. path
end

---@generic T, R
---@param array T[]
---@param func fun(T, i: integer): R
---@return R[]
function M.map(array, func)
	local new_arr = {}
	for i, v in ipairs(array) do
		new_arr[i] = func(v, i)
	end
	return new_arr
end

---@param path string
---@return boolean
function M.file_exists(path) return GLib.file_test(path, "EXISTS") end

M.date = Variable(""):poll(1000, "date")

return M
