AddCSLuaFile()

ENT.Type              	= "anim"
ENT.Base              	= "base_gmodentity"
ENT.PrintName         	= "Scanner Holder"
ENT.Category          	= "PxlCorp"
ENT.Author            	= "PxlCorp"
ENT.Contact           	= "https://scriptfodder.com/users/view/76561198297110372"
ENT.Spawnable         	= true
ENT.PxlDisableRegister	= true

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 1, "owning_ent")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/pxl/hand_scanner/pxl_scanner_main_ref.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local phys = self:GetPhysicsObject()
		phys:Wake()

		local scanner = PxlCashRegister.New "Scanner" ("scanner_holded", self)

		self.wep = NULL

		function self:Scanner()
			return scanner
		end
	end
end

function ENT:SetScanner(wep)
	self.wep = wep

	if IsValid(wep) then
		self:SetSkin(1)
	else
		self:SetSkin(0)
	end
end

function ENT:GetScanner()
	return self.wep
end

function ENT:Use(ply)
	if IsValid(self:GetScanner()) then
		if self:GetScanner():GetOwner() == ply then
			self:Drop()
		end
	elseif not IsValid(ply:GetWeapon("pxl_cr_scanner")) then
		self:Take(ply)
	end
end

function ENT:Take(ply)
	local owner = IsValid(self:Getowning_ent()) and self:Getowning_ent() or self:CPPIGetOwner()

	if owner == ply or (self:Scanner():Server() and self:Scanner():Server():IsAllowed(ply)) then
		self.lastactiveweapon = ply:GetActiveWeapon()

		local wep = ply:Give("pxl_cr_scanner")
		ply:SelectWeapon("pxl_cr_scanner")
		wep.scanner = self:Scanner()
		wep:SetHolder(self)
		self:Scanner():SetUser(ply)
		wep:SetScanner(self:Scanner():GetID())

		self:SetScanner(wep)
	end
end

function ENT:Scanne(scanner)
	return "cant_be_scanne"
end


function ENT:Drop()
	if not IsValid(self:GetScanner()) then return end

	local wep = self:GetScanner()
	local ply = wep:GetParent()

	self:GetScanner():Remove()
	self:SetScanner(NULL)

	if IsValid(self.lastactiveweapon) then
		ply:SelectWeapon(self.lastactiveweapon:GetClass())
	else
		ply:SwitchToDefaultWeapon()
	end
end

function ENT:Draw()
	self:DrawModel()
end

function ENT:OnRemove()
	if SERVER then
		if IsValid(self:GetScanner()) then
			self:Drop()
		end

		self:Scanner():Remove()
	end
end

function ENT:CanProperty(ply, property)
	if property == "skin" then
		return false
	end

	return true
end
