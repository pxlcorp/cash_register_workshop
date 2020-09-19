local CashRegister = PxlCashRegister.CashRegister

CashRegister:OnConstruct("TheftSensor", function(self, ent)
	self.theft_sensor_alert = false
end)

CashRegister:On("Connect", "TheftSensor", function(self, info)
	if self.theft_sensor_alert then
		timer.Simple(0, function()
			self:Send(self:Users()).TheftSensorPopup()
		end)
	end
end)


function CashRegister:TheftSensorStart()
	if self.theft_sensor_alert then return end

	self.theft_sensor_alert = true
	self:Send(self:Users()).TheftSensorPopup()
end

function CashRegister:TheftSensorStop()
	self:Send(self:Users()).TheftSensorClose()
	self.theft_sensor_alert = false
end

function CashRegister.Receive:TheftSensorStop(ply)
	if not self.users[ply] then return end

	self:Server():TheftSensorStop()
end
