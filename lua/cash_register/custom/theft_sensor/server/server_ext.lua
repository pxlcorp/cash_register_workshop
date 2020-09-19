local Server = PxlCashRegister.Server

Server:OnConstruct("TheftSensor", function(self)
	self.theft_sensor_alert = false
end)

function Server:TheftAlarmStart()
	if self.theft_sensor_alert then return end

	self.theft_sensor_alert = true

	for _, accessory in pairs(self:Accessories()) do
		if accessory:Type() == "TheftSensor" then
			accessory:Start()
		end
	end

	for _, cash_register in pairs(self:CashRegisters()) do
		cash_register:TheftSensorStart()
	end
end

function Server:TheftSensorStop()
	self.theft_sensor_alert = false

	for _, accessory in pairs(self:Accessories()) do
		if accessory:Type() == "TheftSensor" then
			accessory:Stop()
		end
	end

	for _, cash_register in pairs(self:CashRegisters()) do
		cash_register:TheftSensorStop()
	end
end
