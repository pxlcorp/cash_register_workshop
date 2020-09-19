local UScreen = PxlCashRegister.UserScreen
local Option = PxlCashRegister.Get("UScreen.Option")
local tr = PxlCashRegister.Language.GetDictionary("main")

local Employees = PxlCashRegister.NewClass("UScreen.Option.Employees", "TabPanel")

Employees.Name = "employees"
Employees.Tooltip = "info.employees"

function Employees:Build(window, panel)
	local owner_label = self:CreateVGUI("DLabel", panel, "Header")
	owner_label:SetText(tr("owner_access", "none"))
	owner_label:Dock(TOP)
	owner_label:DockMargin(15, 15, 15, 5)
	self.owner_label = owner_label

	-----------------------

	self:CreateVGUI("DPanel", panel, "SeparatorIn")

	local permission_label = self:CreateVGUI("DLabel", panel, "Title")
	permission_label:SetText(tr"permission")
	permission_label:Dock(TOP)
	permission_label:DockMargin(15, 5, 15, 5)

	local permission_help = self:CreateVGUI("DLabel", panel, "Label")
	permission_help:SetText(tr"permission_help")
	permission_help:Dock(TOP)
	permission_help:DockMargin(15, 5, 15, 5)
	permission_help:SetWrap(true)
	permission_help:SetAutoStretchVertical(true)

	-- self:CreateVGUI("DPanel", panel, "SeparatorIn")

	local money_div = self:CreateVGUI("DPanel", panel, "None")
	money_div:Dock(TOP)
	money_div:DockMargin(15, 5, 15, 0)
	money_div:SetTall(30)

	local money_checkbox = self:CreateVGUI("DCheckBox", money_div, "CheckBox")
	money_checkbox:Dock(LEFT)
	money_checkbox:DockMargin(5, 5, 5, 5)
	money_checkbox:SetWide(20)
	money_checkbox.OnChange = function(cb, val)
		self:Send().ChangePermission("money", val)
		self:Send().EmitSound()
	end
	self.money_checkbox = money_checkbox

	local money_label = self:CreateVGUI("DLabel", money_div, "Label")
	money_label:SetText(tr"money_permission")
	money_label:Dock(FILL)
	money_label:DockMargin(5, 5, 5, 5)
	money_label.DoClick = function() money_checkbox:Toggle() end

	local option_div = self:CreateVGUI("DPanel", panel, "None")
	option_div:Dock(TOP)
	option_div:DockMargin(15, 5, 15, 0)
	option_div:SetTall(30)

	local option_checkbox = self:CreateVGUI("DCheckBox", option_div, "CheckBox")
	option_checkbox:Dock(LEFT)
	option_checkbox:DockMargin(5, 5, 5, 5)
	option_checkbox:SetWide(20)
	option_checkbox.OnChange = function(cb, val)
		self:Send().ChangePermission("option", val)
		self:Send().EmitSound()
	end
	self.option_checkbox = option_checkbox

	local option_label = self:CreateVGUI("DLabel", option_div, "Label")
	option_label:SetText(tr"option_permission")
	option_label:Dock(FILL)
	option_label:DockMargin(5, 5, 5, 5)
	option_label.DoClick = function() option_checkbox:Toggle() end

	local items_div = self:CreateVGUI("DPanel", panel, "None")
	items_div:Dock(TOP)
	items_div:DockMargin(15, 5, 15, 5 )
	items_div:SetTall(30)

	local items_checkbox = self:CreateVGUI("DCheckBox", items_div, "CheckBox")
	items_checkbox:Dock(LEFT)
	items_checkbox:DockMargin(5, 5, 5, 5)
	items_checkbox:SetWide(20)
	items_checkbox.OnChange = function(cb, val)
		self:Send().ChangePermission("items", val)
		self:Send().EmitSound()
	end
	self.items_checkbox = items_checkbox

	local items_label = self:CreateVGUI("DLabel", items_div, "Label")
	items_label:SetText(tr"items_permission")
	items_label:Dock(FILL)
	items_label:DockMargin(5, 5, 5, 5)
	items_label.DoClick = function() items_checkbox:Toggle() end


	self:CreateVGUI("DPanel", panel, "SeparatorIn")

	-----------------------


	local div = self:CreateVGUI("DPanel", panel, "None")
	div:Dock(FILL)
	div:SetTall(280)
	div:DockMargin(0, 0, 0, 15)

	local row_allowed = self:CreateVGUI("DPanel", div, "None")
	row_allowed:Dock(LEFT)
	row_allowed:SetWide(308)

	local row_notallowed = self:CreateVGUI("DPanel", div, "None")
	row_notallowed:Dock(RIGHT)
	row_notallowed:SetWide(308)



	local allowed_label = self:CreateVGUI("DLabel", row_allowed, "Title")
	allowed_label:SetText(tr"allowed_player")
	allowed_label:Dock(TOP)
	allowed_label:DockMargin(15, 10, 15, 8)
	allowed_label:SetAutoStretchVertical(true)
	allowed_label:SetWrap(true)

	local allowed_list = self:CreateVGUI("DScrollPanel", row_allowed, "ColumnListIn")
	allowed_list:Dock(FILL)
	allowed_list:SetTooltip(tr"info.authorized_player", true)
	self.allowed_list = allowed_list



	-----------------------

	local notallowed_label = self:CreateVGUI("DLabel", row_notallowed, "Title")
	notallowed_label:SetText(tr"not_allowed_player")
	notallowed_label:Dock(TOP)
	notallowed_label:DockMargin(15, 10, 15, 8)
	notallowed_label:SetAutoStretchVertical(true)
	notallowed_label:SetWrap(true)

	local notallowed_list = self:CreateVGUI("DScrollPanel", row_notallowed, "ColumnListIn", tr"info.no_more_player")
	notallowed_list:Dock(FILL)
	notallowed_list:SetTooltip(tr"info.unauthorized_player", true)
	self.notallowed_list = notallowed_list
