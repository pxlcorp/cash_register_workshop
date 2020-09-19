local UScreen = PxlCashRegister.UserScreen
local Option = PxlCashRegister.Get("UScreen.Option")
local tr = PxlCashRegister.Language.GetDictionary("main")

local Server = PxlCashRegister.NewClass("UScreen.Option.Server", "TabPanel")


Server.Name = "server"
Server.Tooltip = "info.server"

function Server:Build(window, panel)
	local server_label = self:CreateVGUI("DLabel", panel, "Title")
	server_label:SetText(tr"server_name")
	server_label:Dock(TOP)
	server_label:DockMargin(15, 15, 15, 8)

	local name_backgroud = self:CreateVGUI("DPanel", panel, "PanelIn")
	name_backgroud:Dock(TOP)
	name_backgroud:SetTall(30)
	name_backgroud:DockMargin(15, 5, 15, 5)
	name_backgroud:DockPadding(10, 0, 10, 0)

	local edit_button = self:CreateVGUI("DButton", name_backgroud, "ColumnEditButton")
	edit_button.DoClick = function(but)
		self:Send().EmitSound()
		self:EditServerName()
	end

	local name_label = self:CreateVGUI("DLabel", name_backgroud, "Label")
	name_label:SetText("")
	name_label:Dock(FILL)
	name_label:DockMargin(0, 5, 10, 5)
	self.name_label = name_label

	self:CreateVGUI("DPanel", panel, "SeparatorIn")

	local svpassword_label = self:CreateVGUI("DLabel", panel, "Title")
	svpassword_label:SetText(tr"password")
	svpassword_label:Dock(TOP)
	svpassword_label:DockMargin(15, 5, 15, 8)

	local password_backgroud = self:CreateVGUI("DPanel", panel, "PanelIn")
	password_backgroud:Dock(TOP)
	password_backgroud:SetTall(30)
	password_backgroud:DockMargin(15, 5, 15, 5)
	password_backgroud:DockPadding(10, 0, 10, 0)

	local edit_button = self:CreateVGUI("DButton", password_backgroud, "ColumnEditButton")
	edit_button.DoClick = function(but)
		self:Send().EmitSound()
		self:ChangeServerPassword()
	end

	local password_label = self:CreateVGUI("DLabel", password_backgroud, "Label")
	password_label:SetText("")
	password_label:Dock(FILL)
	password_label:DockMargin(0, 5, 10, 5)
	self.password_label = password_label

	self:CreateVGUI("DPanel", panel, "SeparatorIn")

	local server_message_label = self:CreateVGUI("DLabel", panel, "Title")
	server_message_label:SetText(tr"server_message")
	server_message_label:Dock(TOP)
	server_message_label:DockMargin(15, 5, 15, 8)
	server_message_label:SetFont("Cash_Register_Big")

	local message_backgroud = self:CreateVGUI("DSizeToContents", panel, "PanelIn")
	message_backgroud:SetSizeX(false)
	message_backgroud:Dock(TOP)
	message_backgroud:SetTall(30)
	message_backgroud:DockMargin(15, 5, 15, 0)
	message_backgroud:InvalidateLayout()
	message_backgroud:DockPadding(0, 0, 0, 10)

	local message_label = self:CreateVGUI("DLabel", message_backgroud, "Label")
	message_label:SetAutoStretchVertical(true)
	message_label:SetText("")
	message_label:Dock(TOP)
	message_label:DockMargin(10, 10, 10, 0)
	self.message_label = message_label

	local edit_button = self:CreateVGUI("DButton", panel, "Button")
	edit_button:Dock(TOP)
	edit_button:DockMargin(15, 10, 15, 5)
	edit_button:SetTall(30)
	edit_button:SetText(tr("edit_server_message"))
	edit_button.DoClick = function()
		self:Send().EmitSound()
		self:EditServerMessage()
	end

	self:CreateVGUI("DPanel", panel, "SeparatorIn")

	local connection_description = self:CreateVGUI("DLabel", panel, "Label")
	connection_description:SetFont("Cash_Register_BasicSmall")
	connection_description:Dock(TOP)
	connection_description:DockMargin(15, 5, 15, 5)
	connection_description:SetAutoStretchVertical(true)
	connection_description:SetWrap(true)
	connection_description:SetText(tr"info.link_description")

	local connection_button = self:CreateVGUI("DButton", panel, "Button")
	connection_button:Dock(TOP)
	connection_button:DockMargin(15, 5, 15, 0)
	connection_button:SetTall(30)
	connection_button:SetText(tr"connect_cash_register")
	connection_button.DoClick = function()
		self:Send().EmitSound()
		self:AskServerInfo()
	end

	local desconnect_button = self:CreateVGUI("DButton", panel, "Button")
	desconnect_button:Dock(TOP)
	desconnect_button:DockMargin(15, 5, 15, 0)
	desconnect_button:SetTall(30)
	desconnect_button:SetText(tr"disconnect_cash_register")
	desconnect_button:SetVisible(false)
	desconnect_button.DoClick = function()
		self:Send().EmitSound()
		self:Send().DisconnectServer()
	end
	self.desconnect_button = desconnect_button
