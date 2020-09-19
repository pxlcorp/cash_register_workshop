local Screen = PxlCashRegister.Screen
local Config = PxlCashRegister.Config

Screen.AddTheme("New", function(Theme, screen)
	local function pr(percentage)
		return screen.screen_resolution*percentage/100
	end

	local cached_color = setmetatable({}, {__mode = 'v'})

	local function hx(color)
		if cached_color[color] then
			return cached_color[color]
		else
			local rgb

			if #color == 3 then
				rgb = Color(tonumber(color[1] .. "f", 16), tonumber(color[2] .. "f", 16), tonumber(color[3] .. "f", 16))
			elseif #color == 4 then
				rgb = Color(tonumber(color[1] .. "f", 16), tonumber(color[2] .. "f", 16), tonumber(color[3] .. "f", 16), tonumber(color[4] .. "f", 16))
			elseif #color == 6 then
				rgb = Color(tonumber(string.sub(color, 1, 2), 16), tonumber(string.sub(color, 3, 4), 16), tonumber(string.sub(color, 5, 6), 16))
			elseif #color == 8 then
				rgb = Color(tonumber(string.sub(color, 1, 2), 16), tonumber(string.sub(color, 3, 4), 16), tonumber(string.sub(color, 5, 6), 16), tonumber(string.sub(color, 7, 8), 16))
			end

			if istable(rgb) then
				cached_color[color] = rgb
				return rgb
			end
		end
	end

	Theme.AccentHX = Config.ThemeAccentColor
	Theme.Accent = hx(Theme.AccentHX)
	Theme.White = hx(Config.ThemePrimaryColor)
	Theme.BackWhite = hx(Config.ThemeSecondaryColor)

	surface.CreateFont("Cash_Register_Basic", {
		font = "Arial",
		size = 20 ,
		weight = 800,
	})

	surface.CreateFont("Cash_Register_BasicSmall", {
		font = "Arial",
		size = 16 ,
		weight = 800,
	})

	surface.CreateFont("Cash_Register_Menu", {
		font = "Arial",
		size = 17,
		weight = 500,
	})

	surface.CreateFont("Cash_Register_Title", {
		font = "Arial",
		size = 25,
		weight = 800,
	})

	surface.CreateFont("Cash_Register_Price", {
		font = "Arial",
		size = 22,
		weight = 800,
	})

	surface.CreateFont("Cash_Register_Customer_Price", {
		font = "Arial",
		size = 32,
		weight = 800,
	})

	surface.CreateFont("Cash_Register_Button", {
		font = "Arial",
		size = 20,
		weight = 800,
	})

	surface.CreateFont("Cash_Register_Big", {
		font = "Arial",
		size = 28,
		weight = 800,
	})

	function Theme:ScreenBackground(PANEL)
		function PANEL:Paint(w, h)
			surface.SetDrawColor(Color(255, 255, 255))
			surface.SetMaterial(Material("pxl/vgui/background.png"))
			surface.DrawTexturedRect(0, 0, w, h)
		end
	end


	function Theme:TooltipBox(PANEL)
		local tooltip_delay = CreateClientConVar("tooltip_delay", "0.5", true, false)

		function PANEL:Build()
			self:DockPadding(8, 6, 8, 6)

			self.Height = 10
			self.Arrow = {}
			self.reverce = 0
		end

		function PANEL:PositionTooltip()
			if not IsValid(self.TargetPanel) or not isstring(self.TargetPanel.custom_tooltip) then
				self:Close()
				return
			end

			self.Contents:SetText(self.TargetPanel.custom_tooltip or "")

			self:PerformLayout()

			local x, y = input.GetCursorPos()
			local w, h = self:GetSize()

			local lx, ly = self.TargetPanel:LocalToScreen(0, 0)
			local tw, th = self.TargetPanel:GetSize()

			y = y - 50

			y = math.min(y, ly - h * 1.5)
			if y < 2 then y = 2 end

			-- Fixes being able to be drawn off screen
			local sx, sy = screen:Panel():LocalToScreen(0, 0)
			local sw, sh = screen:Panel():GetSize()

			local px, py = math.min(math.max(lx - w/2 + tw/2, sx + 5), sx + sw - w - 5), ly - h
			local aw, ah = math.min(lx - px + tw/2, w - 0), self:GetTall() - self.Height - 1

			self.Arrow = {
				{x = aw - 10, y = ah},
				{x = aw + 10, y = ah},
				{x = aw, y = ah + self.Height},
			}

			if py < sy then
				self.reverce = 1
				py = ly + th
				ah = self.Height + 1

				self.Arrow = {
					{x = aw - 10, y = ah},
					{x = aw, y = ah - self.Height},
					{x = aw + 10, y = ah},
				}

				self:PerformLayout()
			end
			self:SetPos(px, py)
		end

		function PANEL:PerformLayout()
			if IsValid(self.Contents) then
				local pl, pu, pr, pd = self:GetDockPadding()

				surface.SetFont(self.Contents:GetFont())
				local tw, th = surface.GetTextSize(self.Contents:GetText())

				self:SetWide(tw + pl + pr)
				self:SetTall(th + pu + pd + self.Height)

				self.Contents:SetSize(tw, th)
				self.Contents:SetPos(pr, pu + self.Height * self.reverce)
				self.Contents:SetVisible(true)
			end

		end

		function PANEL:Paint(w, h)
			draw.RoundedBox(6, 0, self.Height * self.reverce, w, h - self.Height, hx"5551")
			draw.RoundedBox(4, 1, self.Height * self.reverce+1, w-2, h - self.Height-2, hx"ffff")

			surface.SetDrawColor(hx"ffff")
			draw.NoTexture()
			surface.DrawPoly( self.Arrow )
		end
	end


	function Theme:TooltipLabel(PANEL)
		function PANEL:Build()
			self:DockMargin(100, 100, 100, 100)
		end

		return "Label"
	end

	local tooltip = screen:CreateVGUI("DLabel", nil, "TooltipLabel")
	tooltip:SetVisible(false)

	local meta_panel = FindMetaTable("Panel")
	function tooltip:SetParent(parent)
		meta_panel.SetParent(self, parent)

		if IsValid(parent) then
			screen:ApplyTheme(parent, "TooltipBox")
		end
	end


	-- ###################################
	-- ## Basic Element

	function Theme:MetaPanel(PANEL)


		function PANEL:SetTooltip(text, info_tag)
			self.custom_tooltip = text
			self:SetTooltipPanel(tooltip)

			self.info_tag = info_tag or self.info_tag
		end


		local size = 16
		function PANEL:PaintOver(w, h)
			if self.info_tag then
				surface.SetDrawColor(hx"0003")
				surface.SetMaterial(Material("pxl/vgui/info.png"))
				surface.DrawTexturedRect(w - size - 10, h - size - 10, size, size)
			end
		end
	end


	function Theme:None(PANEL)
		function PANEL:Build()
			self:DockMargin(0, 0, 0, 0)
			self:DockPadding(0, 0, 0, 0)
		end

		function PANEL:Paint(w, h)
		end
	end


	function Theme:Container(PANEL)
		PANEL.theme_color = Theme.BackWhite

		function PANEL:Build()
			self:DockMargin(0, 0, 0, 0)
			self:Dock(FILL)
		end

		return "Panel"
	end

	function Theme:SidePanel(PANEL)

		function PANEL:Build()
			self:SetWide(200)
			self:DockMargin(0, 0, 0, 0)
			self:Dock(LEFT)
		end

		return "Panel"
	end




		function Theme:PageTitle(PANEL)
			function PANEL:Build()
				self:SetFont("Cash_Register_Title")
				self:SetTextColor(Theme.White)
				self:Dock(TOP)
				self:DockMargin(10, 15, 5, 5)
				self:SetTall(28)
			end
		end

		function Theme:PageDescription(PANEL)
			function PANEL:Build()
				self:SetFont("Cash_Register_BasicSmall")
				self:SetTextColor(Theme.White)
				self:Dock(TOP)
				self:DockMargin(10, 0, 10, 10)
				self:SetAutoStretchVertical(true)
				self:SetWrap(true)
			end
		end



	function Theme:Separator(PANEL)
		function PANEL:Build()
			self:Dock(TOP)
			self:SetTall(2)
			self:DockMargin(10, 5, 10, 5)
		end

		function PANEL:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, hx"fffa")
		end
	end



	function Theme:SeparatorIn(PANEL)
		function PANEL:Build()
			self:Dock(TOP)
			self:SetTall(2)
			self:DockMargin(15, 5, 15, 5)
		end

		function PANEL:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, hx"ccc9")
		end
	end



