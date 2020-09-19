local UScreen = PxlCashRegister.UserScreen
local Option = PxlCashRegister.Get("UScreen.Option")
local tr = PxlCashRegister.Language.GetDictionary("main")

local Accessories = PxlCashRegister.NewClass("UScreen.Option.Accessories", "TabPanel")

Accessories.Name = "accessories"
Accessories.Tooltip = "info.accessories"

function Accessories:Build(window, panel)
    local accessories_label = self:CreateVGUI("DLabel", panel, "Header")
    accessories_label:SetText(tr"accessories")
    accessories_label:Dock(TOP)
    accessories_label:DockMargin(15, 15, 15, 8)

	local accessories_help = self:CreateVGUI("DLabel", panel, "Label")
	accessories_help:SetText(tr"info.accessories_help")
	accessories_help:Dock(TOP)
	accessories_help:DockMargin(15, 5, 15, 5)
	accessories_help:SetTall(40)
	accessories_help:SetWrap(true)

    local accessories_list = self:CreateVGUI("DScrollPanel", panel, "ColumnListIn")
    accessories_list:Dock(FILL)
    accessories_list:DockMargin(15, 5, 15, 15)
	self.accessories_list = accessories_list
end

function Accessories:GetAccessoriesInfo(accessories)
	self.accessories_list:Clear()

	for _, accessory in pairs(accessories) do
		local column = self:CreateVGUI("DPanel", self.accessories_list, "Column")

		local remove_button = self:CreateVGUI("DButton", column, "ColumnDeleteButton")
		remove_button.DoClick = function(but)
			self:Send().RemoveAccessory(accessory.id)
		end

		if accessory.editable then
			local edit_button = self:CreateVGUI("DButton", column, "ColumnEditButton")
			edit_button.DoClick = function(but)
				self:EditAccessory(accessory.id)
			end
		end

		local name_label = self:CreateVGUI("DLabel", column, "ColumnLabel")
		name_label:SetText(tr("%s [%i]", tr("accessories." .. accessory.type), accessory.id))
	end
end

function Accessories:EditAccessory(id)
	self:Send().GetAccessoryOptions(id, function(options)
		self:Screen():CustomPopup(function(panel, box)
			local entries = {}

			local sort_options = {}
			for name, option in pairs(options) do
				option.Name = name
				sort_options[option.Order] = option
			end

			for _, option in pairs(sort_options) do
				local div = self:CreateVGUI("DPanel", box, "None")
				div:Dock(TOP)
				div:DockMargin(0, 0, 0, 10)
				div:DockPadding(0, 0, 0, 0)
				div:SetTall(30)

				entries[option.Name] = Accessories.SettingsType[option.Type](self, div, option)
			end


			return {{tr"close"},
			{tr"apply", function()
				new_options = {}

				for name, entry in pairs(entries) do
					local err = entry.CheckValue()

					if not err then
						new_options[name] = entry.GetValue()
					else
						self:Message(err)
						return true
					end
				end

				self:Send().SetAccessoryOptions(id, new_options)
			end}}
		end)
	end)
end

function Accessories:Open()
	self:Send().NeededInfo("accessory")
	self:Send().GetAccessoriesInfo()
end



Accessories.SettingsType = {
	number = function(self, div, option)
		local label = self:CreateVGUI("DLabel", div, "Label")
		label:Dock(TOP)
		label:DockMargin(0, 0, 0, 5)
		label:SetText(tr(option.Display))

		local entry = self:CreateVGUI("DTextEntry", box, "TextEntry")
		entry:Dock(TOP)
		entry:DockMargin(0, 0, 0, 0)
		entry:SetText(option.Value)
		entry:SetFont("Cash_Register_Basic")
		entry:SetMultiline(true)
		entry:SetTall(75)

		return {
			GetValue = function()
				return tonumber(entry:GetText())
			end,

			CheckValue = function()
				if not isnumber(tonumber(entry:SetText())) then
					return "invalid_number"
				end
			end
		}
	end,

	number_slider = function(self, div, option)
		local slider = self:CreateVGUI("DNumSlider", div, "Slider")
		slider:Dock(FILL)
		slider:DockMargin(0, 0, 0, 0)
		slider:SetText(tr(option.Display))
		slider:SetMin(option.Min)
		slider:SetMax(option.Max)
		slider:SetValue(option.Value)
		slider:SetDecimals(0)

		return {
			GetValue = function()
				return slider:GetValue()
			end,

			CheckValue = function()

				if not isnumber(slider:GetValue()) then
					return "invalid_slider"
				end
			end
		}
	end,

	boolean = function(self, div, option)
		local checkbox = self:CreateVGUI("DCheckBox", div, "CheckBox")
		checkbox:Dock(LEFT)
		checkbox:DockMargin(0, 0, 5, 0)
		checkbox:SetWide(22)
		checkbox:SetChecked(option.Value)

		local label = self:CreateVGUI("DLabel", div, "Label")
		label:Dock(FILL)
		label:DockMargin(0, 0, 0, 0)
		label:SetText(tr(option.Display))
		label.DoClick = checkbox.DoClick


		return {
			GetValue = function()
				return checkbox:GetChecked()
			end,

			CheckValue = function()
				if not isbool(checkbox:GetChecked()) then
					return "invalid_bool"
				end
			end
		}
	end,

	string = function(self, box, option, value)


		return {
			GetValue = function()

			end,

			CheckValue = function()

			end
		}
	end
}



Option:RegisterTab(Accessories)
