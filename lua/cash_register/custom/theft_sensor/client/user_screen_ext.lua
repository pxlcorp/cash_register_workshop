local UScreen = PxlCashRegister.UserScreen

local tr = PxlCashRegister.Language.GetDictionary("theft_sensor")


function UScreen:TheftSensorPopup()
	self.theftsensorpopup = self:PopupTitle(tr"main.warning", tr"warning",
		{tr"stop_alarm", function()
			self:Send().TheftSensorStop()
			return true
		end})
end

function UScreen:TheftSensorClose()
	self:RemovePopup(self.theftsensorpopup)
	self.theftsensorpopup = nil
end
