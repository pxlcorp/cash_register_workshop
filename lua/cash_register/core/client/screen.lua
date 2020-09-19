
PxlCashRegister.Screen = PxlCashRegister.NewClass("Screen")
local Screen = PxlCashRegister.Screen

local tr = PxlCashRegister.Language.GetDictionary("main")

local vgui3D2D = include("cash_register/includes/vgui3d2d.lua")

local link_info = {
	status = "idle"
}
local hide_crosshair
--[[---------------------------------------------------------
	Screen Object
-----------------------------------------------------------]]

	Screen.Themes = Screen.Themes or {}
	Screen.AllScreen = Screen.AllScreen or {}




	-- Constructor
	function Screen:Construct(ent, pos, ang, width, height, resolution)
		table.insert(Screen.AllScreen, self)

		self.screen_resolution = resolution or 800
		self.parent = ent
		self.pos = pos
		self.ang = ang
		self.height = height
		self.scale = width/self.screen_resolution
		self.active_theme = PxlCashRegister.Config.Theme or "Default"
		self.active_derma = {}
		self.builded = false
		self.popups = {}
		self.screen_active = false

		local p = LocalToWorld(Vector(0, -width/2, -height/2), Angle(), pos, ang)


		self:LinkSetup(p, {width=width,height=height}, ang, 0.3)

		self.islinked = false

		self:SetTheme(self.active_theme)

		self.activeWindow= nil
		self.windows = {}

		for _, window in pairs(self.Windows) do
			self:AddWindow(window)
		end
	end



	-- Theme Management

	function Screen.AddTheme(name, theme)
		Screen.Themes[name] = theme

		for id, screen in pairs(Screen.AllScreen) do
			if screen.active_theme == name then
				screen:SetTheme(name)
			end
		end
	end


	function Screen:SetTheme(theme_name)
		self.theme = {}

		Screen.Themes[theme_name](self.theme, self)

		for _, drm in pairs(self.active_derma) do
			if IsValid(drm) then
				self:ApplyTheme(drm, drm.theme_element)
			end
		end
	end

	function Screen:Theme()
		return self.theme
	end

	function Screen:ApplyTheme(drm, element, is_inherited, ...)
		if drm and not drm.theme_element then
			table.insert(self.active_derma, drm)
		end

		local theme = self.theme

		if not is_inherited then
			drm.theme_element = element
		end

		if theme then
			if theme.MetaPanel then
				theme.MetaPanel(theme, drm)
			end

			local theme_element = theme[element]
			if theme_element then
				local inherit = theme_element(theme, drm)

				if isfunction(drm.Build) then
					drm:Build(...)
				end

				if inherit then
					self:ApplyTheme(drm, inherit, true, ...)
				end
			end
		end
	end

	function Screen:CreateVGUI(class, parent, element, ...)
		assert(self.theme[element])
		local drm = vgui.Create(class, parent, element)

		self:ApplyTheme(drm, element, nil, ...)

		return drm
	end



	-- Panel

	function Screen:InitPanel(forcewindow)
		self.pnl = vgui.Create("DFrame")
		self.pnl:SetPaintedManually(true)
		-- self.pnl:ParentToHUD()
		self.pnl:SetSize(self.screen_resolution, self.height/self.scale)
		self.pnl:ShowCloseButton(false)
		self.pnl:SetTitle("")
		self.pnl:DockPadding(0, 0, 0, 0)
		self.pnl:MoveToBack()
		self.pnl:SetDraggable(false)
		self.pnl.Paint = function(_, x, y)
			surface.SetDrawColor(0, 0, 0, 255)
			surface.DrawRect(0, 0, x, y)
		end

		self.pnl.OnTouch = function(pnl, key)
			if self.OnTouch then
				return self:OnTouch(key)
			end
		end

		self.pnl.OnRelease = function(pnl, key)
			if self.OnRelease then
				return self:OnRelease(key)
			end
		end

		self.pnl.Think = function(pnl)
			if self.Think then
				return self:Think()
			end
		end

		self.builded = true

		if self:Window(forcewindow or self.defaultwindow) then
			self:Show(forcewindow or self.defaultwindow)
		end
	end

	function Screen:IsBuilded()
		return self.builded and IsValid(self:Panel())
	end

	function Screen:RemovePanel()
		self:ClearWindows()
		self.pnl:Remove()
		self.builded = false
	end

	function Screen:Panel()
		return self.pnl
	end

	function Screen:OnTouch(key)
		if self.screen_active then
			if not self:IsFocused() and (key == MOUSE_LEFT or key == MOUSE_RIGHT) then
				self:Focus()
				return true
			end

			if key == MOUSE_MIDDLE then
				self:Link()
				return true
			end
		else
			return true
		end
	end

	--

	function Screen:RegisterWindow(window)
		assert(self:IsClass())
		self.Windows[window:Name()] = window

		for _, screen in pairs(Screen.AllScreen) do
			if screen:IsBuilded() and screen:Window():Class() == window then
				screen:Unlink(true)
				screen:RemovePanel()
				screen:InitPanel(window:Name())
			end
		end
	end

	function Screen:BuildWindow(name)
		self:Window(name):Init()
	end

	function Screen:ClearWindows()
		for _, win in pairs(self.windows) do
			if win:IsBuilded() then
				win:RemovePanel()
			end
		end

		self.active_derma = {}
		self.activeWindow = nil
	end

	function Screen:AddWindow(winclass)
		local win = winclass:New(self)

		self.windows[win:Name()] = win

		return win
	end

	function Screen:Window(name)
		return name and self.windows[name] or self:ActiveWindow()
	end

	function Screen:ActiveWindow()
		return self.activeWindow
	end

	function Screen:Show(name)
		local window = self:Window(name)

		if window then
			self.defaultwindow = self.defaultwindow or name

			if self.activeWindow then
				self.activeWindow:Panel():SetVisible(false)
				self.activeWindow:Close()

				if IsValid(self.activeWindow:ActiveTab()) then
					self.activeWindow:ActiveTab():Close()
				end
			end

			self.activeWindowName = name
			self.activeWindow = window

			if not window.builded then
				window:Init()
			end

			window:Panel():SetVisible(true)
			window:Open()

			if IsValid(window:ActiveTab()) then
				window:ActiveTab():Open()
			end
		end
	end

	function Screen:Draw()
		if not self.parent then return end
		if not self.builded then self:InitPanel() end
		if self.link_info and self.link_info.status == "linked" then return end
		if not self.pnl:IsValid() then
			self:InitPanel()

			if self.activeWindowName then
				self:Show(self.activeWindowName)
			end
			return
		end

		if self.parent_cur_pos ~= self.parent:GetPos() and self.parent_cur_ang ~= self.parent:GetAngles() then
			local _, a = LocalToWorld(Vector(), Angle(0,-90,90), Vector(), self.ang)
			self.cur_ang = self.parent:LocalToWorldAngles(a)
			self.cur_pos = self.parent:LocalToWorld(self.pos)
		end

		vgui3D2D.Start(self.cur_pos, self.cur_ang, self.scale)
			vgui3D2D.MaxRange(PxlCashRegister.Config.ScreenRange)
			vgui3D2D.Paint(self.pnl)

			if LocalPlayer():GetEyeTrace().Entity == self.parent and vgui3D2D.IsPointingPanel(self.pnl) then
				local x, y = vgui3D2D.GetCursorPos(self.pnl)

				surface.SetDrawColor(Color(255, 255, 255))
				surface.SetMaterial(Material("pxl/vgui/cursor.png"))
				surface.DrawTexturedRect(x, y, 32, 32)

				hide_crosshair = self.pnl
				self.screen_active = true
			else
				if IsValid(hide_crosshair) and hide_crosshair == self.pnl then
					hide_crosshair = false
					self.screen_active = false
					
					self:Unfocus()
				end
			end
		vgui3D2D.End()
	end

	function Screen:Think()
		if self.link_info and self.link_info.status == "linked" then
			if IsValid(self.parent) then
				if LocalPlayer():GetShootPos():Distance(self.parent:GetPos()) > PxlCashRegister.Config.ScreenRange + 10 then
					self:Unlink()
				end
		
				local x, y = input.GetCursorPos()
		
				local margin = 100
		
				if x < margin or x > ScrW() - margin or y < margin or y > ScrH() - margin then
					if not unlink_delay then
						unlink_delay = CurTime()
					end
		
					if CurTime() - unlink_delay > 0.2 then
						self:Unlink()
					end
				else
					unlink_delay = nil
				end
			else
				self:Unlink()
			end
		end
	end

	function Screen:OnRemove()
		for id, screen in pairs(Screen.AllScreen) do
			if screen == self then
				table.remove(Screen.AllScreen, id)
				break
			end
		end

		if self:IsLinked() then
			self:Unlink(true)
		end

		if self:IsFocused() then
			self:Unfocus()
		end

		self.pnl:Remove()
	end

	function Screen:ReceiveCallback(action, ...)
		if self[action] then return end

		local args = {...}

		for _, window in pairs(self.windows) do
			if window[action] then
				window[action](window, ...)

				return false
			else
				for _, tab in pairs(window.tabpanels) do
					if tab[action] then
						tab[action](tab, ...)

						return false
					end
				end
			end
		end
	end

	-- Popup


	function Screen:CustomPopup(title, build, no_sep)
		-- local was_linked = self:IsLinked()

		-- if not self:IsLinked() then
		-- 	self:Link()
		-- end


		if isfunction(title) then
			build = title
			title = ""
		end


		local popup = {}
		local id = table.insert(self.popups, popup)

		local background = self:CreateVGUI("DPanel", self:Panel(), "PopupBackground")

		local w,h = self:Panel():GetSize()
		background:SetSize(0, h)
		

		local panel = self:CreateVGUI("DSizeToContents", background, "PopupPanel")
		panel:SetSizeX(false)
		panel:InvalidateLayout()
		panel.background = background
		panel:CenterVertical(0.15)
		
		timer.Simple(0.1, function()
			
			background:SetSize(self:Panel():GetSize())
			panel:CenterHorizontal()
		end)

		function panel.Close()
			self:RemovePopup(id)
		end

		local title_label = self:CreateVGUI("DLabel", panel, title == "" and "PopupTitleEmpty" or "PopupTitle")
		title_label:SetText(title)

		local box = self:CreateVGUI("DSizeToContents", panel, "PopupPanelIn")
		box:Dock(TOP)
		box:SetSizeX(false)
		box:InvalidateLayout()
		local args = build(panel, box) or {}


		if not no_sep then
			self:CreateVGUI("DPanel", panel, "SeparatorIn")
		end

		if #args == 0 then
			args[1] = {tr"close"}
		end

		if #args == 2 then
			local div = self:CreateVGUI("DPanel", panel, "PopupSplit")
			div:Dock(TOP)
			div.Paint = nil

			local but1 = self:CreateVGUI("DButton", div, "PopupButtonSplit")
			but1:Dock(LEFT)
			but1:SetText(args[1][1])
			but1.DoClick = function()
				self:Send().EmitSound()
				local override
				if args[1][2] then override = args[1][2]() end
				if not override then self:RemovePopup(id) end
				-- if not was_linked then self:Unlink() end
			end

			local but2 = self:CreateVGUI("DButton", div, "PopupButtonSplit")
			but2:Dock(RIGHT)
			but2:SetText(args[2][1])
			but2.DoClick = function()
				self:Send().EmitSound()
				local override
				if args[2][2] then override = args[2][2]() end
				if not override then self:RemovePopup(id) end
				-- if not was_linked then self:Unlink() end
			end
		else
			for _, par in pairs(args) do
				if par then
					if par == "_" then
						self:CreateVGUI("DPanel", panel, "SeparatorIn")
					elseif isfunction(par) then
						par(panel, box)
					else
						local but = self:CreateVGUI("DButton", panel, "PopupButton")
						but:SetText(par[1])
						but.DoClick = function()
							self:Send().EmitSound()
							local override
							if par[2] then override = par[2]() end
							if not override then self:RemovePopup(id) end
							-- if not was_linked then self:Unlink() end
						end
					end
				end
			end
		end


		popup.background = background
		popup.panel = panel

		return id
	end

	function Screen:PopupTitle(title, text, ...)
		local args = {...}

		return self:CustomPopup(title, function(panel, box)
			local label = self:CreateVGUI("DLabel", box, "Label")
			label:SetAutoStretchVertical(true)
			label:SetWrap(true)
			label:SetText(text)
			label:Dock(TOP)
			label:DockMargin(0, 0, 0, 0)

			return args
		end)
	end

	function Screen:Popup(text, ...)
		return self:PopupTitle("", text, ...)
	end

	function Screen:RemovePopup(id)
		local popup = self.popups[id]
		self.popups[id] = nil
		popup.background:Remove()
	end

	function Screen:ClearPopup()
		for id, _ in pairs(self.popups) do
			self:RemovePopup(id)
		end
	end

	function Screen:Message(...)
		self:Popup(tr(...))
	end

	function Screen:MessageTitle(title, ...)
		self:PopupTitle(tr(title), tr(...))
	end


	-- Linking

	function Screen:LinkSetup(pos, size, ang, duration)
		self.link_pos = pos
		self.link_size = size
		self.link_ang = ang
		self.link_duration = duration
	end

	function Screen:DisableLinking(disable)
		self.linking_disabled = disable

		if self.islinked then
			self:Unlink()
		end
	end

	function Screen:Link()
		if self.islinked then return end
		if self.linking_disabled then return end
		if link_info.status == "out" and link_info.screen ~= self then return end

		if link_info.screen and not link_info.status == "focus_in" then
			link_info.screen:Unlink()
			return
		end

		surface.PlaySound("pxl/cash_register/transition.ogg")

		self.islinked = true
		self.link_info = link_info
		
		self.is_focused = false

		link_info.screen = self
		link_info.status = "in"
		link_info.start = CurTime() + math.min(CurTime() - (link_info.start or 0), self.link_duration) - self.link_duration
		link_info.start_pos = LocalPlayer():GetShootPos()
		link_info.start_ang = LocalPlayer():EyeAngles()
		link_info.start_fov = link_info.cur_fov
		link_info.duration = self.link_duration
	end

	function Screen:Unlink(force)
		if not self.islinked then return end
		if link_info.status ~= "linked" and not force then return end

		
		self:Panel():SetPaintedManually(true)
		self:Panel():SetParent(nil)
		self:Panel():MoveToBack()
		self:Panel():SetPos(0, 0)

		if link_info.button and link_info.button:IsValid() then
			link_info.button:Remove()
		end

		if link_info.panel and link_info.panel:IsValid() then
			link_info.panel:Remove()
		end

		self.islinked = false


		surface.PlaySound("pxl/cash_register/transition.ogg")

		link_info.status = "out"
		link_info.start = CurTime() + math.min(CurTime() - (link_info.start or 0), self.link_duration) - self.link_duration
		link_info.start_pos = link_info.cur_pos
		link_info.start_ang = link_info.cur_ang
		link_info.start_fov = link_info.cur_fov
		link_info.duration = self.link_duration

		-- self:Panel():SetMouseInputEnabled(false)
		-- self:Panel():SetKeyboardInputEnabled(false)

		-- gui.EnableScreenClicker(false)

		-- self:Panel():SetPos(0, 0)
	end

	function Screen:IsLinked()
		return self.islinked
	end





	function Screen:DisableFocusing(disable)
		self.focused_disabled = disable

		if self:IsFocused() then
			self:Unfocus()
		end
	end

	function Screen:Focus()
		if self:IsFocused() then return end
		if self.islinked then return end
		if self.focused_disabled then return end

		
		self.is_focused =  true

		link_info.screen = self
		link_info.status = "focus_in"
		link_info.start = CurTime()
		link_info.start_fov = link_info.cur_fov

		if self.link_info then
			link_info.duration = self.link_duration
			link_info.start_pos = self.link_info.cur_pos or LocalPlayer():GetShootPos()
			link_info.start_ang = self.link_info.cur_ang or LocalPlayer():EyeAngles()
		else
			link_info.duration = self.link_duration/1.4
			link_info.start_pos = LocalPlayer():GetShootPos()
			link_info.start_ang = LocalPlayer():EyeAngles()
		end

		
		self.link_info = link_info
	end

	function Screen:Unfocus()
		if not self:IsFocused() then return end
		
		self.is_focused = false
		link_info.status = "out"
		link_info.start = CurTime()

		link_info.start_fov = link_info.cur_fov
		link_info.duration = self.link_duration/1.4

		if self.link_info then
			link_info.start_pos = self.link_info.cur_pos or LocalPlayer():GetShootPos()
			link_info.start_ang = self.link_info.cur_ang or LocalPlayer():EyeAngles()
		else
			link_info.start_pos = LocalPlayer():GetShootPos()
			link_info.start_ang = LocalPlayer():EyeAngles()
		end
	end

	function Screen:IsFocused()
		return self.is_focused
	end



