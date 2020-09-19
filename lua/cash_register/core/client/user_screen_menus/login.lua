local UScreen = PxlCashRegister.UserScreen
local tr = PxlCashRegister.Language.GetDictionary("main")

local Login = PxlCashRegister.NewClass("UScreen.Login", "Window")

-- UScreen:RegisterWindows(self, win, pnl)

Login.name = "Login"

function Login:Build(screen, panel)
	screen:ApplyTheme(screen:Panel(), "ScreenBackground")
	-- ## The default midle menu when it's not for rent



	local container = self:CreateVGUI("DSizeToContents", panel, "PopupPanel")
	container:SetSizeX(false)
	container:InvalidateLayout()

	container:CenterHorizontal()
	container:CenterVertical(0.2)


	local title_label = self:CreateVGUI("DLabel", container, "PopupTitleEmpty")
	title_label:SetText("")


	local info_background = self:CreateVGUI("DSizeToContents", container, "PopupPanelIn")
	info_background:Dock(TOP)
	info_background:SetSizeX(false)
	info_background:InvalidateLayout()

	local info_machine_title = self:CreateVGUI("DLabel", info_background, "Label")
	info_machine_title:Dock(TOP)
	info_machine_title:DockMargin(0, 0, 0, 2)
	info_machine_title:SetText(tr("machine_title"))
	info_machine_title:SetFont("Cash_Register_Price")

	local info_machine_label = self:CreateVGUI("DLabel", info_background, "Label")
	info_machine_label:Dock(TOP)
	info_machine_label:DockMargin(10, 0, 0, 10)
	info_machine_label:SetText(tr("machine_label", 0, "unknown"))
	self.info_machine_label = info_machine_label

	local info_owner_title = self:CreateVGUI("DLabel", info_background, "Label")
	info_owner_title:Dock(TOP)
	info_owner_title:DockMargin(0, 0, 0, 2)
	info_owner_title:SetText(tr("owner_title"))
	info_owner_title:SetFont("Cash_Register_Price")

	local info_owner_label = self:CreateVGUI("DLabel", info_background, "Label")
	info_owner_label:Dock(TOP)
	info_owner_label:DockMargin(10, 0, 0, 0)
	info_owner_label:SetText(tr("%s", "unknown"))
	self.info_owner_label = info_owner_label


	local connect_background = self:CreateVGUI("DSizeToContents", container, "None")
	connect_background:Dock(TOP)
	connect_background:SetSizeX(false)
	connect_background:InvalidateLayout()
	connect_background:SetVisible(false)
	self.connect_background = connect_background

	self:CreateVGUI("DPanel", connect_background, "SeparatorIn")

	local connect_button = self:CreateVGUI("DButton", connect_background, "PopupButton")
	connect_button:SetText(tr"connect")
	connect_button.DoClick = function()
		self:Send().EmitSound()
		self:Send().Connect()
	end


	-- ## The midle menu to rent

	local rent_background = self:CreateVGUI("DSizeToContents", container, "None")
	rent_background:Dock(TOP)
	rent_background:SetSizeX(false)
	rent_background:InvalidateLayout()
	rent_background:SetVisible(false)
	self.rent_background = rent_background

	self:CreateVGUI("DPanel", rent_background, "SeparatorIn")

	local rent_button = self:CreateVGUI("DButton", rent_background, "PopupButton")
	rent_button:SetText(tr"rent")
	rent_button.DoClick = function()
		self:Send().EmitSound()
		self:Send().GetRentingInfo()
	end


	-- ## The midle menu to connect or sell when it's rented

	local sell_background = self:CreateVGUI("DSizeToContents", container, "None")
	sell_background:Dock(TOP)
	sell_background:SetSizeX(false)
	sell_background:InvalidateLayout()
	sell_background:SetVisible(false)
	self.sell_background = sell_background

	self:CreateVGUI("DPanel", sell_background, "SeparatorIn")

	local sell_connect_button = self:CreateVGUI("DButton", sell_background, "PopupButton")
	sell_connect_button:SetText(tr"connect")
	sell_connect_button.DoClick = function()
		self:Send().EmitSound()
		self:Send().Connect()
	end

	local selling_price = 0
	local sell_button = self:CreateVGUI("DButton", sell_background, "PopupButton")
	sell_button:SetText(tr"sell")
	sell_button.DoClick = function()
		self:Send().EmitSound()
		self:Send().GetSellingInfo()
	end


	-- ## Button down for the rental option

	local rent_option_background = self:CreateVGUI("DSizeToContents", container, "None")
	rent_option_background:Dock(TOP)
	rent_option_background:SetSizeX(false)
	rent_option_background:InvalidateLayout()
	rent_option_background:SetVisible(false)
	self.rent_option_background = rent_option_background

	self:CreateVGUI("DPanel", rent_option_background, "SeparatorIn")

	local rent_option_button = self:CreateVGUI("DButton", rent_option_background, "PopupButton")
	rent_option_button:SetText(tr"rent_option")
	rent_option_button.DoClick = function()
		self:Send().EmitSound()
		self:OpenRentSetting()
	end
