local TabPanel = PxlCashRegister.NewClass("TabPanel")

function TabPanel:Construct(window, parent)
	self.screen = screen
	self.builded = false
	self.active_derma = {}
	self.parent = parent
	self.window = window
end

function TabPanel:Init()
	self.builded = true

	self.panel = vgui.Create("DPanel", self.parent, self.Name)
	self.panel:Dock(FILL)
	-- self.panel:SetSize(self:Screen():Panel():GetSize())
	self.panel:SetVisible(false)

	self.panel.Paint = function() end


	self.Build(self, self:Screen(), self.panel)

	return self.panel
end

function TabPanel:Screen()
	return self:Window():Screen()
end

function TabPanel:Window()
	return self.window
end

function TabPanel:Panel()
	return self.panel
end

function TabPanel:OnRemove()
	if IsValid(self.panel) then
		self.panel:Remove()
	end
end



function TabPanel:ApplyTheme(...)
	return self:Screen():ApplyTheme(...)
end
function TabPanel:CreateVGUI(...)
	return self:Screen():CreateVGUI(...)
end

function TabPanel:Send(...)
	return self:Screen():Send(...)
end


function TabPanel:Open()
end
function TabPanel:Close()
end
