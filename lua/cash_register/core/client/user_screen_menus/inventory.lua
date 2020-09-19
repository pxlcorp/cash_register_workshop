local UScreen = PxlCashRegister.UserScreen
local tr = PxlCashRegister.Language.GetDictionary("main")

local Inventory = PxlCashRegister.NewClass("UScreen.Inventory", "Window")

Inventory.name = "Inventory"

function Inventory:Build(screen, panel)
	self.items = {}
	self.items_group = {}

	local buttons_panel = self:CreateVGUI("DPanel", panel, "SidePanel")

	local items_list = self:CreateVGUI("DScrollPanel", panel, "ColumnList", tr"info.no_item_in_inventory")
	self.items_list = items_list

	local title_label = self:CreateVGUI("DLabel", buttons_panel, "PageTitle")
	title_label:SetText(tr"items_list")

	local description_label = self:CreateVGUI("DLabel", buttons_panel, "PageDescription")
	description_label:SetText(tr"info.inventory")

	self:CreateVGUI("DPanel", buttons_panel, "Separator")

	local clear_button = self:CreateVGUI("DButton", buttons_panel, "MenuButton", "pxl/vgui/refresh.png", 16)
	clear_button:SetText(tr"clear")
	clear_button:SetTooltip(tr"info.clear_inventory")
	clear_button.DoClick = function()
		self:Send().EmitSound()
		self:PopupTitle(tr"warning", tr"sure_to_clear_server",
		{tr"cancel"},
		{tr"clear", function()
			self:Send().ClearServer()
		end})
	end

	self:CreateVGUI("DPanel", buttons_panel, "Separator")
	
	local show_button = self:CreateVGUI("DButton", buttons_panel, "MenuButton", 
		"pxl/vgui/checkbox_" .. (screen.show_empty_cat and "on" or "off") .. "16.png", 16)
	show_button:SetText(tr"show_empty")
	show_button:SetTooltip(tr"info.show_empty")
	show_button.DoClick = function()
		self:Send().EmitSound()
		if screen.show_empty_cat then
			show_button.icon = "pxl/vgui/checkbox_off16.png"
		else
			show_button.icon = "pxl/vgui/checkbox_on16.png"
		end

		screen.show_empty_cat = not screen.show_empty_cat
		
		self:ClearServerItems()
		self:Send().GetServerItems(screen.show_empty_cat)

	end
	self.show_button = show_button

	local load_button = self:CreateVGUI("DButton", buttons_panel, "MenuButton", "pxl/vgui/arrow_down.png", 16)
	load_button:SetText(tr"load_profile")
	load_button:SetTooltip(tr"info.load_profile")
	load_button.DoClick = function()
		self:Send().EmitSound()
		self:LoadProfile()
	end

	local save_button = self:CreateVGUI("DButton", buttons_panel, "MenuButton", "pxl/vgui/arrow_up.png", 16)
	save_button:SetText(tr"save_profile")
	save_button:SetTooltip(tr"info.save_profile")
	save_button.DoClick = function()
		self:Send().EmitSound()
		self:SaveProfile()
	end

	local remove_profile_button = self:CreateVGUI("DButton", buttons_panel, "MenuButton", "pxl/vgui/x-mark.png", 16)
	remove_profile_button:SetText(tr"remove_profile")
	remove_profile_button:SetTooltip(tr"info.remove_profile")
	remove_profile_button.DoClick = function()
		self:Send().EmitSound()
		self:RemoveProfile()
	end

	local clear_profile_button = self:CreateVGUI("DButton", buttons_panel, "MenuButton", "pxl/vgui/refresh.png", 16)
	clear_profile_button:SetText(tr"clear_profile")
	clear_profile_button:SetTooltip(tr"info.clear_profile")
	clear_profile_button.DoClick = function()
		self:Send().EmitSound()
		self:PopupTitle(tr"warning", tr"sure_to_clear_server",
		{tr"cancel"},
		{tr"clear", function()
			self:Send().ClearProfile()
		end})
	end

	self:CreateVGUI("DPanel", buttons_panel, "Separator")


	local back_button = self:CreateVGUI("DButton", buttons_panel, "MenuButton", "pxl/vgui/arrow_left.png")
	back_button:SetText(tr"back")
	back_button.DoClick = function()
		self:Send().EmitSound()
		screen:Show("Main")
	end