hook.Add("CalcView", "PxlCashRegister.CalcView", function(ply, origin, angles, fov, znear, zfar)
	local cam = {}

	if link_info.status == "in" then
		local self = link_info.screen

		link_info.fov = fov
		local progress = math.min((CurTime() - link_info.start)/link_info.duration, 1)

		link_info.cur_ang = LerpAngle(progress, link_info.start_ang, self.parent:LocalToWorldAngles(self.link_ang))
		cam.angles = link_info.cur_ang

		link_info.cur_fov = Lerp(progress, link_info.start_fov or fov, fov)
		cam.fov = link_info.cur_fov

		local opposite = ((self.link_size.height / self:Panel():GetTall()) * ScrH()) / 2
		local ang = fov / 2 * math.pi / 180
		local distance = opposite / math.tan(ang) * 1.33

		link_info.cur_pos = LerpVector(progress, link_info.start_pos, self.parent:LocalToWorld(self.link_pos) - self.parent:LocalToWorldAngles(self.link_ang):Forward()*distance)
		cam.origin = link_info.cur_pos


		if progress == 1 and not link_info.is_waiting then

			local but = vgui.Create("DButton")
			but:SetSize(ScrW(), ScrH())
			but:SetText("")
			but:SetCursor("up")
			but:MakePopup()
			but:ParentToHUD()
			but.Paint = function() end
			but.DoClick = function()
				self:Unlink()

				if but and but:IsValid() then
					but:Remove()
				end
			end

			local pnl = vgui.Create("DFrame", but)
			pnl:ShowCloseButton(false)
			pnl:SetTitle("")
			pnl:SetSize(self:Panel():GetSize())
			pnl:Center()
			pnl:MakePopup()
			pnl:SetDraggable(false)
			pnl.Paint = function(_, x, y) return end

			link_info.button = but
			link_info.panel = pnl
			self:Panel():SetPos(0, 0)

			local cx, cy = vgui3D2D.GetCursorPos(self:Panel())

			if cx and cy then
				local sx, sy = pnl:GetPos()
				input.SetCursorPos(cx + sx, cy + sy)
			end

			link_info.is_waiting = true

			timer.Simple(0, function()
				link_info.is_waiting = false
				link_info.status = "linked"
				
				self:Panel():SetPaintedManually(false)
				self:Panel():SetParent(pnl)
			end)
		end

		return cam
	elseif link_info.status == "out" then
		local progress = math.min((CurTime() - link_info.start)/link_info.duration, 1)

		link_info.cur_pos = LerpVector(progress, link_info.start_pos, LocalPlayer():GetShootPos())
		cam.origin = link_info.cur_pos

		link_info.cur_ang = LerpAngle(progress, link_info.start_ang, LocalPlayer():EyeAngles())
		cam.angles = link_info.cur_ang

		
		link_info.cur_fov = Lerp(progress, link_info.start_fov, fov)
		cam.fov = link_info.cur_fov

		if progress == 1 then
			link_info.screen.link_info = nil

			link_info.status = "idle"
			link_info.screen = nil

		end

		return cam
	elseif link_info.status == "linked" then
		local self = link_info.screen

		local opposite = ((self.link_size.height / self:Panel():GetTall()) * ScrH()) / 2
		local ang = fov / 2 * math.pi / 180
		local distance = opposite / math.tan(ang) * 1.33

		link_info.cur_pos = self.parent:LocalToWorld(self.link_pos) - self.parent:LocalToWorldAngles(self.link_ang):Forward()*distance
		cam.origin = link_info.cur_pos

		link_info.cur_ang = self.parent:LocalToWorldAngles(self.link_ang)
		cam.angles = link_info.cur_ang

		local x, y = gui.MousePos()
		if x and y and x ~= 0 and y ~= 0 then
			local pos = gui.ScreenToVector(x, y)

			local tr = util.TraceLine({
				start = link_info.cur_pos,
				endpos = link_info.cur_pos + pos * 10000,
				filter = LocalPlayer()
			})

			LocalPlayer():SetEyeAngles((tr.HitPos - LocalPlayer():GetShootPos()):Angle())
		end

		return cam
	elseif link_info.status == "focus_in" then
		local self = link_info.screen

		if not link_info.cur_fov then
			link_info.cur_fov = fov
			link_info.start_fov = fov
		end

		local progress = math.min((CurTime() - link_info.start)/link_info.duration, 1)

		local view_pos = WorldToLocal(LocalPlayer():GetShootPos(), Angle(), self.cur_pos, self.cur_ang)
		local to_center = self.cur_ang:Forward() * math.Clamp(view_pos.x, 0, self.link_size.width)
		local dist = util.DistanceToLine(self.cur_pos + to_center, self.cur_pos + self.cur_ang:Right()*self.link_size.height + to_center, LocalPlayer():GetShootPos())
		local target_fov = math.Remap(dist + 5, 0, PxlCashRegister.Config.ScreenRange, 100, 60)

		
		link_info.cur_pos = LerpVector(progress, link_info.start_pos, LocalPlayer():GetShootPos())
		cam.origin = link_info.cur_pos

		link_info.cur_ang = LerpAngle(progress, link_info.start_ang, LocalPlayer():EyeAngles())
		cam.angles = link_info.cur_ang

		if dist <= PxlCashRegister.Config.ScreenRange then
			link_info.cur_fov = Lerp(progress, link_info.start_fov, target_fov)
		end

		cam.fov = link_info.cur_fov

		return cam
	end
end)


