--[[---------------------------------------------------------
	Customer Screen
-----------------------------------------------------------]]
	PxlCashRegister.CustomerScreen = PxlCashRegister.NewClass("CScreen", "Screen")
	local CScreen = PxlCashRegister.CustomerScreen
	CScreen:InitNet("CashRegister_CustomerScreen")
	CScreen.Windows	= CScreen.Windows	or {}
	CScreen.Payments = {}

	local tr = PxlCashRegister.Language.GetDictionary("main")

--[[----------------------------------------------------------
	Object
------------------------------------------------------------]]

	function CScreen:Construct(ent, id, pos, ang, wide, height)
		self.__parent.Construct(self, ent, pos, ang, wide, height, 480)
		self:SetID(id)

		self.popups = {}

		self:InitPanel()

		self:Show("Preview")

		return self
	end