end



function Inventory:Open()
	self:Send().NeededInfo("server_items")
	self:Send().GetServerItems(self:Screen().show_empty_cat)
end



function Inventory:Close()
	self:ClearServerItems()
end



function Inventory:AddServerItem(itm)
	if self.items_group[itm.groupid] then
		local group = self.items_group[itm.groupid]

		group.quantity = group.quantity + 1
		group.items[itm.id] = itm

		group.column.quantity:SetText(tr("%d x", group.quantity))
		group.column.quantity:SetVisible(true)

		surface.SetFont("Cash_Register_Title")
		group.column.quantity:SetWide(surface.GetTextSize(group.column.quantity:GetText()))

		itm.column = group.column
		itm.group = group		
	else
		local column = self:CreateVGUI("DPanel", self.items_list, "Column")
		column:SetTall(60)

		if itm.model then
			local icon_background = self:CreateVGUI("DPanel", column, "PanelIn")
			icon_background:Dock(LEFT)
			icon_background:DockMargin(0, 9, 10, 9)
			icon_background:SetWide(42)

			local icon = vgui.Create( "SpawnIcon", icon_background)
			icon:Dock(FILL)
			icon:DockMargin(5, 5, 5, 5)
			icon:SetDisabled(true)
			icon:SetModel(itm.model)
		end

		local delete_button = self:CreateVGUI("DButton", column, "ColumnDeleteButton")
		delete_button:SetTooltip(tr"info.remove_item_cart")
		delete_button.DoClick = function(but)
			self:Send().EmitSound()
			
			if itm.groupid then
				if itm.group.quantity > 0 then
					for id, itm in pairs(itm.group.items) do
						self:Send().RemoveServerItem(id)
						break
					end
				else
					self:PopupTitle(tr"warning", tr"sure_to_remove_group",
						{tr"cancel"},
						{tr"remove", function()
							self:Send().RemoveServerItemGroup(itm.groupid)
						end})
				end
			else
				self:Send().RemoveServerItem(itm.id)
			end
		end
		
		local edit_button = self:CreateVGUI("DButton", column, "ColumnEditButton")
		edit_button:SetTooltip(tr"info.edit_item")
		edit_button.DoClick = function(but)
			self:Send().EmitSound()

			if itm.groupid then
				self:StartEditing(itm.group)
			else
				self:StartEditing(itm)
			end
		end

		local quantity_label = self:CreateVGUI("DLabel", column, "Label")
		quantity_label:Dock(LEFT)
		quantity_label:DockMargin(0, 10, 10, 7)
		quantity_label:SetContentAlignment(7)
		quantity_label:SetFont("Cash_Register_Title")
		quantity_label:SizeToContents(true)
		quantity_label:SetVisible(self:Screen().show_empty_cat or not itm.id)
		quantity_label:SetText(tr("%d x", isnumber(itm.id) and 1 or 0))

		surface.SetFont("Cash_Register_Title")
		quantity_label:SetWide(surface.GetTextSize(quantity_label:GetText()))

		column.quantity = quantity_label

		local text_box = self:CreateVGUI("DPanel", column, "None")
		text_box:Dock(FILL)
		text_box:DockMargin(0, 7, 0, 7)

		local name_label = self:CreateVGUI("DLabel", text_box, "Label")
		name_label:SetText(itm.name)
		name_label:Dock(TOP)
		column.name = name_label

		local price_label = self:CreateVGUI("DLabel", text_box, "Label")
		price_label:SetText(tr("$", itm.cost))
		price_label:SizeToContents()
		price_label:Dock(TOP)
		price_label:DockMargin(0, 3, 0, 0)
		column.cost = price_label

		itm.column = column

		if itm.groupid then
			self.items_group[itm.groupid] = {
				id = itm.groupid,
				column = column,
				quantity = isnumber(itm.id) and 1 or 0,
				name = itm.name,
				cost = itm.cost,
				items = {}
			}

			itm.group = self.items_group[itm.groupid]

			if itm.id then
				itm.group.items[itm.id] = itm
			end
		end
	end
	
	if itm.id then
		self.items[itm.id] = itm
	end
end



