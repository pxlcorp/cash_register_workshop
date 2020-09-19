
if SERVER then
	resource.AddWorkshop("1559063835")

	AddCSLuaFile("cash_register/custom/theft_sensor/client/user_screen_ext.lua")

	include("cash_register/custom/theft_sensor/server/theft_sensor.lua")
	include("cash_register/custom/theft_sensor/server/cash_register_ext.lua")
	include("cash_register/custom/theft_sensor/server/server_ext.lua")
else
	include("cash_register/custom/theft_sensor/client/user_screen_ext.lua")
end

hook.Add("InitPostEntity","PxlTheftSensor",function()
	DarkRP.createEntity(
		"Pxl Anti-Theft Sensor",
		{
			ent	= "pxl_anti_theft_sensor",
			model = "models/pxl/anti_theft_systems/anti_theft_systems_ref.mdl",
			max = 5,
			price = 100,
			cmd = "buy_pxltheftsensor"
		}
	)
end)

sound.Add({
	name = "PxlTheftSensor.Bell",
	channel = CHAN_STATIC,
	volume = 1,
	level = 60,
	pitch = 100,
	sound = "pxl/theft_sensor/bell.ogg"
})

sound.Add({
	name = "PxlTheftSensor.Alarm",
	channel = CHAN_STATIC,
	volume = 1,
	level = 65,
	pitch = 100,
	sound = "pxl/theft_sensor/alarm.wav"
})
