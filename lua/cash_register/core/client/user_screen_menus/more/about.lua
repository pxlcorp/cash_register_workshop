--TODO Implementer le menu About
--TODO Chager le menu a partire d'une page github

local UScreen = PxlCashRegister.UserScreen
local More = PxlCashRegister.Get("UScreen.More")
local tr = PxlCashRegister.Language.GetDictionary("main")

local About = PxlCashRegister.NewClass("UScreen.More.About", "TabPanel")

About.Name = "about"
About.Tooltip = "info.about"

function About:Build(window, panel)
	local dhtml = vgui.Create("DHTML", panel)
	dhtml:Dock(FILL)
	dhtml:DockMargin(0, 0, 0, 0)
	self.dhtml = dhtml

	http.Fetch("https://pxlcorp.github.io/cash_register/about/en.html", function(body)
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

More:RegisterTab(About)
