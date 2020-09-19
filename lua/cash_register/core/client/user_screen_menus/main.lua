local UScreen = PxlCashRegister.UserScreen
local tr = PxlCashRegister.Language.GetDictionary("main")

local Main = PxlCashRegister.NewClass("UScreen.Main", "Window")

Main.name = "Main"

function Main:Build(screen, panel)
	self.items = {}
	self.items_group = {}

	local side_menu = self:CreateVGUI("DPanel", panel, "SidePanel")
	local items_list = self:CreateVGUI("DScrollPanel", panel, "ColumnList", tr"info.no_item_in_cart") -- Panel
	self.items_list = items_list

	local title_price_label = self:CreateVGUI("DLabel", side_menu, "PageTitle")
	title_price_label:SetText(tr"total_price")


	local price_backgroud = self:CreateVGUI("DPanel", side_menu, "Main_PriceBackground") -- PanelIn

	local price_label = self:CreateVGUI("DLabel", price_backgroud, "Main_PriceLabel") -- Price
	price_label:SetText(tr("$", 0))
	self.price_label = price_label


	self:CreateVGUI("DPanel", side_menu, "Separator")

	-- local buttons_panel = self:CreateVGUI("DPanel", panel, "SidePanelBot") -- Panel
	-- buttons_panel:Dock(FILL)

	function addbutton(parent, tall, label, doclick, icon, description)
		local but = self:CreateVGUI("DButton", parent, "MenuButton", icon, description)
		but:SetText(tr(label))
		but:SetTooltip(description)
		but.DoClick = function()
			self:Send().EmitSound()
			doclick()
		end

		return but
	end


	addbutton(side_menu, 40, "accept", function()
		self:Send().StartTransaction()
	end, "pxl/vgui/arrow_right.png", tr"info.accept_transaction")

	addbutton(side_menu, 40, "add_service", function()
		self:AddService()
	end, "pxl/vgui/add.png", tr"info.add_service") --"Add a service to the shopping cart.")

	addbutton(side_menu, 40, "clear", function()
		if table.Count(self.items) == 0 then
			self:PopupTitle(tr"warning", tr"warning.no_item_in_cart_to_clear")
			return
		end

		self:PopupTitle(tr"confirmation", tr"sure_to_clear",
		{tr"cancel"},
		{tr"clear", function()
			self:Send().ClearItems()
		end})
	end, "pxl/vgui/refresh.png", tr"info.clear_cart") --"Clear all items of the shopping cart.")

	self:CreateVGUI("DPanel", side_menu, "Separator")

	addbutton(side_menu, 40, "items_list", function()
		screen:Show("Inventory")
	end, nil, tr"info.inventory")

	addbutton(side_menu, 40, "money", function()
		screen:Show("Money")
	end, nil, tr"info.money")

	addbutton(side_menu, 40, "option", function()
		screen:Show("Option")
	end, nil, tr"info.option")

	addbutton(side_menu, 40, "more", function()
		screen:Show("More")
	end, nil, tr"info.more")

	self:CreateVGUI("DPanel", side_menu, "Separator")

	addbutton(side_menu, 40, "disconnect", function()
		self:Send().Disconnect()
	end)
end


function Main:Open()
	self:Send().NeededInfo("items")
	self:Send().GetItems()
end

function Main:Close()
	self:ClearItems()
end


