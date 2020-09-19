local CScreen = PxlCashRegister.CustomerScreen
local tr = PxlCashRegister.Language.GetDictionary("main")

local Preview = PxlCashRegister.NewClass("CScreen.Preview", "Window")

Preview.name = "Preview"

function Preview:Build(screen, panel)
	self:ApplyTheme(screen:Panel(), "ScreenBackground")

	local back = self:CreateVGUI("DPanel", panel, "CustomerBack")
	back:DockMargin(10, 10, 10, 10)
	back:Dock(FILL)



	local market_label = self:CreateVGUI("DLabel", back, "Main_PriceLabel") -- Price
	market_label:SetText("Market")
	market_label:SetFont("Cash_Register_Customer_Price")
	market_label:Dock(TOP)
	market_label:DockMargin(15, 12, 15, 5)
	market_label:SetTall(28)
	self.market_label = market_label

	local top_div = self:CreateVGUI("DPanel", back, "None")
	top_div:SetTall(45)
	top_div:DockMargin(5, 0, 5, 5)
	top_div:Dock(BOTTOM)

	local purchase_button = self:CreateVGUI("DButton", top_div, "Button")
	purchase_button:Dock(LEFT)
	purchase_button:DockMargin(0, 0, 5, 0)
	purchase_button:SetWide(120)
	purchase_button:SetText(tr"buy")
	purchase_button:SetFont("Cash_Register_Customer_Price")
	purchase_button:SetDisabled(true)
	purchase_button.DoClick = function()
		self:Send().GetPurchaseInfo()
		self:Send().EmitSound()
	end
	self.purchase_button = purchase_button

	local price_background = self:CreateVGUI("DPanel", top_div, "PanelIn")
	price_background:Dock(FILL)
	price_background:DockMargin(0, 0, 0, 0)
	self.price_background = price_background

	local price_label = self:CreateVGUI("DLabel", price_background, "Main_PriceLabel") -- Price
	price_label:SetText(tr("$", 0))
	price_label:SetFont("Cash_Register_Customer_Price")
	price_label:Dock(FILL)
	price_label:SetContentAlignment(6)
	self.price_label = price_label


	local items_list = self:CreateVGUI("DScrollPanel", back, "ColumnListIn", tr"info.no_item_in_cart")
	items_list:Dock(FILL)
	items_list:DockMargin(5, 5, 5, 5)
	self.items_list = items_list
end

function Preview:Update(info)
	if not self:IsBuilded() then return end

	self.price_label:SetText(tr("$", info.cost))

	self.items_list:Clear()

	local column

	for i, itm in pairs(info.items) do
		column = self:CreateVGUI("DPanel", self.items_list, "Column")


		local price_label = self:CreateVGUI("DLabel", column, "ColumnPriceLabel")
		price_label:SetText(tr("$", itm.cost))
		price_label:SizeToContents()

		local name_label = self:CreateVGUI("DLabel", column, "ColumnLabel")
		name_label:SetText(i .. ": " ..  itm.name)
	end

	if column then
		timer.Simple(0.05, function()
			self.items_list.VBar:SetScroll( self.items_list.pnlCanvas:GetTall() )
		end)
	end

	self.purchase_button:SetDisabled(not info.is_ready)

	self:Panel():InvalidateChildren(true)

	self.market_label:SetText(info.name)
end

function Preview:PreparePurchase(info)
	local payments = {}

	for mod, payment in pairs(info.payments) do
		table.insert(payments, {
			tr(payment.Name),
			function()
				local function to_payment(info)
					self:PopupTitle(tr"confirmation", tr("confirmation_text", payment.Name),
						{tr"cancel", function()
							self:Send().Quit()
						end},
						{tr"accept", function()
							self:Send().Purchase(mod, payment_info)
						end})
				end


				if isfunction(PxlCashRegister.Modules.Payments[mod]) then
					PxlCashRegister.Modules.Payments[mod](self, payment, function(err, info)
						if err then
							self:Send().Quit()

							if isstring(err) then
								self:PopupTitle(tr"payment_error", tr(err))
							end
						else
							to_payment(info)
						end
					end)
				else
					to_payment()
				end
			end
		})
	end

	table.insert(payments, "_")
	table.insert(payments, {
		tr"close",
		function()
			self:Send().Quit()
		end})

	self:Popup(tr("chose_payment_method_to_buy", info.total), unpack(payments))
end

function Preview:Open()
	self:Send().Listen()
end

function Preview:Close()
	self:Send().StopListening()
end


CScreen:RegisterWindow(Preview)
