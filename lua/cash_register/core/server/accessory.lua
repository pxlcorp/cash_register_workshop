PxlCashRegister.Accessory = PxlCashRegister.NewClass("Accessory")
local Accessory = PxlCashRegister.Accessory

Accessory.ID_Inc = 0

function Accessory:Construct(tpe, ent)
	Accessory.ID_Inc = Accessory.ID_Inc + 1

	self:SetID(Accessory.ID_Inc)

	self.type = tpe
	self.entity = ent
	self.isLinked = false
	self.options = {}

	function ent.Accessory(ent)
		return self
	end
end

function Accessory:Option(name)
	if self.Options[name] then
		if self.options[name] ~= nil then
			return self.options[name]
		else
			return self.Options[name].Default
		end
	end
end

function Accessory:SetOption(name, value)
	local option = self.Options[name]

	if option then
		if self:Option() ~= value then
			local err = option.OnChange and option.OnChange(self, self:Option(name), value)

			if not err then
				self.options[name] = value
			else
				return err
			end
		end
	end
end

function Accessory:Save()
	local obj = self.entity

	if not IsValid(obj) then return end

	return {
		class		= obj:GetClass(),
		pos			= obj:GetPos(),
		ang			= obj:GetAngles(),
		options		= self.options
	}
end

function Accessory:Load(info)
	local obj = ents.Create(info.class)
	obj:SetPos(info.pos)
	obj:SetAngles(info.ang)
	obj:Spawn()

	local phys = obj:GetPhysicsObject()
	if IsValid(phys) then
		phys:EnableMotion(false)
	end

	for name, value in pairs(info.options or {}) do
		obj:Accessory():SetOption(name, value)
	end

	return obj
end


function Accessory:AccessoryType()
	return self.type
end


function Accessory:SetCashRegister(cash_register)
	if not self.isLinked then
		self.cash_register = cash_register
		self.isLinked = true
	else
		if cash_register == nil and self.cash_register then
			self.cash_register = cash_register
			self.isLinked = false
		else
			return "is_already_linked"
		end
	end
end

function Accessory:CashRegister()
	return self.cash_register
end

function Accessory:SetServer(server)
	if not self.isLinked then
		self.server = server
		self.isLinked = true
	else
		if server == nil and self.server then
			self.server = server
			self.isLinked = false
		else
			return "is_already_linked"
		end
	end
end

function Accessory:Server()
	if self.server then
		return self.server
	elseif self:CashRegister() then
		return self:CashRegister():Server()
	end
end

function Accessory:OnRemove()
	local ent = self.entity
	timer.Simple(0, function()
		if IsValid(ent) then
			ent:Remove()
		end
	end)

	if self:CashRegister() then
		self:CashRegister():RemoveAccessory(self)
	elseif self:Server() then
		self:Server():RemoveAccessory(self)
	end
end

function Accessory:Entity()
	return self.entity
end
