local UScreen = PxlCashRegister.UserScreen
local tr = PxlCashRegister.Language.GetDictionary("main")

local Money = PxlCashRegister.NewClass("UScreen.Money", "Window")

Money.name = "Money"

function Money:Build(window, panel)
	local buttons_panel = self:CreateVGUI("DPanel", panel, "SidePanel")

	local player_list = self:CreateVGUI("DScrollPanel", panel, "ColumnList")
	self.player_list = player_list

	local title_label = self:CreateVGUI("DLabel", buttons_panel, "PageTitle")
	title_label:SetText(tr"money")

	local description_label = self:CreateVGUI("DLabel", buttons_panel, "PageDescription")
	description_label:SetText(tr"info.money")

	self:CreateVGUI("DPanel", buttons_panel, "Separator")

	local credit_backgroud = self:CreateVGUI("DPanel", buttons_panel, "PanelIn")
	credit_backgroud:Dock(TOP)
	credit_backgroud:SetTall(55)
	credit_backgroud:DockMargin(10, 5, 10, 0)
	credit_backgroud:SetTooltip(tr"info.credit", true)

	local credit_label = self:CreateVGUI("DLabel", credit_backgroud, "Label")
	credit_label:SetFont("Cash_Register_Price")
	credit_label:Dock(TOP)
	credit_label:DockMargin(5, 5, 5, 0)
	credit_label:SetText(tr"credit")

	local credit_amont = self:CreateVGUI("DLabel", credit_backgroud, "Label")
	credit_amont:SetFont("Cash_Register_Price")
	credit_amont:Dock(TOP)
	credit_amont:DockMargin(5, 5, 5, 5)
	credit_amont:SetText(tr("$", 0))
	self.credit_amont = credit_amont

	local cash_backgroud = self:CreateVGUI("DPanel", buttons_panel, "PanelIn")
	cash_backgroud:Dock(TOP)
	cash_backgroud:SetTall(55)
	cash_backgroud:DockMargin(10, 5, 10, 5)
	cash_backgroud:SetTooltip(tr"info.cash", true)

	local cash_label = self:CreateVGUI("DLabel", cash_backgroud, "Label")
	cash_label:SetFont("Cash_Register_Price")
	cash_label:Dock(TOP)
	cash_label:DockMargin(5, 5, 5, 0)
	cash_label:SetText(tr"cash")

	local cash_amont = self:CreateVGUI("DLabel", cash_backgroud, "Label")
	cash_amont:SetFont("Cash_Register_Price")
	cash_amont:Dock(TOP)
	cash_amont:DockMargin(5, 5, 5, 5)
	cash_amont:SetText(tr("$", 0))
	self.cash_amont = cash_amont

	self:CreateVGUI("DPanel", buttons_panel, "Separator")

	local take_button = self:CreateVGUI("DButton", buttons_panel, "MenuButton", "pxl/vgui/arrow_up.png")
	take_button:SetText(tr"take_money")
	take_button:SetTooltip(tr"info.take_money")
	take_button.DoClick = function()
		local ply = LocalPlayer()
		self:Send().EmitSound()
		self:AskMoneyToGive(ply:Name(), ply:UniqueID(), "Cash")
	end

	local deposit_button = self:CreateVGUI("DButton", buttons_panel, "MenuButton", "pxl/vgui/arrow_down.png")
	deposit_button:SetText(tr"deposit_money")
	deposit_button:SetTooltip(tr"info.deposit_money")
	deposit_button.DoClick = function()
		self:Send().EmitSound()

		if not self.Deposits then
			self:Popup(tr"deposit_not_load_yet")
		else
			local depositmod = {}

			for mod, info in pairs(self.Deposits) do
				table.insert(depositmod, {tr(info.Name), function()
					if PxlCashRegister.Modules.Deposit[mod] then
						PxlCashRegister.Modules.Deposit[mod](self, info, function(err, more)
							if err then
								if isstring(err) then
									self:Message(err)
								end
							else
								self:AskMoneyToDeposit(mod, info)
							end
						end)
					else
						self:AskMoneyToDeposit(mod)
					end
				end})
			end

			if #depositmod > 0 then
				table.insert(depositmod, "_")
				table.insert(depositmod, {tr"close"})
				table.insert(depositmod, false)

				self:Popup(tr"chose_depositmod", unpack(depositmod))
			else
				self:Popup(tr"no_depositmod")
			end
		end
	end

	self:CreateVGUI("DPanel", buttons_panel, "Separator")

	local back_button = self:CreateVGUI("DButton", buttons_panel, "MenuButton", "pxl/vgui/arrow_left.png")
	back_button:SetText(tr"back")
	back_button.DoClick = function()
		self:Send().EmitSound()
		self:Screen():Show("Main")
	end
