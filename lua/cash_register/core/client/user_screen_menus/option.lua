local UScreen = PxlCashRegister.UserScreen
local tr = PxlCashRegister.Language.GetDictionary("main")

local Option = PxlCashRegister.NewClass("UScreen.Option", "Window")

Option.name = "Option"

Option.Options = Option.Options or {}

function Option:Build(screen, panel)
	local options_list = self:CreateVGUI("DScrollPanel", panel, "SidePanel")
	self.options_list = options_list

	local option_menu = self:CreateVGUI("DPanel", panel, "Container")

	local title_label = self:CreateVGUI("DLabel", options_list, "PageTitle")
	title_label:SetText(tr"option")

	self:CreateVGUI("DPanel", options_list, "Separator")

	options_button_list = self:CreateVGUI("DSizeToContents", options_list, "None")
	options_button_list:Dock(TOP)
	self.options_button_list = options_button_list

	self:CreateVGUI("DPanel", options_list, "Separator")

	local add_scanner_button = self:CreateVGUI("DButton", options_list, "MenuButton", "pxl/vgui/add.png")
	add_scanner_button:SetText(tr"add_scanner")
	add_scanner_button.DoClick = function()
		self:Send().EmitSound()
		self:Send().FindScanner()
	end

	self:CreateVGUI("DPanel", options_list, "Separator")

	local back_button = self:CreateVGUI("DButton", options_list, "MenuButton", "pxl/vgui/arrow_left.png")
	back_button:SetText(tr"back")
	back_button.DoClick = function()
		self:Send().EmitSound()
		screen:Show("Main")
	end

	self:InitTabs(option_menu)
end

function Option:OnTabInit(tab)
	local but = self:CreateVGUI("DButton", self.options_button_list, "MenuButton", tab.Icon)
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

function Option:OnTabsRemove()
	self.options_button_list:Clear()
end

function Option:OnTabOpen(newtab, oldtab)
	if IsValid(oldtab) then
		oldtab.menu_button.active = false
	end

	newtab.menu_button.active = true
end

function Option:Open()
	if not self.activetab then
		for _, tab in pairs(self.tabpanels) do
			self:Show(tab.Name)
			break
		end
	end
end

function Option:Close()

end

UScreen:RegisterWindow(Option)
