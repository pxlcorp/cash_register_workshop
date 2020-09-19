AddCSLuaFile()

ENT.Type              	= "anim"
ENT.Base              	= "base_gmodentity"
ENT.PrintName         	= "Fixed Scanner"
ENT.Category          	= "PxlCorp"
ENT.Author            	= "PxlCorp"
ENT.Contact           	= "https://scriptfodder.com/users/view/76561198297110372"
ENT.Spawnable         	= true
ENT.PxlDisableRegister	= true

ENT.ScanneRange = 30

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Server")

	self:NetworkVar("Entity", 1, "owning_ent")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/pxl/fix_scanner/scanner_fix_ref.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local phys = self:GetPhysicsObject()
		phys:Wake()

		local scanner = PxlCashRegister.New "Scanner" ("scanner_fixed", self)

		function self:Scanner()
			return scanner
		end
	end
end

function ENT:CashRegister()
	return self:Scanner():CashRegister()
end

function ENT:Think()
	if SERVER then
		if self:CashRegister() then
			local ent = self:Scanner():Trace(self:LocalToWorld(Vector(0,-2,6)), self:GetRight(), self.ScanneRange, self)
			local itm = self:Scanner():GetItem(ent)

			local succ = self:Scanner():CheckEnt(ent)

			if succ then
				self:Scanner():EmitSound()
			end
		end
	end
end

function ENT:OnRemove()
	if SERVER then
		self:Scanner():Remove()
	end
end

function ENT:IsScanned(scanner)
	if scanner:AccessoryType() ~= "scanner_holded" then return end

	if self:CashRegister() then
		return false, "scanner_already_linked"
	else
		local ply = scanner:User()
		local server = scanner:Server()

		if IsValid(ply) and server and (not server:HasPermission(ply, "option") or (server:IsPersistMod() and not server.can_edit_scanner and not PxlCashRegister.Config.IsAdmin(ply))) then
			return false, "not_allowed"
		else
			if scanner:CashRegister() then
				local err = scanner:CashRegister():CheckScanner(self:Scanner())

				if err then
					return false, err
				else
					return true, "scanner_added", {scanner:Server():Name()}
				end
			else
				return
			end
		end
	end
end

function ENT:SendScanneInfo(scanner)
	if not self:CashRegister() and scanner:Server() then
		return "add_scanner_on", scanner:Server():Name()
	end
end