-- ###################################
-- ## Column

	function Theme:ColumnList(PANEL)

		function PANEL:Build(place_holder)
			-- self:SetWide(pr(73))
			self:DockMargin(0, 0, 0, 0)
			self:Dock(FILL)

			self.place_holder = place_holder or self.place_holder
		end

		function PANEL:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Theme.BackWhite)

			if not isstring(self.place_holder) or not IsValid(self.pnlCanvas) then return end

			if #self:GetCanvas():GetChildren() == 0 then
				draw.SimpleText(self.place_holder, "Cash_Register_Basic", 10, 10, hx(Theme.AccentHX.."80"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end
		end
	end

	function Theme:ColumnListIn(PANEL)
		function PANEL:Build(place_holder)
			self:SetWide(pr(73))
			self:DockMargin(15, 0, 15, 0)
			self:Dock(TOP)

			self.place_holder = place_holder or self.place_holder
		end

		function PANEL:Paint(w, h)
			draw.RoundedBox(4, 0, 0, w, h, Theme.White)

			if not isstring(self.place_holder) or not IsValid(self.pnlCanvas) then return end

			if #self:GetCanvas():GetChildren() == 0 then
				draw.SimpleText(self.place_holder, "Cash_Register_Basic", 10, 10, hx(Theme.AccentHX.."80"), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
			end
		end
	end

	function Theme:Column(PANEL)
		function PANEL:Build()
			self:SetTall(40)
			self:DockMargin(0, 0, 0, 0)
			self:DockPadding(20, 0, 20, 0)
			self:Dock(TOP)
		end

		function PANEL:Paint(w, h)
			draw.RoundedBox(0, 10, h-1, w - 20, 1, hx"0002")
		end
	end


	function Theme:ColumnLabel(PANEL)
		function PANEL:Build()
			self:DockMargin(0, 5, 0, 5)
			self:SetWrap(false)
			self:Dock(FILL)
		end

		return "Label"
	end

	function Theme:ColumnPriceLabel(PANEL)
		function PANEL:Build()
			self:DockMargin(10, 8, 0, 8)

			self:Dock(RIGHT)
			self:InvalidateLayout()
		end

		return "Label"
	end


	function Theme:ColumnDeleteButton(PANEL)
		function PANEL:Build()
			self:SetWide(16)
			self:SetText("")
			self:DockMargin(10, 0, 0, 0)

			self:Dock(RIGHT)
		end

		function PANEL:Paint(w, h)
			local color = Color(217, 83, 79)

			if self.Depressed or self:IsSelected() or self:GetToggle() then
				color = Color(172, 41, 37)
			elseif self.Hovered then
				color = Color(201, 48, 44)
			end
			-- draw.RoundedBoxEx(4, 0, 0, w, h, color, false, true, false, true)

			local size = 16

			surface.SetDrawColor(color)
			surface.SetMaterial(Material("pxl/vgui/remove.png"))
			surface.DrawTexturedRect((w - size)/2, (h - size)/2, size, size)
		end
	end


	function Theme:ColumnAddButton(PANEL)
		function PANEL:Build()
			self:SetWide(16)
			self:SetText("")
			self:DockMargin(10, 0, 0, 0)

			self:Dock(RIGHT)
		end

		function PANEL:Paint(w, h)
			local color = Color(92, 184, 92)

			if self.Depressed or self:IsSelected() or self:GetToggle() then
				color = Color(57, 132, 57)
			elseif self.Hovered then
				color = Color(68, 157, 68)
			end
			-- draw.RoundedBoxEx(4, 0, 0, w, h, color, false, true, false, true)

			local size = 16

			surface.SetDrawColor(color)
			surface.SetMaterial(Material("pxl/vgui/add.png"))
			surface.DrawTexturedRect((w - size)/2, (h - size)/2, size, size)
		end
	end


	function Theme:ColumnEditButton(PANEL)
		function PANEL:Build()
			self:SetWide(16)
			self:SetText("")
			self:DockMargin(10, 0, 0, 0)

			self:Dock(RIGHT)
		end

		function PANEL:Paint(w, h)
			local color = Color(91, 192, 222)

			if self.Depressed or self:IsSelected() or self:GetToggle() then
				color = Color(38, 154, 188)
			elseif self.Hovered then
				color = Color(49, 176, 213)
			end
			-- draw.RoundedBoxEx(4, 0, 0, w, h, color, false, false, false, false)

			local size = 16

			surface.SetDrawColor(color)
			surface.SetMaterial(Material("pxl/vgui/edit.png"))
			surface.DrawTexturedRect((w - size)/2, (h - size)/2, size, size)
		end
	end


	function Theme:ColumnPayButton(PANEL)
		function PANEL:Build()
			self:SetWide(16)
			self:SetText("")
			self:DockMargin(10, 0, 0, 0)
		end

		function PANEL:Paint(w, h)
			local color = Color(92, 184, 92)

			if self.Depressed or self:IsSelected() or self:GetToggle() then
				color = Color(57, 132, 57)
			elseif self.Hovered then
				color = Color(68, 157, 68)
			end
			-- draw.RoundedBoxEx(4, 0, 0, w, h, color, false, true, false, true)

			local size = 16

			surface.SetDrawColor(color)
			surface.SetMaterial(Material("pxl/vgui/arrow_right.png"))
			surface.DrawTexturedRect((w - size)/2, (h - size)/2, size, size)
		end
	end


	function Theme:ColumnActionButton(PANEL)
		function PANEL:Build()
			self:SetWide(16)
			self:SetText("")
			self:DockMargin(10, 0, 0, 0)
		end

		function PANEL:Paint(w, h)
			local color = Color(91, 192, 222)

			if self.Depressed or self:IsSelected() or self:GetToggle() then
				color = Color(38, 154, 188)
			elseif self.Hovered then
				color = Color(49, 176, 213)
			end

			local size = 16

			surface.SetDrawColor(color)
			surface.SetMaterial(Material("pxl/vgui/arrow_right.png"))
			surface.DrawTexturedRect((w - size)/2, (h - size)/2, size, size)
		end
	end


	function Theme:ColumnInvitedTag(PANEL)
		function PANEL:Build()
			self:SetWide(16)
			self:SetText("")
			self:DockMargin(10, 0, 0, 0)

			self:Dock(RIGHT)
		end

		function PANEL:Paint(w, h)
			local color = Color(91, 192, 222)

			local size = 16

			surface.SetDrawColor(color)
			surface.SetMaterial(Material("pxl/vgui/letter.png"))
			surface.DrawTexturedRect((w - size)/2, (h - size)/2, size, size)
		end
	end

	-- ####################################

	function Theme:QRCode(PANEL)
		function PANEL:Paint(w, h)

		end
	end

	-- Login

	function Theme:LoginRefreshBackground(PANEL)
		function PANEL:Build()
			local size = 40

			self:SetPos(pr(100) - size, 0)
			self:SetSize(size, size)
		end

		function PANEL:Paint(w, h)
			draw.RoundedBoxEx(20, 0, 0, w, h, Theme.Accent, false, false, true, false)
		end
	end


	function Theme:LoginRefreshButton(PANEL)
		function PANEL:Build()
			self:SetText("")
			self:DockMargin(0, 0, 0, 0)
			self:Dock(FILL)
		end

		function PANEL:Paint(w, h)
			local color = Color(245, 245, 245)
			local size = 32

			surface.SetDrawColor(color)
			surface.SetMaterial(Material("pxl/vgui/refresh32.png"))
			surface.DrawTexturedRect((w-size)/2, (h-size)/2, size, size)
		end
	end


	function Theme:MenuButton(PANEL)
		function PANEL:Build(icon)
			self:SetTextColor(Color(225, 225, 225, 0))
			self:SetFont("Cash_Register_Button")
			self:SetContentAlignment(4)
			self.icon = icon or self.icon
			self.icon_size = 16

			self:Dock(TOP)
			self:DockMargin(0, 0, 0, 0)
			self:SetTall(40)
		end

		function PANEL:Paint(w, h)
			local color = hx"0000"

			if self.Depressed or self:IsSelected() or self:GetToggle() then
				color = hx"3382f9"
			elseif self.Hovered then
				color = hx"0007"
			end

			draw.RoundedBox(0, 0, 0, w, h, color)
			if self.active then
				draw.RoundedBox(0, 0, 0, 3, h, hx"3382f9")
			end

			if self.icon then
				local size = self.icon_size
				surface.SetMaterial(Material(self.icon))
				surface.SetDrawColor(Theme.White)
				surface.DrawTexturedRect(10, (h-size)/2, size, size)

				draw.SimpleText(self:GetText(), "Cash_Register_Button", size + 15, h/2, Theme.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			else
				draw.SimpleText(self:GetText(), "Cash_Register_Button", 10, h/2, Theme.White, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end
		end
	end



	function Theme:Button(PANEL)
		function PANEL:Build()
			self:SetTextColor(Theme.White)
			self:SetFont("Cash_Register_Button")
		end

		function PANEL:Paint(w, h)
			local color = Theme.Accent

			if self:GetDisabled() then
				color = hx(Theme.AccentHX.."55")
			elseif self.Depressed or self:IsSelected() or self:GetToggle() then
				color = hx"3382f9"
			elseif self.Hovered then
				color = hx"17293e"
			end

			draw.RoundedBox(4, 0, 0, w, h, color)
		end
	end


	function Theme:PopupBackground(PANEL)
		local time = 0.1
		function PANEL:Build()
			self:SetAlpha(0)
			
			self:AlphaTo(255, time, 0.1)
		end

		function PANEL:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(0, 0, 0, 200))
		end

		local OldRemove = PANEL.Remove
		function PANEL:Remove()
			self:AlphaTo(0, time, 0, function()
				OldRemove(self)
			end)
		end
	end


	function Theme:PopupPanel(PANEL)
		function PANEL:Build()
			self:SetWide(226)
			self:DockPadding(0, 0, 0, 15)
		end

		function PANEL:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Theme.BackWhite)
			draw.RoundedBox(0, 0, 0, w, h*0.2, Theme.Accent)
		end

		-- return "Panel"
	end


	function Theme:PopupTitle(PANEL)
		function PANEL:Build()
			self:SetFont("Cash_Register_Basic")
			self:SetTextColor(Theme.White)
			self:Dock(TOP)
			self:DockMargin(10, 5, 10, 5)
			self:SetTall(28)
		end
	end


	function Theme:PopupTitleEmpty(PANEL)
		function PANEL:Build()
			self:SetFont("Cash_Register_Basic")
			self:SetTextColor(Theme.White)
			self:Dock(TOP)
			self:DockMargin(10, 5, 10, 5)
			self:SetTall(10)
		end
	end


	function Theme:PopupPanelIn(PANEL)
		function PANEL:Build()
			self:DockMargin(0, 0, 0, 0)
			self:DockPadding(15, 15, 15, 15)
		end

		function PANEL:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Theme.BackWhite)
		end

		-- return "PanelIn"
	end


	function Theme:PopupButton(PANEL)
		function PANEL:Build()
			self:Dock(TOP)
			self:DockMargin(0, 0, 0, 0)
			self:SetTall(35)
			self:SetTextColor(Theme.Accent)
			self:SetFont("Cash_Register_Button")
		end

		function PANEL:Paint(w, h)
			local color = Theme.BackWhite

			if self.Depressed or self:IsSelected() or self:GetToggle() then
				color = hx"3382f9"
			elseif self.Hovered then
				color = hx"e3e3e3"
			end

			draw.RoundedBox(0, 0, 0, w, h, color)
		end
	end

	function Theme:PopupSplit(PANEL)
		function PANEL:Build()
			self:DockMargin(0, 0, 0, 0)
			self:SetTall(35)
		end
	end

	function Theme:PopupButtonSplit(PANEL)
		function PANEL:Build()
			self:SetWide((226)/2)
			self:SetTextColor(Theme.Accent)
			self:SetFont("Cash_Register_Button")
		end

		function PANEL:Paint(w, h)
			local color = Theme.BackWhite

			if self.Depressed or self:IsSelected() or self:GetToggle() then
				color = hx"3382f9"
			elseif self.Hovered then
				color = hx"e3e3e3"
			end

			draw.RoundedBox(0, 0, 0, w, h, color)
		end
	end


	function Theme:Panel(PANEL)
		function PANEL:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, self.theme_color or Theme.Accent)
		end
	end


	function Theme:PanelIn(PANEL)
		function PANEL:Paint(w, h)
			draw.RoundedBox(4, 0, 0, w, h, self.theme_color or Theme.White)
		end
	end


	function Theme:Price(PANEL)
		function PANEL:Build()
			self:SetTextColor(Theme.White)
			self:SetFont("Cash_Register_Price")
		end
	end


	function Theme:Label(PANEL)
		function PANEL:Build()
			self:SetFont("Cash_Register_Basic")
			self:SetTextColor(Theme.Accent)
		end
	end


	function Theme:Header(PANEL)
		function PANEL:Build()
			self:SetFont("Cash_Register_Big")
			self:SetTextColor(Theme.Accent)
			self:SetTall(30)
		end
	end


	function Theme:Title(PANEL)
		function PANEL:Build()
			self:SetFont("Cash_Register_Big")
			self:SetTextColor(Theme.Accent)
		end
	end


	-- function Theme:Column(PANEL)
	-- 	function PANEL:Paint(w, h)
	-- 		draw.RoundedBox(4, 0, 0, w, h, hx"ddd")
	-- 	end
	-- end


	function Theme:CheckBox(PANEL)
		function PANEL:Paint(w, h)
			if self:GetChecked() then
				surface.SetMaterial(Material("pxl/vgui/checkbox_on.png"))
			else
				surface.SetMaterial(Material("pxl/vgui/checkbox_off.png"))
			end

			local size = 32

			surface.SetDrawColor(Color(255, 255, 255))
			surface.DrawTexturedRect((w-size)/2, (h-size)/2, size, size)
		end
	end

	local last_type = 0
	function Theme:TextEntry(PANEL)
		function PANEL:Build()
			self:SetFont("Cash_Register_Basic")
			self.OnKeyCodeTyped = function(self, code)

				if CurTime() - last_type > 0.05 then
					screen:Send().KeyTyping()
				end
				last_type = CurTime()
			end
		end

		function PANEL:Paint(w, h)
			draw.RoundedBox(4, 0, 0, w, h, Theme.White)

			self:DrawTextEntryText(Theme.Accent, Color(47, 139, 251), Theme.Accent)
		end

		function PANEL:OnMousePressed()
			if not screen:IsLinked() then
				screen:Link()

				timer.Simple(0.5, function()
					self:RequestFocus()
				end)
			end
		end
	end


	function Theme:Slider(PANEL)
		function PANEL:Build()
			self.TextArea:SetWide(35)
			self.TextArea:SetTextColor(Theme.Accent)
			screen:ApplyTheme(self.Label, "Label")

			self.Slider.Paint = function(self, w, h)
				surface.SetDrawColor(Theme.Accent)
				surface.DrawRect(8, h / 2 - 1, w - 15, 1)

				local space = (w - 16) / 5
				for i = 0, 5 do
					surface.DrawRect(8 + i * space, h / 2 - 1 + 4, 1, 5)
				end
			end
		end
	end



	-- ##################################
	-- ## Main

	function Theme:Main_PriceBackground(PANEL)
		function PANEL:Build()
			self:Dock(TOP)
			self:SetTall(35)
			self:DockMargin(10, 5, 10, 5)
		end

		return "PanelIn"
	end

	function Theme:Main_PriceLabel(PANEL)
		function PANEL:Build()
			self:DockMargin(5, 8, 5, 8)
			self:SetTextColor(Theme.Accent)
			self:SetFont("Cash_Register_Price")
			self:Dock(TOP)
		end
	end





	function Theme:CustomerBack(PANEL)
		PANEL.theme_color = Theme.BackWhite
		return "PanelIn"
	end
end)