function Inventory:RemoveServerItem(id)
	local itm = self.items[id]

	if itm.group then
		local group = itm.group

		if group.quantity > 1 or self:Screen().show_empty_cat then
			group.quantity = group.quantity - 1
			group.items[id] = nil
			
			group.column.quantity:SetText(tr("%d x", group.quantity))
			
			surface.SetFont("Cash_Register_Title")
			group.column.quantity:SetWide(surface.GetTextSize(group.column.quantity:GetText()))

			group.column.quantity:SetVisible(true)
			
			if group.quantity == 1 and not self:Screen().show_empty_cat then
				group.column.quantity:SetVisible(false)
				group.column:InvalidateLayout(true)
			end
		else 
			self.items_group[group.id] = nil
			group.column:Remove()
		end
	else
		self.items[id].column:Remove()
	end
	
	self.items[id] = nil
end



function Inventory:RemoveServerItemGroup(id)
	local group = self.items_group[id]

	if group then
		group.column:Remove()

		self.items_group[id] = nil
	end
end



function Inventory:EditServerItem(itm)
	local itm = table.Merge(self.items[itm.id], itm)

	itm.column.name:SetText(itm.name)
	itm.column.cost:SetText(tr("$", itm.cost))
end



function Inventory:EditServerItemGroup(grp_info)
	local group = table.Merge(self.items_group[grp_info.id], grp_info)

	group.column.name:SetText(grp_info.name)
	group.column.cost:SetText(tr("$", grp_info.cost))
end



function Inventory:ClearServerItems(refresh)
	if not self:IsVisible() then return end

	self.items_list:Clear()
	self.items = {}
	self.items_group = {}

	if refresh then
		self:Send().GetServerItems(self:Screen().show_empty_cat)
	end
end



function Inventory:SendServerItems(info, show_empty)
	self:ClearServerItems()

	if show_empty then
		self.show_button.icon = "pxl/vgui/checkbox_on16.png"
		self:Screen().show_empty_cat = true
	end

	for id, itm in pairs(info) do
		self:AddServerItem(itm)
	end
end



function Inventory:StartEditing(itm)
	self:CustomPopup(tr"editing", function(panel, box)
		local description_label = self:CreateVGUI("DLabel", box, "Label")
		description_label:SetAutoStretchVertical(true)
		description_label:SetWrap(true)
		description_label:SetText(tr"info.edit_item")
		description_label:Dock(TOP)
		description_label:DockMargin(0, 0, 0, 10)

		self:CreateVGUI("DPanel", box, "SeparatorIn"):DockMargin(0, 0, 0, 10)

		local name_label = self:CreateVGUI("DLabel", box, "Label")
		name_label:Dock(TOP)
		name_label:DockMargin(0, 0, 0, 2)
		name_label:SetText(tr"name")
		name_label:SetFont("Cash_Register_Basic")

		local name_entry = self:CreateVGUI("DTextEntry", box, "TextEntry")
		name_entry:Dock(TOP)
		name_entry:DockMargin(0, 0, 0, 10)
		name_entry:SetText(itm.name)

		local cost_label = self:CreateVGUI("DLabel", box, "Label")
		cost_label:Dock(TOP)
		cost_label:DockMargin(0, 0, 0, 2)
		cost_label:SetText(tr"cost")

		local cost_entry = self:CreateVGUI("DTextEntry", box, "TextEntry")
		cost_entry:Dock(TOP)
		cost_entry:DockMargin(0, 0, 0, 0)
		cost_entry:SetText(itm.cost)
		cost_entry:SetNumeric(true)

		return {
			{tr"close"},
			{tr"accept", function()
				self:Send().EditItem(itm.groupid or itm.id, name_entry:GetValue(), tonumber(cost_entry:GetValue()))
			end}
		}
	end)
end