function Main:AddItem(itm)
	if self.items_group[itm.groupid] then
		local group = self.items_group[itm.groupid]

		group.quantity = group.quantity + 1
		group.items[itm.id] = itm

		group.column.quantity_label:SetText(tr("%d x", group.quantity))
		group.column.quantity_label:SetVisible(true)

		surface.SetFont("Cash_Register_Title")
		group.column.quantity_label:SetWide(surface.GetTextSize(group.column.quantity_label:GetText()))

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
				for id, itm in pairs(itm.group.items) do
					self:Send().RemoveItem(id)
					break
				end
			else
				self:Send().RemoveItem(itm.id)
			end
		end

		local quantity_label = self:CreateVGUI("DLabel", column, "Label")
		quantity_label:Dock(LEFT)
		quantity_label:DockMargin(0, 10, 10, 7)
		quantity_label:SetContentAlignment(7)
		quantity_label:SetFont("Cash_Register_Title")
		quantity_label:SizeToContents(true)
		quantity_label:SetVisible(false)
		column.quantity_label = quantity_label

		local text_box = self:CreateVGUI("DPanel", column, "None")
		text_box:Dock(FILL)
		text_box:DockMargin(0, 7, 0, 7)

		local name_label = self:CreateVGUI("DLabel", text_box, "Label")
		name_label:SetText(itm.name)
		name_label:Dock(TOP)

		local price_label = self:CreateVGUI("DLabel", text_box, "Label")
		price_label:SetText(tr("$", itm.cost))
		price_label:SizeToContents()
		price_label:Dock(TOP)
		price_label:DockMargin(0, 3, 0, 0)

		itm.column = column

		if itm.groupid then
			self.items_group[itm.groupid] = {
				id = itm.groupid,
				column = column,
				quantity = 1,
				items = {[itm.id] = itm}
			}

			itm.group = self.items_group[itm.groupid]
		end
	end
		
	self.items[itm.id] = itm
	self:CalcCost()
end


function Main:RemoveItem(id)
	local itm = self.items[id]

	if itm.group then
		local group = itm.group

		if group.quantity > 1 then
			group.quantity = group.quantity - 1
			group.items[id] = nil
			
			group.column.quantity_label:SetText(tr("%d x", group.quantity))

			surface.SetFont("Cash_Register_Title")
			group.column.quantity_label:SetWide(surface.GetTextSize(group.column.quantity_label:GetText()))



			if group.quantity == 1 then
				group.column.quantity_label:SetVisible(false)
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
	self:CalcCost()
end

function Main:SendItems(info)
	self:ClearItems()

	for _, itm in pairs(info) do
		self:AddItem(itm)
	end
end

function Main:ClearItems()
	for id, itm in pairs(self.items) do
		itm.column:Remove()
	end

	self.items = {}
	self.items_group = {}

	self:CalcCost()
end

function Main:CalcCost()
	local cost = 0

	for _, itm in pairs(self.items) do
		cost = cost + itm.cost
	end

	self.price_label:SetText(tr("$", cost))
end


function Main:AddService()
	self:CustomPopup(tr"add_service", function(panel, box)
		local description_label = self:CreateVGUI("DLabel", box, "Label")
		description_label:SetAutoStretchVertical(true)
		description_label:SetWrap(true)
		description_label:SetText(tr"info.add_service")
		description_label:Dock(TOP)
		description_label:DockMargin(0, 0, 0, 10)

		self:CreateVGUI("DPanel", box, "SeparatorIn"):DockMargin(0, 0, 0, 10)

		local name_label = self:CreateVGUI("DLabel", box, "Label")
		name_label:Dock(TOP)
		name_label:DockMargin(0, 0, 0, 2)
		name_label:SetText(tr"description")

		local name_entry = self:CreateVGUI("DTextEntry", box, "TextEntry")
		name_entry:Dock(TOP)
		name_entry:DockMargin(0, 0, 0, 10)
		name_entry:SetText("")
		name_entry:SetFont("Cash_Register_Basic")

		local price_label = self:CreateVGUI("DLabel", box, "Label")
		price_label:Dock(TOP)
		price_label:DockMargin(0, 0, 0, 2)
		price_label:SetText(tr"cost")

		local price_entry = self:CreateVGUI("DTextEntry", box, "TextEntry")
		price_entry:Dock(TOP)
		price_entry:DockMargin(0, 0, 0, 10)
		price_entry:SetText("")
		price_entry:SetNumeric(true)
		price_entry:SetFont("Cash_Register_Basic")

		return {
			{tr"close"},
			{tr"add", function()
				self:Send().AddService(name_entry:GetValue(), tonumber(price_entry:GetValue()))
			end}
		}
	end)
end




UScreen:RegisterWindow(Main)
