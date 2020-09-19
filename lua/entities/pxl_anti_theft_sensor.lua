AddCSLuaFile()

ENT.Type              	= "anim"
ENT.Base              	= "base_gmodentity"
ENT.PrintName         	= "Anti-Theft Sensor"
ENT.Category          	= "PxlCorp"
ENT.Author            	= "PxlCorp"
ENT.Contact           	= "https://scriptfodder.com/users/view/76561198297110372"
ENT.Spawnable         	= true
ENT.PxlDisableRegister	= true

function ENT:SetupDataTables()
	self:NetworkVar("Int", 0, "Server")

	self:NetworkVar("Entity", 1, "owning_ent")

	self:NetworkVar("Int", 0, "Range")
	self:NetworkVar("Bool", 0, "LeftSide")
	self:NetworkVar("Bool", 1, "RightSide")
end


function ENT:SpawnFunction(ply, tr, ClassName)
	if not tr.Hit then return end

	local SpawnPos = tr.HitPos + tr.HitNormal * 25.5
	local SpawnAng = ply:EyeAngles()
	SpawnAng.p = 0
	SpawnAng.y = SpawnAng.y + 180

	local ent = ents.Create(ClassName)
	ent:SetPos(SpawnPos)
	ent:SetAngles(SpawnAng)
	ent:Spawn()
	ent:Activate()

	return ent
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/pxl/anti_theft_systems/anti_theft_systems_ref.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)

		local phys = self:GetPhysicsObject()
		phys:Wake()
		phys:SetMass(50)

		local theftsensor = PxlCashRegister.New "TheftSensor" ("anti_theft_sensor", self)

		self:SetRange(theftsensor:Option("range"))
		self:SetLeftSide(theftsensor:Option("leftside"))
		self:SetRightSide(theftsensor:Option("rightside"))

		function self:TheftSensor()
			return theftsensor
		end
	end
end

function ENT:Server()
	return self:TheftSensor():Server()
end

function ENT:Think()
	if SERVER then
		self:TheftSensor():Tick()
	end
end

function ENT:OnRemove()
	if SERVER then
		self:TheftSensor():Remove()
	end
end

function ENT:IsScanned(scanner)
	if scanner:AccessoryType() ~= "scanner_holded" then return end

	if self:Server() then
		-- return false, "scanner_already_linked"
	else
		local ply = scanner:User()
		local server = scanner:Server()

		if IsValid(ply) and server and (not server:HasPermission(ply, "option") or (server:IsPersistMod() and not server.can_edit_scanner and not PxlCashRegister.Config.IsAdmin(ply))) then
			return false, "not_allowed"
		else
			if server then
				local err = server:AddAccessory(self:TheftSensor())

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
	if not self:Server() and scanner:Server() then
		return "add_theft_sensor_on", scanner:Server():Name()
	end
end


function ENT:Draw()
	self:DrawModel()

	if IsValid(LocalPlayer()) then
		local wep = LocalPlayer():GetActiveWeapon()

		if IsValid(wep) and wep:GetClass() == "pxl_cr_scanner" then
			local tr = LocalPlayer():GetEyeTrace()

			if tr.Entity == self then
				if tr.StartPos:Distance(tr.HitPos) < 100 then
					local left = self:GetLeftSide() and 1 or 0
					local right = self:GetRightSide() and 1 or 0

					for i = 1 - right, left do
						local global_dir = i*2 - 1
						render.DrawWireframeBox(
							self:LocalToWorld(Vector(0, -5, -(self:OBBMins().z + 5)/2)),
							self:GetAngles(),
							-Vector(0, 20, ((self:OBBMaxs() - self:OBBMins()).z - 5))/2,
							Vector(self:GetRange()*global_dir, 20, ((self:OBBMaxs() - self:OBBMins()).z - 5)/2),
							Color(0, 255, 0))
					end
				end
			end
		end
	end
end

function ENT:CanProperty(ply, property)
	if property == "skin" then
		return false
	end

	return true
end