function Inventory:LoadProfile()
	self:CustomPopup(tr"load_profile", function(panel, box)
		local profile_list = self:CreateVGUI("DScrollPanel", box, "ColumnListIn", tr"info.no_profile")
		profile_list:Dock(TOP)
		profile_list:SetTall(200)
		profile_list:DockMargin(0, 0, 0, 0)

		function profile_list.AddFile(profile_list, name)
			local lbl = self:CreateVGUI("DButton", profile_list, "Label")
			lbl:Dock(TOP)
			lbl:DockMargin(5, 5, 5, 0)
			lbl:SetText(name)
			lbl:SetCursor("hand")
			lbl:SetContentAlignment(4)
			
			lbl.DoClick = function(lbl)
				self:Send().EmitSound()

				if profile_list.selectedlbl == lbl then
					lbl.selected = false

					profile_list.selectedlbl = nil
					profile_list.selected = nil

					return
				end

				lbl.selected = true

				if profile_list.selectedlbl then
					profile_list.selectedlbl.selected = false
				end

				profile_list.selectedlbl = lbl
				profile_list.selected = name
			end

			lbl.Paint = function(lbl, w, h)
				if lbl.selected then
					draw.RoundedBox(5, 0, 0, w, h, Color(10, 150, 255, 100))
				end
			end

			return lbl
		end

		local have_local_file = false
		
		for _, name in pairs(PxlCashRegister.Profile.GetProfilesList()) do
			profile_list:AddFile(name)
			have_local_file = true
		end

		self:Send().GetProfilesList(function(profiles)
			if istable(profiles) and #profiles > 0 then
				if have_local_file then
					self:CreateVGUI("DPanel", profile_list, "SeparatorIn"):DockMargin(5, 2, 5, 2)
				end

				for _, name in pairs(profiles) do
					profile_list:AddFile(name).on_server = true
				end
			end
		end)

		return {
			{tr"close"},
			{tr"load", function()
				local name = profile_list.selected

				if name then
					if profile_list.selectedlbl.on_server then

					else
						local profile = PxlCashRegister.Profile.LoadProfile(name)

						if istable(profile) then
							self:Send().LoadProfile(name, profile, self:Screen().show_empty_cat or false, function(err)
								if isstring(err) then
									self:Popup(tr(err))
								else
									self:Popup(tr"profile_loaded_success")
								end
							end)
						elseif isstring(profile) then
							self:Popup(tr(profile))
							self:LoadProfile()
						end
					end
				else
					self:LoadProfile()
				end
			end}
		}
	end)
end





function Inventory:SaveProfile()
	self:CustomPopup(tr"save_profile", function(panel, box)

		local profile_entry = self:CreateVGUI("DTextEntry", box, "TextEntry")
		profile_entry:Dock(TOP)
		profile_entry:DockMargin(0, 0, 0, 10)
		profile_entry:SetText("")
		profile_entry:SetFont("Cash_Register_Basic")


		local profile_list = self:CreateVGUI("DScrollPanel", box, "ColumnListIn", tr"info.no_profile")
		profile_list:Dock(TOP)
		profile_list:SetTall(200)
		profile_list:DockMargin(0, 0, 0, 0)

		local server_div = self:CreateVGUI("DPanel", box, "None")
		server_div:Dock(TOP)
		server_div:DockMargin(0, 5, 0, 0)
		server_div:SetTall(30)
		server_div:SetVisible(false)

		local server_checkbox = self:CreateVGUI("DCheckBox", server_div, "CheckBox")
		server_checkbox:Dock(LEFT)
		server_checkbox:DockMargin(0, 5, 5, 5)
		server_checkbox:SetWide(20)
		server_checkbox.OnChange = function(cb, val)
			-- self:Send().ChangePermission("server", val)
			-- self:Send().EmitSound()
		end
		self.server_checkbox = server_checkbox

		local server_label = self:CreateVGUI("DLabel", server_div, "Label")
		server_label:SetText(tr"save_on_server")
		server_label:Dock(FILL)
		server_label:DockMargin(5, 5, 5, 5)
		server_label.DoClick = function() server_checkbox:Toggle() end


		function profile_list.AddFile(profile_list, name)
			local lbl = self:CreateVGUI("DButton", profile_list, "Label")
			lbl:Dock(TOP)
			lbl:DockMargin(5, 5, 5, 0)
			lbl:SetText(name)
			lbl:SetCursor("hand")
			lbl:SetContentAlignment(4)
			
			lbl.DoClick = function(lbl)
				self:Send().EmitSound()

				if profile_list.selectedlbl == lbl then
					lbl.selected = false

					profile_list.selectedlbl = nil
					profile_list.selected = nil

					return
				end

				lbl.selected = true

				if profile_list.selectedlbl then
					profile_list.selectedlbl.selected = false
				end

				profile_list.selectedlbl = lbl
				profile_list.selected = name

				profile_entry:SetValue(name)
				server_checkbox:SetChecked(lbl.on_server)
			end

			lbl.Paint = function(lbl, w, h)
				if lbl.selected then
					draw.RoundedBox(5, 0, 0, w, h, Color(10, 150, 255, 100))
				end
			end

			return lbl
		end


		local have_local_file = false

		for _, name in pairs(PxlCashRegister.Profile.GetProfilesList()) do
			have_local_file = true

			profile_list:AddFile(name)
		end


		profile_entry.OnTextChanged = function()
			if profile_list.selectedlbl then
				profile_list.selectedlbl.selected = false

				profile_list.selectedlbl = lbl
				profile_list.selected = name
			end

		end

		self:Send().GetProfilesList(true, function(profiles)
			if istable(profiles) then
				server_div:SetVisible(true)

				if #profiles > 0 then
					if have_local_file then
						self:CreateVGUI("DPanel", profile_list, "SeparatorIn"):DockMargin(5, 2, 5, 2)
					end

					for _, name in pairs(profiles) do
						profile_list:AddFile(name).on_server = true
					end
				end
			end
		end)

		return {
			{tr"close"},
			{tr"save", function()
				if profile_entry:GetText() ~= "" then
					local name = string.Trim(profile_entry:GetText())
					local on_server = server_checkbox:GetChecked() or false

					self:Send().SaveProfile(name, on_server, function(profile)
						if istable(profile) then
							PxlCashRegister.Profile.SaveProfile(name, profile)
							self:Popup(tr"profile_saved_success")
						elseif isstring(profile) then
							self:SaveProfile()
							self:Popup(tr(profile))
						else
							self:Popup(tr"profile_saved_success")
						end
					end)
				else
					self:SaveProfile()
				end
			end}
		}
	end)
