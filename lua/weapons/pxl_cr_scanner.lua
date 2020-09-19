SWEP.PrintName	= "Handheld Scanner"
SWEP.Spawnable	= true
SWEP.Author   	= "PxlCorp"
SWEP.Contact  	= "https://scriptfodder.com/users/view/76561198297110372"

SWEP.ViewModel	= "models/pxl/hand_scanner/v_scanner_reference.mdl"
SWEP.WorldModel = "models/pxl/hand_scanner/w_scanner_reference.mdl"

SWEP.Spawnable     	= true
SWEP.AdminSpawnable	= true

SWEP.Weight        	= 10
SWEP.AutoSwitchTo  	= true
SWEP.AutoSwitchFrom	= true

SWEP.DisableDuplicator = true

SWEP.Primary.ClipSize   	= -1
SWEP.Primary.DefaultClip	= -1
SWEP.Primary.Automatic  	= false
SWEP.Primary.Ammo       	= "none"

SWEP.Secondary.ClipSize   	= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatie  	= false
SWEP.Secondary.Ammo       	= "none"

SWEP.ScanneRange = 100

function SWEP:Initialize()
	self:SetHoldType("pistol")

	if SERVER then
		timer.Simple(0, function()
			if not self:Scanner() then
				self:Remove()
			end

		end)
	else
		self.scanner = PxlCashRegister.New "Scanner" (self:GetScanner())
	end
end

function SWEP:Think()
	if CLIENT then return end

	local ply = self:GetOwner()
	local ent = self:Scanner():Trace(ply:EyePos(), ply:GetAimVector(), self.ScanneRange, ply)

	self:Scanner():SetTitle(self:Scanner():GetInfo(ent))
end

function SWEP:Scanner()
	return self.scanner
end

function SWEP:CashRegister()
	return self:Scanner():CashRegister()
end

function SWEP:SetupDataTables()
	self:NetworkVar("Int", 0, "CashRegister")
	self:NetworkVar("Int", 0, "Scanner")
	self:NetworkVar("Entity", 1, "Holder")
end

function SWEP:PrimaryAttack()
	self.Owner:SetAnimation(PLAYER_ATTACK1)
	self.Weapon:SendWeaponAnim(ACT_VM_PRIMARYATTACK)

	self:SetNextPrimaryFire(CurTime() + 0.6)

	if CLIENT then return end
	local ply = self:GetOwner()
	local ent = self:Scanner():Trace(ply:EyePos(), ply:GetAimVector(), self.ScanneRange, ply)


	local r_succ, r_msg, r_args = self:Scanner():RegisterEnt(ent)
	r_args = r_args or {}

	if r_succ then
		self:Scanner():EmitSound(self)
		if r_msg then self:Scanner():Message(r_msg, unpack(r_args)) end
	elseif r_succ == false then
		if r_msg then self:Scanner():Message(r_msg, unpack(r_args)) end
	else
		local c_succ, c_msg, c_args = self:Scanner():CheckEnt(ent)
		c_args = c_args or {}

		if c_succ then
			self:Scanner():EmitSound(self)
			if c_msg then self:Scanner():Message(c_msg, unpack(c_args)) end
		elseif c_succ == false then
			if c_msg then self:Scanner():Message(c_msg, unpack(c_args)) end
		else
			if r_msg then self:Scanner():Message(r_msg, unpack(r_args)) end
		end
	end
end

function SWEP:SecondaryAttack()
	return
end

function SWEP:OnDrop()
	self:Remove()
end

function SWEP:OnRemove()
	if SERVER then
		if self:GetHolder() then
			self:Scanner():SetUser(NULL)
			self:GetHolder():SetScanner(NULL)
		else
			self:Scanner():Remove()
		end
	else
		self:Scanner():Remove()
	end

	if IsValid(self:GetHolder()) then
		self:GetHolder():SetScanner(nil)
	end
end

function SWEP:Holster(wep)
	if SERVER then
		if IsValid(self:GetHolder()) then
			self:Remove()
		end
	end

	return true
end
local t = 0
function SWEP:PostDrawViewModel(vm, weapon, ply)
	t = t + 1
	local pos, ang = LocalToWorld(Vector(12.9, 5.15, -3.8), Angle(-105, -105, 48), vm:GetBonePosition(2), vm:GetBoneMatrix(2):GetAngles())
	self:Scanner():DrawScreen(pos, ang, 0.0175)
end

function SWEP:DrawWorldModel()
	self:DrawModel()

	-- cam.Start3D2D(self:LocalToWorld(Vector(2.2, -1.5, 2)), self:LocalToWorldAngles(Angle(-5, 92, 60)), 0.02)
	--	draw.RoundedBox(5, 0, 0, 1200, 1200, Color(0, 0, 0))
	-- cam.End3D2D()
end