hook.Add("CalcViewModelView", "PxlCashRegister.CalcViewModelView", function(wep, vm, oldPos, oldAng, pos, ang)
	if link_info.status == "in" or link_info.status == "focus_in" then
		local progress = math.min((CurTime() - link_info.start)/link_info.duration, 1)
		local dist = link_info.status == "focus_in" and 2 or 50
		link_info.wep_dist = dist

		return LerpVector(progress, pos, oldPos - ang:Up()*dist), ang
	elseif link_info.status == "out" then
		local progress = math.min((CurTime() - link_info.start)/link_info.duration, 1)
		return LerpVector(progress, oldPos - ang:Up()*link_info.wep_dist, pos), ang
	elseif link_info.status == "linked" then
		return oldPos - ang:Forward()*1000, ang
	end
end)


hook.Add("HUDShouldDraw", "PxlCashRegister.HUDShouldDraw", function(name)
	if name == "CHudCrosshair" and (link_info.status ~= "idle" or hide_crosshair) then
		return false
	end
end)


local escapIsDown, recording = false
local record_key, use_key, use_down

hook.Add( "PreRender", "PxlCashRegister.PreRender", function()
	if input.IsKeyDown(KEY_ESCAPE) then
		if not escapIsDown and link_info.screen and link_info.status ~= "out" and link_info.status ~= "focus_in" then
			gui.HideGameUI()

			link_info.screen:Unlink()

			escapIsDown = true
			return true
		end
	else
		escapIsDown = false
	end



	if link_info.screen then
		local istypeing = (vgui.GetKeyboardFocus() and vgui.GetKeyboardFocus():GetClassName() == "TextEntry")
		record_key = input.GetKeyCode(input.LookupBinding("voicerecord"))
		use_key = input.GetKeyCode(input.LookupBinding("use"))

		
		if input.IsKeyDown(record_key) then
			if not recording and not istypeing  then
				recording = true
				RunConsoleCommand("+voicerecord")
			end
		elseif recording then
			recording = false
			RunConsoleCommand("-voicerecord")
		end

		if not use_down and input.IsKeyDown(use_key) then
			use_down = true

			if link_info.status == "linked" and not istypeing then
				timer.Simple(0, function()
					link_info.screen:Unlink()
				end)
			end
		elseif use_down and not input.IsKeyDown(use_key) then
			use_down = false
		end
	else
		if recording and not input.IsKeyDown(record_key) then
			recording = false
			RunConsoleCommand("-voicerecord")
		end
	end
	
end)
