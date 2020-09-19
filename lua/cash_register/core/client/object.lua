local MetaTable = PxlCashRegister.MetaTable

MetaTable.Main = {}
local main_mt = MetaTable.Main

main_mt.__index = function(cls, key)
	return cls.__parent[key] or main_mt[key]
end

function main_mt:__tostring()
	if istable(self.__class) then
		return "Object " .. (self:GetID() and ("[" .. self:GetID() .. "]")) .. "[" .. self.__type .. "]"
	else
		return "Class [" .. self.__type .. "]"
	end
end

function main_mt:AddCallback(event, callback)
	table.insert(self.__callbacks[event], callback)
end

function main_mt:Call(event, ...)
	if self.__callbacks[event] then
		local result = {};

		for _, callback in pairs(self.__callbacks[event]) do
			result = {callback(self, ...)}

			if result[1] ~= nil then
				return unpack(result)
			end
		end
	end
end

function main_mt:Type()
	return self.__type
end

function main_mt:Class()
	assert(istable(self.__class))
	return self.__class
end

function main_mt:Push()
	assert(istable(self.__class))
	local class = self.__class

	local id = table.insert(class.__objects, self)
	self.__id = id
end

function main_mt:SetID(id)
	assert(istable(self.__class))
	local class = self.__class

	self.__id = id
	class.__objects[id] = self
end

function main_mt:GetID()
	assert(istable(self.__class))

	return self.__id or self.id or 0
end

function main_mt:Get(id)
	assert(istable(self.__objects))
	return self.__objects[id]
end

function main_mt:GetAll()
	assert(istable(self.__objects))
	return self.__objects
end

function main_mt:Remove()
	assert(istable(self.__class))
	local class = self.__class

	if self.OnRemove then
		self:OnRemove()
	end

	if class.__objects[self.__id] then
		class.__objects[self.__id] = nil
	end

	for k, v in pairs(self) do
		self[k] = nil
	end

	self.isRemoved = true
end

function main_mt:IsValid()
	return not self.isRemoved
end

function main_mt:IsClass()
	return not istable(self.__class)
end

function main_mt:IsObject()
	return istable(self.__class)
end

function main_mt:OnMissingIndex(key)
end

function main_mt:__run_callback(id, ...)
	local domt = self.__sendmt

	local callback = domt.callback[id]
	if callback then
		callback(...)
		domt.callback[id] = nil
	end
end

function main_mt:OnConstruct(mod_name, callback)
	self.__onconstruct[mod_name] = callback
end

function main_mt:InitNet(name)
	local domt = setmetatable({nets = {default = name}, obj = self, callback = {}}, {__index = function(self, key)
		return function(...)
			local args = {...}

			local callback_id = 0
			if isfunction(args[#args]) then
				callback_id = table.insert(self.callback, table.remove(args, #args))
			end

			net.Start(self.net)
				net.WriteInt(self.obj:GetID(), 8)
				net.WriteInt(callback_id, 32)
				net.WriteString(key)
				net.WriteInt(#args, 8)

				for _, value in pairs(args) do
					net.WriteType(value)
				end
			net.SendToServer()
		end
	end})
	self.__sendmt = domt

	function self:Send(player, net)
		self.__sendmt.obj = self
		self.__sendmt.net = self.__sendmt.nets[net] or self.__sendmt.nets.default

		return self.__sendmt
	end

	net.Receive(name, function()
		local id = net.ReadInt(8)
		local callback_id = net.ReadInt(32)
		local action = net.ReadString()
		local count = net.ReadInt(8)
		local args = {}

		local obj = self:Get(id)
		if not obj then return end
		assert(obj, "Try to call " .. action .. " on a nil object " .. self.__type .. ":" .. id)

		for i = 1, count do
			table.insert(args, net.ReadType())
		end

		local override
		if obj.ReceiveCallback then
			override = obj:ReceiveCallback(action, unpack(args))
		end

		if override ~= false then
			assert(isfunction(obj[action]), "No function " .. self.__type .. ":" .. action)
			local result = {obj[action](obj, unpack(args))}

			if #result > 0 and callback_id > 0 then
				obj:Send().__run_callback(callback_id, unpack(result))
			end
		end
	end)
end

function main_mt:AddNet(index, name)
	if not self.__sendmt then return end

	self.__sendmt.nets[index] = name

	assert(not self[index])
	self[index] = {}

	net.Receive(name, function()
		local id = net.ReadInt(8)
		local callback_id = net.ReadInt(32)
		local action = net.ReadString()
		local count = net.ReadInt(8)
		local args = {}

		local obj = self:Get(id)
		if not obj then return end
		assert(obj, "Try to call " .. action .. " on a nil object " .. self.__type .. ":" .. id)

		for i = 1, count do
			table.insert(args, net.ReadType())
		end

		assert(isfunction(obj[index][action]), "No function " .. self.__type .. ":" .. action)

		local override
		if obj.ReceiveCallback then
			override = obj:ReceiveCallback(action, unpack(args))
		end

		if override ~= false then
			local result = {obj[index][action](obj, unpack(args))}

			if #result > 0 and callback_id > 0 then
				obj:Send(index).__run_callback(callback_id, unpack(result))
			end
		end
	end)
end

function main_mt:New(...)
	return PxlCashRegister.New(self:Type())(...)
end

function PxlCashRegister.NewClass(name, inherit, bass_cls)
	local bass_cls = bass_cls or {}
	local inherit = isstring(inherit) and MetaTable[inherit] or istable(inherit) and inherit or {}

	if MetaTable[name] then
		return setmetatable(MetaTable[name], main_mt)
	else
		local cls = setmetatable(bass_cls, main_mt)
		cls.__index = function(self, key) return cls[key] or inherit[key] or cls.OnMissingIndex(key) end
		cls.__parent = inherit
		cls.__type = name
		cls.__objects = {}
		cls.__onconstruct = {}

		MetaTable[name] = cls

		return cls
	end
end

function PxlCashRegister.New(name, bass_obj)
	local class = MetaTable[name]
	if not class then return end

	local bass_obj = bass_obj or {}

	return function(...)
		local obj = setmetatable(bass_obj, class)
		obj.__class = class
		obj.__type = class.__type
		obj.__callbacks = {}

		if class.Construct then
			obj:Construct(...)
		end

		for _, callback in pairs(obj.__onconstruct) do
			callback(obj, ...)
		end

		return obj
	end
end

function PxlCashRegister.Get(class, id)
	if not MetaTable[class] then return end

	if id then
		return MetaTable[class]:Get(id)
	else
		return MetaTable[class]
	end
end
