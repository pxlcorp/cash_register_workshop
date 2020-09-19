local UScreen = PxlCashRegister.UserScreen
local tr = PxlCashRegister.Language.GetDictionary("main")

local More = PxlCashRegister.NewClass("UScreen.More", "Window")

More.name = "More"

More.Mores = More.Mores or {}

function More:Build(screen, panel)
	local more_list = self:CreateVGUI("DScrollPanel", panel, "SidePanel")
	self.more_list = more_list

	local option_menu = self:CreateVGUI("DPanel", panel, "Container")

	local title_label = self:CreateVGUI("DLabel", more_list, "PageTitle")
	title_label:SetText(tr"more")

	self:CreateVGUI("DPanel", more_list, "Separator")

	more_button_list = self:CreateVGUI("DSizeToContents", more_list, "None")
	more_button_list:Dock(TOP)
	self.more_button_list = more_button_list

	self:CreateVGUI("DPanel", more_list, "Separator")

	local back_button = self:CreateVGUI("DButton", more_list, "MenuButton", "pxl/vgui/arrow_left.png")
	back_button:SetText(tr"back")
	back_button.DoClick = function()
		self:Send().EmitSound()
		screen:Show("Main")
	end

	self:InitTabs(option_menu)
end

function More:OnTabInit(tab)
	local but = self:CreateVGUI("DButton", self.more_button_list, "MenuButton", tab.Icon)
	but:SetText(tr(tab.Name))
	but.DoClick = function()
		self:Send().EmitSound()

		self:Show(tab.Name)
	end

	tab.menu_button = but

	if tab.Tooltip then
		but:SetTooltip(tr(tab.Tooltip))
	end
end

function More:OnTabsRemove()
	self.more_button_list:Clear()
end

function More:OnTabOpen(newtab, oldtab)
	if IsValid(oldtab) then
		oldtab.menu_button.active = false
	end

	newtab.menu_button.active = true
end



function More:Open()
	if not self.activetab then
		for _, tab in pairs(self.tabpanels) do
			self:Show(tab.Name)
			break
		end
	end
end

function More:Close()

end

UScreen:RegisterWindow(More)