end

function Server:GetServerInfo(data)
	local info = util.JSONToTable(data)

	self.name_label:SetText(info.name)
	self.server_name = info.name

	self.password_label:SetText(info.password or tr"no_password_private")
	self.server_password = info.password or ""

	self.message_label:SetText(info.message or tr"no_server_message")
	self.server_message = info.message or ""

	self.desconnect_button:SetVisible(not info.lan)
end

function Server:ChangeServerPassword()
	self:Screen():CustomPopup(tr"info.change_server_password", function(panel, box)
		local password_label = self:CreateVGUI("DLabel", box, "Label")
		password_label:Dock(TOP)
		password_label:DockMargin(0, 0, 0, 2)
		password_label:SetText(tr"password")

		local password_entry = self:CreateVGUI("DTextEntry", box, "TextEntry")
		password_entry:Dock(TOP)
		password_entry:DockMargin(0, 0, 0, 10)
		password_entry:SetText(self.server_password)
		password_entry:SetFont("Cash_Register_Basic")

		return {
			{tr"make_private", function()
				self:Send().MakeServerPrivate()
			end},
			"_",
			{tr"accept", function()
				self:Send().ChangerServerPassword(password_entry:GetValue())
			end},
			{tr"close"}
		}
	end)
end

function Server:AskServerInfo()
	self:Screen():CustomPopup(tr"linking", function(panel, box)
		local description_label = self:CreateVGUI("DLabel", box, "Label")
		description_label:SetAutoStretchVertical(true)
		description_label:SetWrap(true)
		description_label:SetText(tr"info.linking_description")
		description_label:Dock(TOP)
		description_label:DockMargin(0, 0, 0, 10)

		self:CreateVGUI("DPanel", box, "SeparatorIn"):DockMargin(0, 0, 0, 10)

		local name_label = self:CreateVGUI("DLabel", box, "Label")
		name_label:Dock(TOP)
		name_label:DockMargin(0, 0, 0, 2)
		name_label:SetText(tr"server_name")

		local name_entry = self:CreateVGUI("DTextEntry", box, "TextEntry")
		name_entry:Dock(TOP)
		name_entry:DockMargin(0, 0, 0, 10)
		name_entry:SetText("")

		local password_label = self:CreateVGUI("DLabel", box, "Label")
		password_label:Dock(TOP)
		password_label:DockMargin(0, 0, 0, 2)
		password_label:SetText(tr"password")

		local password_entry = self:CreateVGUI("DTextEntry", box, "TextEntry")
		password_entry:Dock(TOP)
		password_entry:DockMargin(0, 0, 0, 10)
		password_entry:SetText("")

		return {
			{tr"close"},
			{tr"add", function()
				self:Send().ConnectServer(name_entry:GetValue(), password_entry:GetValue())
			end}
		}
	end)
end

function Server:EditServerName()
	self:Screen():CustomPopup(tr"info.change_server_name", function(panel, box)
		local name_label = self:CreateVGUI("DLabel", box, "Label")
		name_label:Dock(TOP)
		name_label:DockMargin(0, 0, 0, 2)
		name_label:SetText(tr"name")

		local name_entry = self:CreateVGUI("DTextEntry", box, "TextEntry")
		name_entry:Dock(TOP)
		name_entry:DockMargin(0, 0, 0, 10)
		name_entry:SetText(self.server_name)
		name_entry:SetFont("Cash_Register_Basic")

		return {{tr"close"},
		{tr"accept", function()
			self:Send().EditServerName(name_entry:GetValue())
		end}}
	end)
end

function Server:EditServerMessage()
	self:Screen():CustomPopup(tr"info.change_server_message", function(panel, box)
		local message_label = self:CreateVGUI("DLabel", box, "Label")
		message_label:Dock(TOP)
		message_label:DockMargin(0, 0, 0, 2)
		message_label:SetText(tr"message")

		local message_entry = self:CreateVGUI("DTextEntry", box, "TextEntry")
		message_entry:Dock(TOP)
		message_entry:DockMargin(0, 0, 0, 10)
		message_entry:SetText(self.server_message)
		message_entry:SetFont("Cash_Register_Basic")
		message_entry:SetMultiline(true)
		message_entry:SetTall(75)

		return {
			{tr"close"},
			{tr"accept", function()
				self:Send().EditServerMessage(message_entry:GetValue())
			end}
		}
	end)
end

function Server:Open()
	self:Send().NeededInfo("server")
	self:Send().GetServerInfo()
end


Option:RegisterTab(Server)
