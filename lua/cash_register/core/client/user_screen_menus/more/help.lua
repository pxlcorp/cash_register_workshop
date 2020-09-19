
local UScreen = PxlCashRegister.UserScreen
local More = PxlCashRegister.Get("UScreen.More")
local tr = PxlCashRegister.Language.GetDictionary("main")

local Help = PxlCashRegister.NewClass("UScreen.More.Help", "TabPanel")

Help.Name = "help"
Help.Tooltip = "info.help"

function Help:Build(window, panel)
	local dhtml = vgui.Create("DHTML", panel)
	dhtml:Dock(FILL)
	dhtml:DockMargin(0, 0, 0, 0)
	self.dhtml = dhtml

	http.Fetch("https://pxlcorp.github.io/cash_register/help/en.html", function(body)
		if self and self.dhtml then
			self.dhtml:SetHTML(body)
		end
	end,
	function()
		if self and self.dhtml then
			self.dhtml:SetHTML("<h1>ERREUR</h1>")
		end
	end)
end


More:RegisterTab(Help)
