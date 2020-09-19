AddCSLuaFile()

ENT.Type              	= "anim"
ENT.Base              	= "base_gmodentity"
ENT.PrintName         	= "Cash Register"
ENT.Category          	= "PxlCorp"
ENT.Author            	= "PxlCorp"
ENT.Contact           	= "https://scriptfodder.com/users/view/76561198297110372"
ENT.Spawnable         	= true
ENT.IsCashRegister    	= true
ENT.PxlDisableRegister	= true


if SERVER then
	util.AddNetworkString("CashRegister_Init")
end

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 1, "owning_ent")
	self:NetworkVar("Bool", 0, "IsOpen")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/pxl/cash_register_pxl/cash_register_pxl.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:ManipulateBoneAngles(1, Angle(0,0,0))
		self:SetSkin(1)

		local phys = self:GetPhysicsObject()
		phys:Wake()
		phys:SetMass(50)
		local cash_register = PxlCashRegister.New "CashRegister" (self)

		function self:CashRegister()
			return cash_register
		end

		self:SetIsOpen(false)

		local ply = self:CPPIGetOwner()

		if not IsValid(ply) then
			ply = self:Getowning_ent()
		end

		if IsValid(ply) then
			self:CashRegister():Server():SetOwner(ply)
		end
	else
		self.isopen = false

		self.anim_time	= 0.6
		self.anim_max 	= 8
		self.anim_wait	= 1

		self.screen_request = 0
		self.last_draw = CurTime()
	end
end

net.Receive("CashRegister_Init", function(_, ply)
	local ent = net.ReadEntity()

	if SERVER then -- If it received by the server, it will send the CashRegister ID to the client
		local function initclient()
			if not IsValid(ent) then return end

			net.Start("CashRegister_Init")
				net.WriteEntity(ent)
				net.WriteInt(ent:CashRegister():GetID(), 16)
			net.Send(ply)
		end
		initclient()
	else -- Initialize screens with the ID of the CashRegister
		local id = net.ReadInt(16)

		-- Remove old screens if they are still valid
		if IsValid(ent.uscreen) then ent.uscreen:Remove() end
		if IsValid(ent.cscreen) then ent.cscreen:Remove() end

		-- -3.294717 5.385781 16.629593
		-- -3.305739 -5.337150 16.598869
		-- -5.926492 5.379009 9.297883
		-- -5.928627 -5.351084 9.291918


		ent.uscreen = PxlCashRegister.New "UScreen" (ent, id, Vector(2.22, -9.58, 19.48), Angle(20, 180, 0), 19.16, 13.97)
		ent.cscreen = PxlCashRegister.New "CScreen" (ent, id, Vector(-3.22, 5.39, 16.61), Angle(20, 0, 0), 10.75, 7.85)
		-- ent.pscreen = PxlCashRegister.New "PScreen" (ent, id, Vector(-5.315, 3.25, 9.63), Angle(0,243.4, 87), 3.425, 0.9, 8)
	end
end)

function ENT:Think()
	if SERVER then
		self:CashRegister():Think()
	end
end

-- Drawing function
function ENT:Draw()
	self:DrawModel()
	self.last_draw = CurTime()

	if IsValid(self.uscreen) and IsValid(self.cscreen) then
		self.uscreen:Draw()
		self.cscreen:Draw()
	else
		-- If there has no screen, it will ask to the server to send the cash_register ID
		if CurTime() - self.screen_request > 1 then
			net.Start("CashRegister_Init")
				net.WriteEntity(self)
			net.SendToServer()

			self.screen_request = CurTime()
		end
	end
end

function ENT:OnRemove()
	if SERVER then
		self:CashRegister():Remove()
	else
		if IsValid(self.uscreen) then
			self.uscreen:Remove()
		end
		if IsValid(self.cscreen) then
			self.cscreen:Remove()
		end
	end
end

-- Customer Screen

-- function ENT:Use(ply)
-- 	-- self:CashRegister():Send(ply, "Customer").TryToOpen()
-- end

-- Scanning thing

function ENT:IsScanned(scanner)
	if scanner:AccessoryType() ~= "scanner_holded" then return end

	if self:CashRegister():IsFindingScanner() then
		local err = self:CashRegister():CheckScanner(scanner)

		if err then
			return false, err
		else
			return true, "connect_to_server", {self:CashRegister():Server():Name()}
		end
	else
		return
	end
end

function ENT:SendScanneInfo(scanner)
	if scanner:AccessoryType() ~= "scanner_holded" then return end

	if self:CashRegister():IsFindingScanner() then
		return "connect_to_server", self:CashRegister():Server():Name()
	else
		return self:CashRegister():Server():Name()
	end
end


-- Animation

if CLIENT then




	function ENT:Think()
		if self.uscreen and CurTime() - self.last_draw > 10 and self.uscreen:IsBuilded() and not self.uscreen.connected then
			self.uscreen:RemovePanel()
			self.cscreen:RemovePanel()
		end

		if self.isopen ~= self:GetIsOpen() then
			self.isopen = self:GetIsOpen()
			self.anim_start = CurTime()
			self.anim_run = true

			sound.Play("PxlCashRegister.Drawer", self:GetPos())
		end

		if self.anim_run then
			local time = math.min(CurTime() - self.anim_start, self.anim_time)/self.anim_time
			local pos = math.min(math.tan(time)/1.5, 1)*self.anim_max

			if self.isopen then
				self:ManipulateBonePosition(1, Vector(pos, 0, 0))
			else
				self:ManipulateBonePosition(1, Vector(self.anim_max - pos, 0, 0))
			end

			if time >= 1 then
				self.anim_run = false
			end
		end

		self:NextThink(CurTime())
		return true
	end
else
	function ENT:Anim()
		self:AnimOpen()

		timer.Simple(2, function()
			if not self then return end

			self:AnimClose()
		end)
	end

	function ENT:AnimOpen()
		self:SetIsOpen(true)

		timer.Simple(1.2, function()
			if self:CashRegister():GetCash() > 0 then
				local format = PxlCashRegister.Config.MoneyStyle

				if format == "USD" then
					self:SetSkin(0)
				elseif format == "EUR" then
					self:SetSkin(2)
				end
			else
				self:SetSkin(1)
			end
		end)
	end

	function ENT:AnimClose()
		self:SetIsOpen(false)
	end
end

function ENT:CanProperty(ply, property)
	if property == "skin" then
		return false
	end

	return true
end