end

function Login:Open()
	self:Send().NeededInfo("connect")
	self:Send().GetConnectInfo()
end

function Login:GetConnectInfo(info)
	if not self:IsVisible() then return end

	self.rent_option_background:SetVisible(info.isadmin)

	self.info_machine_label:SetText(tr("machine_label", info.cash_register_id, info.server_name))
	self.info_owner_label:SetText(tr("%s", info.owner_name))

	if info.forrenting then
		self.connect_background:SetVisible(false)
		self.rent_background:SetVisible(true)
		self.sell_background:SetVisible(false)
	elseif info.cansell then
		self.connect_background:SetVisible(false)
		self.rent_background:SetVisible(false)
		self.sell_background:SetVisible(true)
	else
		self.connect_background:SetVisible(true)
		self.rent_background:SetVisible(false)
		self.sell_background:SetVisible(false)
	end
end

function Login:GetSellingInfo(data)
	local info = util.JSONToTable(data)

	local function confirmation(mod, more)
		self:Popup(tr("selling_confirmation", info.cost, mod),
		{tr"cancel"},
		{tr"sell", function() self:Send().Sell(mod, more) end})
	end

	local function showpayments()
		local payments = {}
		for mod, info in pairs(info.payments) do
			table.insert(payments, {tr(info.Name), function()
				if PxlCashRegister.Modules.Deposit[mod] then
					PxlCashRegister.Modules.Deposit[mod](self:Screen(), info, function(more)
						confirmation(mod, more)
					end)
				else
					confirmation(mod)
				end
			end})
		end

		if info.isadmin then
			table.insert(payments, {tr"has_admin", function()
				self:Send().Sell("admin")
			end})
		end

		if #payments > 0 then
			table.insert(payments, {tr"close"})
			table.insert(payments, "_")
			table.insert(payments, false)

			self:Popup(tr"choose_payment_for_selling", unpack(payments))
		else
			self:Popup(tr"no_payment_method")
		end
	end

	if info.mod then
		if info.money then
			self:Popup(tr"there_have_money",
			{tr"cancel"},
			{tr"continue", function()
				confirmation(info.mod)
			end})
		else
			confirmation(info.mod)
		end
	else
		if info.money then
			self:Popup(tr"there_have_money",
			{tr"cancel"},
			{tr"continue", showpayments})
		else
			showpayments()
		end
	end
end

