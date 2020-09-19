--[[----------------------------------------------------------
	User Screen
------------------------------------------------------------]]

	PxlCashRegister.UserScreen = PxlCashRegister.NewClass("UScreen", "Screen")
	local UScreen = PxlCashRegister.UserScreen
	UScreen:InitNet("CashRegister_UserScreen")
	UScreen.Windows	= UScreen.Windows	or {}
	UScreen.Options	= UScreen.Options	or {}
	UScreen.Logs	= UScreen.Logs		or {}
	UScreen.Deposit	= UScreen.Deposit	or {}

	local tr = PxlCashRegister.Language.GetDictionary("main")


--[[----------------------------------------------------------
	Object
------------------------------------------------------------]]

	--[[----------------------------------------------------------
	-	General													]]

		function UScreen:Construct(ent, id, pos, ang, wide, height)
			self.__parent.Construct(self, ent, pos, ang, wide, height, 800)
			self:SetID(id)

			self.items = {}
			self.popups = {}
			self.connected = false

			-- for name, func in pairs(UScreen.Windows) do
			-- 	local win = self:AddWindow(name)
			-- end

			self:InitPanel()

			self:Show("Login")


			-- self:Panel().Paint = function(s, w, h)
			-- 	surface.SetDrawColor(Color(255, 255, 255))
			-- 	surface.SetMaterial(Material("pxl/vgui/cash_register_backgroud.png"))
			-- 	surface.DrawTexturedRect(0, 0, w, h)
			-- end

			return self
		end

		-- hook.Add("Think", "CashRegister_UScreen", function()
		-- 	for _, screen in pairs(UScreen:GetAll()) do
		-- 		screen:Think()
		-- 	end
		-- end)
		--

		--
		-- function UScreen:Think()
		-- 	-- if self.link_info and self.link_info.status == "linked" then
		-- 	-- 	if IsValid(self.parent) then
		-- 	-- 		if LocalPlayer():GetShootPos():Distance(self.parent:GetPos()) > PxlCashRegister.Config.ScreenRange + 10 then
		-- 	-- 			self:Unlink()
		-- 	-- 		end
		-- 	--
		-- 	-- 		local x, y = input.GetCursorPos()
		-- 	--
		-- 	-- 		local margin = 2
		-- 	--
		-- 	-- 		if x < margin or x > ScrW() - margin or y < margin or y > ScrH() - margin then
		-- 	-- 			if not unlink_delay then
		-- 	-- 				unlink_delay = CurTime()
		-- 	-- 			end
		-- 	--
		-- 	-- 			if CurTime() - unlink_delay > 0.2 then
		-- 	-- 				self:Unlink()
		-- 	-- 			end
		-- 	-- 		else
		-- 	-- 			unlink_delay = nil
		-- 	-- 		end
		-- 	-- 	else
		-- 	-- 	 	self:Unlink()
		-- 	-- 	end
		-- 	-- end
		-- end



		function UScreen:StolePopup()
			self.stolepopup = self:Popup(tr"has_been_stole",
				{tr"ok", function()
					self:Send().StoleOk()
					return true
				end})
		end

		function UScreen:CloseStolePopup()
			self:RemovePopup(self.stolepopup)
			self.stolepopup = nil
		end

		function UScreen:Notify(...)
			notification.AddLegacy(tr(...), 0, 5)
		end

	--[[----------------------------------------------------------
	-	Main													]]

		function UScreen:Connect(info)
			assert(not self.connected, "Error, Trying to connect wer is already connected")
			info = util.JSONToTable(info)

			self.connected = true

			self:Show("Main")

			if info.hasbeenstole then
				self:StolePopup()
			end

			if info.iswaitingtoprintreceipt then
				self:AskToPrintReceipt()
			end

			if info.isfindingscanner then
				self:FindScanner()
			end

			if info.intransaction then
				self:StartTransaction()
			end

			self.playerisowner = info.isowner
			self.playerisadmin = info.isadmin

			if cookie.GetNumber("PxlCashRegister.HideHelp") ~= 1 and not self.notfirst then
				self.notfirst = true

				self:Popup(tr"new_help",
				{tr"show_help", function()
					self:Show("More")
					self:ActiveWindow():Show("help")
				end},
				{tr"dont_show_again", function()
					cookie.Set("PxlCashRegister.HideHelp", 1)
				end},
				{tr"close"})
			end
		end

		function UScreen:Disconnect()
			self:ClearPopup()
			-- self:StopFindingScanner()

			self.connected = false

			self:ClearWindows()
			self:Show("Login")

			self:Unlink()
		end

		function UScreen:StartTransaction()
			self.transaction_popup = self:Popup(tr"waiting_transaction",
			{tr"cancel", function()
				self:Send().StopTransaction()
				self.transaction_popup = nil
			end})
		end

		function UScreen:StopTransaction()
			if self.transaction_popup then
				self:RemovePopup(self.transaction_popup)
				self.transaction_popup = nil
			end
		end

		function UScreen:AskToPrintReceipt()
			self.printreceipt = self:Popup(tr"would_you_print_the_receipt",
				{tr"no",
				function()
					self:Send().ReplyToPrintReceipt(false)
					return true
				end},
				{tr"yes",
				function()
					self:Send().ReplyToPrintReceipt(true)
					return true
				end})
		end

		function UScreen:FindScanner()
			self.findmenu_popup = self:CustomPopup(tr"add_scanner", function(panel, box)
				box:DockPadding(10, 10, 10, 8)
				panel:SetWide(260)
				panel:CenterVertical(0.12)
				panel:CenterHorizontal()

				local description_label = self:CreateVGUI("DLabel", box, "Label")
				description_label:SetAutoStretchVertical(true)
				description_label:SetWrap(true)
				description_label:SetText(tr"info.adding_scanner")
				description_label:Dock(TOP)
				description_label:DockMargin(5, 0, 5, 10)

				local qccode = self:CreateVGUI("DPanel", box, "QRCode")
				qccode:Dock(TOP)
				qccode:SetTall(240)
				qccode.Paint = function(self, x, y)
					draw.RoundedBox(4, 0, 0, x, y, Color(255, 255, 255))

					local margin = 10
					surface.SetDrawColor(Color(255, 255, 255))
					surface.SetMaterial(Material("pxl/vgui/qr_code.png"))
					surface.DrawTexturedRect(margin, margin, x - margin*2, x - margin*2)
				end

				return {
					{tr"cancel", function()
						self:Send().EmitSound()
						self:Send().StopFindingScanner()

						return true
					end}
				}
			end)

			self:Unlink()
		end

		function UScreen:StopFindingScanner()
			self:RemovePopup(self.findmenu_popup)
		end




		function UScreen:CloseReceiptPopup()
			self:RemovePopup(self.printreceipt)
		end
