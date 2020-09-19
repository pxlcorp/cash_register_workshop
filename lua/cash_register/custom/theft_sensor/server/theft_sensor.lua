PxlCashRegister.TheftSensor = PxlCashRegister.NewClass("TheftSensor", "Accessory")
local TheftSensor = PxlCashRegister.TheftSensor

function TheftSensor:Construct(tpe, ent)
	self.__parent.Construct(self, tpe, ent)

	self.alarm = false

	if not ent then return end

	local i = {}
	i.margin = 5
	i.height = (ent:OBBMaxs() - ent:OBBMins()).z - i.margin/2
	i.start = ent:OBBMins().z + i.margin
	i.range = 75
	i.size = 20
	i.filter = function(ent)
		self:CheckEntity(ent)
	end

	self.trace_info = i

	self.last_beeped_players = {}
end

function TheftSensor:CheckEntity(ent)
	if ent.CRSItem then
		if ent.CRSItem:Server() == self:Server() then
			self:Server():TheftAlarmStart()
		end
	end

	if ent:IsPlayer() then
		self:Welcome(ent)
	end
end

function TheftSensor:Tick()
	if self:Server() then
		local ent = self.entity

		if ent then
			local tri = self.trace_info
			local left = self:Option("leftside") and 1 or 0
			local right = self:Option("rightside") and 1 or 0

			for i = 1 - right, left do
				local global_dir = i*2 - 1

				local startpos = ent:LocalToWorld(Vector(0, 0, tri.start + tri.margin))
				local dir = ent:GetForward()*global_dir

				local tr = util.TraceHull({
					start = startpos + dir * tri.size,
					endpos = startpos + dir * self:Option("range"),
					maxs = Vector(tri.size, tri.size, tri.height)/2,
					mins = -Vector(tri.size, tri.size, tri.height)/2,
					ignoreworld = true,
					filter = tri.filter
				})
			end
		end
	end
end

function TheftSensor:Start()
	if self.alarm then return end

	self.alarm = true

	local function beep()
		self.entity:StopSound("PxlTheftSensor.Alarm")
		self.entity:EmitSound("PxlTheftSensor.Alarm")

		self:Entity():SetSkin(1)

		timer.Simple(5.28, function()
			if self.alarm then
				beep()
			end
		end)
	end

	beep()
end


function TheftSensor:Stop()
	if IsValid(self.entity) then
		self.entity:StopSound("PxlTheftSensor.Alarm")
	end

	self:Entity():SetSkin(0)

	self.alarm = false
end


function TheftSensor:Welcome(ply)
	if not self.alarm then
		if CurTime() - (self.last_beeped_players[ply] or 0) > 0.5 then
			if self:Option("beep_player") then
				sound.Play("PxlTheftSensor.Bell", self:Entity():GetPos())
			end

			self:Entity():SetSkin(2)

			timer.Simple(0.5, function()
				if not self.alarm then
					self:Entity():SetSkin(0)
				end
			end)
		end

		self.last_beeped_players[ply] = CurTime()
	end
end


function TheftSensor:OnRemove()
	self:Stop()

	self.__parent.OnRemove(self)
end


TheftSensor.Options = {
	range = {
		Display = "theft_sensor.option_range",
		Type = "number_slider",
		Default = 50,
		Max = 100,
		Min = 20,
		OnChange = function(self, old, new)
			self:Entity():SetRange(new)
		end,
		Order = 1
	},
	leftside = {
		Display = "theft_sensor.option_leftside",
		Type = "boolean",
		Default = false,
		OnChange = function(self, old, new)
			self:Entity():SetLeftSide(new)
		end,
		Order = 2
	},
	rightside = {
		Display = "theft_sensor.option_rightside",
		Type = "boolean",
		Default = true,
		OnChange = function(self, old, new)
			self:Entity():SetRightSide(new)
		end,
		Order = 3
	},
	beep_player = {
		Display = "theft_sensor.option_beep_on_player",
		Type = "boolean",
		Default = true,
		Order = 4
	},
}
