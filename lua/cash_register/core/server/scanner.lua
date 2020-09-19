PxlCashRegister.Scanner = PxlCashRegister.NewClass("Scanner", "Accessory")
local Scanner = PxlCashRegister.Scanner
Scanner:InitNet("CashRegister_Scanner")

--[[---------------------------------------------------------
	Scanne MetaTable
-----------------------------------------------------------]]

function Scanner:Construct(tpe, ent)
	self.__parent.Construct(self, tpe, ent)

	self.lasterror = {"", ""}
	self.parent = ent
	self.title = {}
	self.user = NULL
end


function Scanner:Trace(pos, dir, range, ignoredents)
	dir = isangle(dir) and dir:Forward() or dir
	range = range or 100000
	ignoredents = ignoredents or {}

	local tr = util.TraceLine{
		start = pos,
		endpos = pos + dir * range,
		filter = ignoredents
	}

	return tr.Entity, tr
end

function Scanner:RegisterEnt(ent)
	if not self:CashRegister() then return nil, "not_linked" end
	if not self:Server():HasPermission(self:User(), "items") then return false, "not_allowed" end

	local item, err = self:Server():AddItem(ent)

	if item then
		if err then
			return nil, err
		else
			return true, "item_registered", {item:Name()}
		end
	else
		return false, err
	end
end

function Scanner:CheckEnt(ent)
	if ent.IsScanned then
		local succ, msg, args = ent:IsScanned(self)

		if succ ~= nil then
			return succ, msg, args
		end
	end

	if self:CashRegister() then
		local item = self:GetItem(ent)

		if not item or not self:Server():GetItem(item:GetID()) then
			return false, "invalid_item"
		end

		if IsValid(self:User()) and not self:Server():IsAllowed(self:User()) then
			return false, "not_allowed"
		end

		local err = self:CashRegister():AddItem(item)

		if not err then
			return true, "item_added", {item:Name()}
		else
			return false, err
		end
	end
end

function Scanner:GetInfo(ent)
	if not ent then return "no_fucking_item" end

	if ent.SendScanneInfo then
		local args = {ent:SendScanneInfo(self)}

		if #args > 0 then
			return unpack(args)
		end
	end

	local item = self:GetItem(ent)

	if self:CashRegister() then
		if item then
			return "item_display", item:Name(), item:Cost(), self:Server():Name()
		else
			return "no_item"
		end
	else
		return "not_linked"
	end
end

function Scanner:GetItem(ent)
	return ent.CRSItem
end

function Scanner:SetUser(ply)
	self.user = ply
end

function Scanner:User()
	return self.user
end

function Scanner:SetParent(ent)
	self.parent = ent
end

function Scanner:EmitSound(ent)
	local ent = ent or self.parent

	if ent then
		sound.Play("PxlCashRegister.Scan", ent:GetPos())
	end
end

function Scanner:SetTitle(...)
	if util.TableToJSON({...}) ~= util.TableToJSON(self.title) then
		self.title = {...}

		if IsValid(self:User()) then
			self:Send(self:User()).SetTitle(...)
		end
	end
end

function Scanner:Message(...)
	if IsValid(self:User()) then
		self:Send(self:User()).Message(...)
	end
end

function Scanner.Receive:GetTitle(ply)
	if ply ~= self:User() then return end

	self:Send(self:User()).SetTitle(unpack(self.title))
end