function Login:OpenRentSetting()
	self:Screen():Send().GetRentInfo(function(data)
		local info = util.JSONToTable(data)
		if not info then return end

		self:CustomPopup(tr"rent_option", function(panel, box)
			panel:SetWide(300)
			panel:CenterHorizontal()
			panel:CenterVertical(0.1)

			local server_edit_background = self:CreateVGUI("DPanel", box, "None")
			server_edit_background:Dock(TOP)
			server_edit_background:DockMargin(0, 0, 0, 10)
			server_edit_background:SetTall(44)

			local server_edit_checkbox = self:CreateVGUI("DCheckBox", server_edit_background, "CheckBox")
			server_edit_checkbox:Dock(LEFT)
			server_edit_checkbox:DockMargin(0, 5, 10, 5)
			server_edit_checkbox:SetWide(20)
			server_edit_checkbox.OnChange = function(cb, val)
			end

			local server_edit_label = self:CreateVGUI("DLabel", server_edit_background, "Label")
			server_edit_label:SetText(tr"can_edit_server")
			server_edit_label:Dock(FILL)
			server_edit_label:DockMargin(0, 5, 0, 5)
			server_edit_label.DoClick = function() server_edit_checkbox:Toggle() end
			server_edit_label:SetWrap(true)
			server_edit_label:SetAutoStretchVertical(true)

			local accessory_edit_background = self:CreateVGUI("DPanel", box, "None")
			accessory_edit_background:Dock(TOP)
			accessory_edit_background:DockMargin(0, 0, 0, 10)
			accessory_edit_background:SetTall(44)

			local accessory_edit_checkbox = self:CreateVGUI("DCheckBox", accessory_edit_background, "CheckBox")
			accessory_edit_checkbox:Dock(LEFT)
			accessory_edit_checkbox:DockMargin(0, 5, 10, 5)
			accessory_edit_checkbox:SetWide(20)
			accessory_edit_checkbox.OnChange = function(cb, val)
			end

			local accessory_edit_label = self:CreateVGUI("DLabel", accessory_edit_background, "Label")
			accessory_edit_label:SetText(tr"can_edit_accessory")
			accessory_edit_label:Dock(FILL)
			accessory_edit_label:DockMargin(0, 5, 0, 5)
			accessory_edit_label.DoClick = function() accessory_edit_checkbox:Toggle() end
			accessory_edit_label:SetWrap(true)

			local rent_background = self:CreateVGUI("DPanel", box, "None")
			rent_background:SetTall(30)
			rent_background:Dock(TOP)
			rent_background:DockMargin(0, 0, 0, 10)

			local rent_entry = self:CreateVGUI("DTextEntry", rent_background, "TextEntry")
			rent_entry:Dock(RIGHT)
			rent_entry:DockMargin(5, 5, 0, 5)
			rent_entry:SetWide(100)
			rent_entry:SetText("0")
			rent_entry:SetNumeric(true)

			local rent_label = self:CreateVGUI("DLabel", rent_background, "Label")
			rent_label:SetText(tr"rent_cost")
			rent_label:Dock(FILL)
			rent_label:DockMargin(0, 5, 5, 5)

			local sell_background = self:CreateVGUI("DPanel", box, "None")
			sell_background:SetTall(30)
			sell_background:Dock(TOP)
			sell_background:DockMargin(0, 0, 0, 10)

			local sell_entry = self:CreateVGUI("DTextEntry", sell_background, "TextEntry")
			sell_entry:Dock(RIGHT)
			sell_entry:DockMargin(5, 5, 0, 5)
			sell_entry:SetWide(100)
			sell_entry:SetText("0")
			sell_entry:SetNumeric(true)

			local sell_label = self:CreateVGUI("DLabel", sell_background, "Label")
			sell_label:SetText(tr"sell_cost")
			sell_label:Dock(FILL)
			sell_label:DockMargin(0, 5, 0, 5)


			server_edit_checkbox:SetChecked(info.server)
			accessory_edit_checkbox:SetChecked(info.accessory)
			rent_entry:SetText(info.rend)
			sell_entry:SetText(info.sell)


			if not info.ispersist then
				return {
					{tr"make_persist", function()
						self:Send().EmitSound()
						self:Send().MakePersist(server_edit_checkbox:GetChecked(), accessory_edit_checkbox:GetChecked(), tonumber(rent_entry:GetText()), tonumber(sell_entry:GetText()),function(enabled)
							box:SetIsPersist(enabled)
						end)
					end},
					"_",
					{tr"close", function()
						self:Send().EmitSound()
					end}
				}
			else
				return {
					{tr"save_setting", function()
						self:Send().EmitSound()
						self:Send().SaveSettingPersist(server_edit_checkbox:GetChecked(), accessory_edit_checkbox:GetChecked(), tonumber(rent_entry:GetText()), tonumber(sell_entry:GetText()))
					end},
					{tr"save_setup", function()
						self:Send().EmitSound()
						self:Send().SaveSetupPersist()
					end},
					{tr"reload", function()
						self:Send().EmitSound()
						self:Send().ReloadPersist()
					end},
					{tr"remove", function()
						self:Send().EmitSound()

						self:Popup(tr"remove_server_confirmation",
						{tr"cancel"},
						{tr"remove",function()
							self:Send().RemovePersist()
						end})
					end},
					"_",
					{tr"close", function()
						self:Send().EmitSound()
					end}
				}
			end
		end)
	end)
end

function Login:GetRentingInfo(data)
	local info = util.JSONToTable(data)

	local function confirmation(mod, more)
		self:Popup(tr("renting_confirmation", info.cost, mod),
		{tr"cancel"},
		{tr"rent", function() self:Send().Rent(mod, more) end})
	end

	local payments = {}
	for mod, info in pairs(info.payments) do
		table.insert(payments, {tr(info.Name), function()
			if PxlCashRegister.Modules.Deposit[mod] then
				PxlCashRegister.Modules.Deposit[mod](self:Screen(), info, function(more)
					confirmation(mod, more)
				end)
			else
				confirmation(mod)
			end
		end})
	end

	if info.isadmin then
		table.insert(payments, {tr"has_admin", function()
			self:Send().Rent("admin")
		end})
	end

	if #payments > 0 then
		table.insert(payments, "_")
		table.insert(payments, {tr"close"})
		table.insert(payments, false)

		self:PopupTitle(tr"rent_choose_method", tr"choose_payment_for_renting", unpack(payments))
	else
		self:Popup(tr"no_payment_method")
	end
end


function Login:AskForInvitation()
	self:Popup(tr"invitation_message",
	{tr"no",
	function()
		self:Send().AnswerForInvitation(false)
	end},
	{tr"yes",
	function()
		self:Send().AnswerForInvitation(true)
	end})
end


UScreen:RegisterWindow(Login)