end

function Money:Open()
	self:Send().NeededInfo("money")
	self:Send().GetMoneyInfo()
end

function Money:Clear()
	self.player_list:Clear()
end

function Money:SetMoney(cash, credit)
	self.cash_amont:SetText(tr("$", cash))
	self.credit_amont:SetText(tr("$", credit))

	self.cash = cash
	self.credit = credit
end

function Money:AskMoneyToGive(name, uid, mod)
	local moneytype = self.Transfers[mod].Type
	local cash = self[moneytype]

	self:CustomPopup(function(panel, box)
		if cash > 0 then
			local slider = self:CreateVGUI("DNumSlider", box, "Slider")
			slider:Dock(TOP)
			slider:DockMargin(0, 0, 0, 0)
			slider:SetText(tr"money")
			slider:SetMin(0)
			slider:SetMax(cash)
			slider:SetDecimals(0)

			return {
				{tr"close"},
				{tr(LocalPlayer():UniqueID() == uid and "get" or "pay"), function()
					self:Send().SendMoney(uid, math.Round(slider:GetValue(), 2), mod)
				end}
			}
		else
			local label = self:CreateVGUI("DLabel", box, "Label")
			label:SetAutoStretchVertical(true)
			label:SetWrap(true)
			label:SetText(tr"no_money")
			label:Dock(TOP)
			label:DockMargin(0, 0, 0, 0)
		end
	end)
end

function Money:AskMoneyToDeposit(mod, more)
	self:CustomPopup(function(panel, box)
		local cost_label = self:CreateVGUI("DLabel", box, "Label")
		cost_label:Dock(TOP)
		cost_label:DockMargin(0, 0, 0, 2)
		cost_label:SetText(tr"amount")

		local amount_entry = self:CreateVGUI("DTextEntry", box, "TextEntry")
		amount_entry:Dock(TOP)
		amount_entry:DockMargin(0, 0, 0, 10)
		amount_entry:SetText("")
		amount_entry:SetNumeric(true)

		return {
			{tr"close"},
			{tr"deposit", function()
				self:Send().DepositMoney(tonumber(amount_entry:GetValue()), mod, more)
			end}
		}
	end)
end

function Money:UpdateMoney(cash, credit)
	if not self:IsVisible() then return end

	self:SetMoney(cash, credit)
end

function Money:SendMoneyInfo(data)
	local info = util.JSONToTable(data)

	self:Clear()

	self:SetMoney(info.cash, info.credit)

	self.Transfers = info.transfers
	self.Deposits = info.deposits

	for _, ply in pairs(info.players) do
		local column = self:CreateVGUI("DPanel", self.player_list, "Column")

		local pay_button = self:CreateVGUI("DButton", column, "ColumnPayButton")
		pay_button:Dock(RIGHT)
		pay_button:SetTooltip(tr("info.transfer_credit_to", ply.name))

		pay_button.DoClick = function()
			self:Send().EmitSound()

			local transmods = {}
			for mod, info in pairs(self.Transfers) do
				if info.Type == "credit" then
					table.insert(transmods, {tr(info.Name), function() self:AskMoneyToGive(ply.name, ply.uid, mod) end})
				end
			end

			if #transmods > 0 then
				table.insert(transmods, "_")
				table.insert(transmods, {tr"close"})
				table.insert(transmods, false)

				self:Popup(tr"chose_transmod", unpack(transmods))
			else
				self:Popup(tr"no_transmod")
			end
		end

		local name_label = self:CreateVGUI("DLabel", column, "ColumnLabel")
		name_label:SetText(ply.name)
	end
end


UScreen:RegisterWindow(Money)