end

function Employees:Open()
	self:Send().NeededInfo("access")
	self:Send().GetEmployeesInfo()
end

function Employees:GetEmployeesInfo(info)
	self.allowed_list:Clear()

	for _, ply in pairs(info.allowed) do
		local column = self:CreateVGUI("DPanel", self.allowed_list, "Column")

		if not ply.isowner then
			local remove_button = self:CreateVGUI("DButton", column, "ColumnDeleteButton")
			remove_button:SetTooltip(tr"info.remove_player")
			remove_button.DoClick = function(but)
				self:Send().EmitSound()
				self:Send().RemovePlayer(ply.uid)
			end
		else
			self.owner_label:SetText(tr("owner_access", ply.name))
		end

		if ply.invitation then
			local invited_tag = self:CreateVGUI("DPanel", column, "ColumnInvitedTag")
			invited_tag:SetTooltip(tr"info.invitation_pending")
		end

		local name_label = self:CreateVGUI("DLabel", column, "ColumnLabel")
		name_label:SetText(ply.name)
	end

	self.notallowed_list:Clear()
	for _, ply in pairs(info.notallowed) do
		local column = self:CreateVGUI("DPanel", self.notallowed_list, "Column")

		local add_button = self:CreateVGUI("DButton", column, "ColumnAddButton")
		add_button:SetTooltip(tr"info.add_player")
		add_button.DoClick = function(but)
			self:Send().EmitSound()
			self:Send().AddPlayer(ply.uid)
		end

		local name_label = self:CreateVGUI("DLabel", column, "ColumnLabel")
		name_label:SetText(ply.name)
	end
		--

	self.money_checkbox:SetChecked(info.permission.money)
	self.option_checkbox:SetChecked(info.permission.option)
	self.items_checkbox:SetChecked(info.permission.items)

	if not info.isowner then
		self.money_checkbox:SetDisabled(true)
		self.option_checkbox:SetDisabled(true)
		self.items_checkbox:SetDisabled(true)
	end
end

Option:RegisterTab(Employees)