end

function Inventory:RemoveProfile()
	self:CustomPopup(tr"remove_profile", function(panel, box)
		local profile_list = self:CreateVGUI("DScrollPanel", box, "ColumnListIn", tr"info.no_profile")
		profile_list:Dock(TOP)
		profile_list:SetTall(200)
		profile_list:DockMargin(0, 0, 0, 0)

		function profile_list.AddFile(profile_list, name)
			local lbl = self:CreateVGUI("DButton", profile_list, "Label")
			lbl:Dock(TOP)
			lbl:DockMargin(5, 5, 5, 0)
			lbl:SetText(name)
			lbl:SetCursor("hand")
			lbl:SetContentAlignment(4)
			
			lbl.DoClick = function(lbl)
				self:Send().EmitSound()

				if profile_list.selectedlbl == lbl then
					lbl.selected = false

					profile_list.selectedlbl = nil
					profile_list.selected = nil

					return
				end

				lbl.selected = true

				if profile_list.selectedlbl then
					profile_list.selectedlbl.selected = false
				end

				profile_list.selectedlbl = lbl
				profile_list.selected = name
			end

			lbl.Paint = function(lbl, w, h)
				if lbl.selected then
					draw.RoundedBox(5, 0, 0, w, h, Color(10, 150, 255, 100))
				end
			end

			return lbl
		end

		local have_local_file = false

		for _, name in pairs(PxlCashRegister.Profile.GetProfilesList()) do
			have_local_file = true

			profile_list:AddFile(name)
		end

		self:Send().GetProfilesList(true, function(profiles)
			if istable(profiles) and #profiles > 0 then
				if have_local_file then
					self:CreateVGUI("DPanel", profile_list, "SeparatorIn"):DockMargin(5, 2, 5, 2)
				end

				for _, name in pairs(profiles) do
					profile_list:AddFile(name).on_server = true
				end
			end
		end)

		return {
			{tr"close"},
			{tr"remove", function()
				local name = profile_list.selected

				if name then
					if profile_list.selectedlbl.on_server then
						self:Send().RemoveProfile(name, function(err)
							if err then
								self:Popup(tr(err))
							else
								self:Popup(tr"profile_remoded_success")
							end
						end)
					else
						PxlCashRegister.Profile.RemoveProfile(name)
						self:Popup(tr"profile_remoded_success")
					end
				else
					self:RemoveProfile()
				end
			end}
		}
	end)
end


UScreen:RegisterWindow(Inventory)
