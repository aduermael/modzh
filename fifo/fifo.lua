--- A FIFO list! (first in, first out)
--- Optimized with node recycling and cached list sizes.
---@code
--- fifo = require("github.com/aduermael/modzh/fifo")
--- local list = fifo()
--- list:push(value)
--- local value = list:pop()
--- print(list.first)
--- print(list.last) -- last one that's been pushed
--- print("size:", #list)

local privateFields = setmetatable({}, { __mode = "k" })

local fields
local n
local v

local recycledNodes = {}
local function recycleNode(node)
	node.value = nil
	node.next = nil
	table.insert(recycledNodes, node)
end
local function getOrCreateNode(value)
	n = table.remove(recycledNodes)
	if n == nil then
		n = {
			-- next = nil, -- first -> last
		}
	end
	n.value = value
	return n
end

local fifoMT = {
	__index = {
		push = function(self, value)
			fields = privateFields[self]
			if fields == nil then
				error("fifoList:push(value) should be called with `:`", 2)
			end
			-- note: it's ok to push a nil value
			n = getOrCreateNode(value)
			if fields.last ~= nil then
				fields.last.next = n
				fields.last = n
			else -- list is emtpy
				fields.first = n
				fields.last = n
			end
			fields.size = fields.size + 1
		end,
		pop = function(self)
			fields = privateFields[self]
			if fields == nil then
				error("fifoList:pop(value) should be called with `:`", 2)
			end
			n = fields.first
			if n ~= nil then
				fields.size = fields.size - 1
				fields.first = n.next
				if fields.first == nil then -- list now empty
					fields.last = nil
				end
				v = n.value
				recycleNode(n)
				return v
			end
			return nil
		end,
	},
	__newindex = function()
		error("fifo table is read-only", 2)
	end,
	__len = function(l)
		fields = privateFields[l]
		if fields == nil then
			return
		end
		return fields.size
	end,
}

local mod = setmetatable({}, {
	__newindex = function()
		error("fifo module is read-only", 2)
	end,
	__call = function()
		local l = {}
		privateFields[l] = {
			size = 0,
			first = nil,
			last = nil,
		}
		setmetatable(l, fifoMT)
		return l
	end,
	__metatable = false,
})

return mod