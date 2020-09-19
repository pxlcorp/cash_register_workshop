
local UScreen = PxlCashRegister.UserScreen
local More = PxlCashRegister.Get("UScreen.More")
local tr = PxlCashRegister.Language.GetDictionary("main")

local Logs = PxlCashRegister.NewClass("UScreen.More.Logs", "TabPanel")

Logs.Name = "logs"
Logs.Tooltip = "info.logs"

function Logs:Build(window, panel)
	local logs_label = self:CreateVGUI("DLabel", panel, "Header")
	logs_label:SetText(tr"logs")
	logs_label:Dock(TOP)
	logs_label:DockMargin(15, 15, 15, 8)

	local logs_list = self:CreateVGUI("DScrollPanel", panel, "ColumnListIn")
	logs_list:Dock(FILL)
	logs_list:SetTall(436)
	logs_list:DockMargin(15, 5, 15, 15)
	self.logs_list = logs_list
end

function Logs:AddLogs(id, log)
	local column = self:CreateVGUI("DSizeToContents", self.logs_list, "Column")
	column:Dock(TOP)
	column:SetSizeX(false)
	column:InvalidateLayout()
	column:DockPadding(10, 10, 10, 10)
	column:SetCursor("hand")

	local name_label = self:CreateVGUI("DLabel", column, "Label")
	name_label:SetAutoStretchVertical(true)
	name_label:SetWrap(true)
	name_label:SetText(tr(unpack(log.args)))
	name_label:Dock(TOP)
	name_label:DockMargin(0, 0, 0, 0)
	name_label:SetMouseInputEnabled(true)
	name_label:SetCursor("hand")


	name_label.DoClick = function()
		if Logs.LogType[log.type] then
			local actions = {}

			for _, but in pairs(Logs.LogType[log.type]) do
				table.insert(actions, {tr(but.Name), function()
					but.DoClick(self, log)
				end})
			end

			table.insert(actions, "_")
			table.insert(actions, {tr"close"})

			self:Screen():Popup(tr"which_action_for_log", unpack(actions))
		else
			self:Screen():Popup(tr"there_is_no_action")
		end
	end
end

function Logs:GetLogs(data)
	local info = util.JSONToTable(data)

	self.logs_list:Clear()

	for id, log in pairs(info.logs) do
		self:AddLogs(id, log)
	end
end

function Logs:Open()
	self:Send().NeededInfo("log")
	self:Send().GetLogs()
end


--[[----------------------------------------------------------
-	Logs Custom Column										]]
Logs.LogType = {}
Logs.LogType.Purchase = {
	{
		Name = "print",
		Icon = "pxl/vgui/arrow_right.png",
		DoClick = function(self, log)
			self:Send().PrintReceipt(log.id)
		end
	},
	{
		Name = "print_to_customer",
		Icon = "pxl/vgui/arrow_right.png",
		DoClick = function(self, log)
			self:Send().PrintReceiptToCustomer(log.id)
		end
	}
}



More:RegisterTab(Logs)
