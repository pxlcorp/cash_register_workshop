local Window = PxlCashRegister.NewClass("Window")


--[[---------------------------------------------------------
	Window Object
-----------------------------------------------------------]]

	function Window:Construct(screen)
		self.screen = screen
		self.builded = false
		self.active_derma = {}

		self.tabpanels = {}
	end

	function Window:Init()
		self.builded = true

		self.panel = vgui.Create("DPanel", self:Screen():Panel(), self.name)
		self.panel:Dock(FILL)
		self.panel:SetSize(self:Screen():Panel():GetSize())
		self.panel:SetVisible(false)

		self.panel.Paint = function() end

		self:Build(self:Screen(), self.panel)

		return self.panel
	end

	function Window:OnRemove()
		self:Panel():Remove()

		self:RemoveTabs()
	end

	function Window:Screen()
		return self.screen
	end

	function Window:Panel()
		return self.panel
	end

	function Window:Name()
		return self.name
	end

	function Window:Send(...)
		return self:Screen():Send(...)
	end

	function Window:RemovePanel()
		self:Close()

		self.panel:Remove()
		self.builded = false

		self:RemoveTabs()
	end

	function Window:IsBuilded()
		return self.builded
	end

	function Window:Rebuild()
		self:RemovePanel()
		self:Init()
	end

	function Window:IsVisible()
		return IsValid(self:Panel()) and self:Panel():IsVisible()
	end




	function Window:InitTabs(parent)
		self.tabparent = parent
		for _, tab in pairs(self.TabPanels or {}) do
			self.tabpanels[tab.Name] = tab:New(self, parent)

			self:OnTabInit(tab)
		end
	end

	function Window:RegisterTab(tab)
		assert(self:IsClass())

		self.TabPanels = self.TabPanels or {}
		self.TabPanels[tab.Name] = tab

		for _, screen in pairs(PxlCashRegister.Screen.AllScreen) do
			for _, window in pairs(screen.windows or {}) do
				if window.activetab and window.activetab:Class() == tab then
					window:RemoveTabs()
					window:InitTabs(window.tabparent)
					window:Show(tab.Name)
				end
			end
		end
	end

	function Window:Show(name)
		local tab = self.tabpanels[name]

		if IsValid(tab) then
			if self.activetab then
				self.activetab:Panel():SetVisible(false)
				self:OnTabClose(self.activetab)

				if self.activetab.Close then
					self.activetab:Close(self)
				end
			end

			if not tab.builded then
				tab:Init()
			end

			tab:Panel():SetVisible(true)
			self:OnTabOpen(tab, self.activetab)

			self.activetab = tab

			if tab.Open then
				tab:Open(self)
			end
		end
	end

	function Window:RemoveTabs()
		for _, tab in pairs(self.tabpanels) do
			tab:Remove()
		end
		self.activetab = nil

		self:OnTabsRemove()
	end

	function Window:ActiveTab()
		return self.activetab
	end



	function Window:CustomPopup(...)
		if isfunction(self:Screen().CustomPopup) then
			return self:Screen():CustomPopup(...)
		end
	end
	function Window:PopupTitle(...)
		if isfunction(self:Screen().PopupTitle) then
			return self:Screen():PopupTitle(...)
		end
	end
	function Window:Popup(...)
		if isfunction(self:Screen().Popup) then
			return self:Screen():Popup(...)
		end
	end
	function Window:RemovePopup(...)
		if isfunction(self:Screen().RemovePopup) then
			return self:Screen():RemovePopup(...)
		end
	end
	function Window:ClearPopup(...)
		if isfunction(self:Screen().ClearPopup) then
			return self:Screen():ClearPopup(...)
		end
	end
	function Window:Theme(...)
		return self:Screen():Theme(...)
	end
	function Window:ApplyTheme(...)
		return self:Screen():ApplyTheme(...)
	end
	function Window:CreateVGUI(...)
		return self:Screen():CreateVGUI(...)
	end

	-- Function to Override
		function Window:Build()
		end

		function Window:Open()
		end

		function Window:Close()
		end

		function Window:ChangeLanguage(new, old)
		end

		function Window:OnTabInit()
		end

		function Window:OnTabOpen()
		end

		function Window:OnTabClose()
		end

		function Window:OnTabsRemove()
		end
