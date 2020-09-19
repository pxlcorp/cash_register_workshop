
surface.CreateFont("Cash_Register_Basic", {
	font = "Arial",
	size = 17,
	weight = 800,
})

surface.CreateFont("Cash_Register_Menu", {
	font = "Arial",
	size = 17,
	weight = 500,
})

surface.CreateFont("Cash_Register_Title", {
	font = "Arial",
	size = 23,
	weight = 800,
})

surface.CreateFont("Cash_Register_Price", {
	font = "Arial",
	size = 30,
	weight = 500,
})

surface.CreateFont("Cash_Register_Button", {
	font = "Arial",
	size = 20,
	weight = 800,
})

surface.CreateFont("Cash_Register_Big", {
	font = "Arial",
	size = 30,
	weight = 800,
})

PxlCashRegister.popups = {}

function PxlCashRegister.Popup(title, text, ...)
	local args = {...}
	local popup = {}
	local id = table.insert(PxlCashRegister.popups, popup)

	local frame = vgui.Create("DFrame")
	frame:MakePopup()
	frame:SetBackgroundBlur(true)
	frame:InvalidateLayout()
	frame:ShowCloseButton(false)
	frame:SetDraggable(false)
	frame:SetWide(210)
	frame:SetTitle(title)

	local panel = vgui.Create("DSizeToContents", frame)
	panel:SetSizeX(false)
	panel:InvalidateLayout()
	panel:Dock(FILL)
	panel:SetWide(200)
	panel.PerformLayout = function()
		panel:SizeToChildren(panel.m_bSizeX, panel.m_bSizeY)
		frame:SizeToChildren(false, true)

		frame:CenterHorizontal()
		frame:CenterVertical(0.4)
	end

	local textbox = vgui.Create("DSizeToContents", panel)
	textbox:Dock(TOP)
	textbox:SetSizeX(false)
	textbox:InvalidateLayout()
	textbox:DockMargin(1, 1, 1, 3)
	textbox:DockPadding(5, 5, 5, 5)
	textbox.Paint = function(self, x, y)
		draw.RoundedBox(4, 0, 0, x, y, Color(225, 225, 225))
	end

	local label = vgui.Create("DLabel", textbox)
	label:SetAutoStretchVertical(true)
	label:SetWrap(true)
	label:SetText(text)
	label:SetTextColor(Color(75, 75, 75))
	label:Dock(TOP)

	if #args == 0 then
		args[1] = {PxlCashRegister.Language.Translate("main", "close")}
	end

	if #args == 2 then
		local div = vgui.Create("DPanel", panel)
		div:Dock(TOP)
		div:DockMargin(0, 2, 0, 0)
		div:SetTall(25)
		div.Paint = nil

		local but1 = vgui.Create("DButton", div)
		but1:Dock(LEFT)
		but1:SetWide((200-2)/2)
		but1:SetText(args[1][1])
		but1.DoClick = function()
			if args[1][2] then args[1][2]() end
			PxlCashRegister.RemovePopup(id)
		end

		local but2 = vgui.Create("DButton", div)
		but2:Dock(RIGHT)
		but2:SetWide((200-2)/2)
		but2:SetText(args[2][1])
		but2.DoClick = function()
			if args[2][2] then args[2][2]() end
			PxlCashRegister.RemovePopup(id)
		end
	else
		for _, par in pairs(args) do
			if par then
				local but = vgui.Create("DButton", panel)
				but:Dock(TOP)
				but:DockMargin(0, 2, 0, 0)
				but:SetTall(25)
				but:SetText(par[1])
				but.DoClick = function()
					if par[2] then par[2]() end
					PxlCashRegister.RemovePopup(id)
				end
			end
		end
	end

	popup.panel = frame

	return id
end

function PxlCashRegister.RemovePopup(id)
	local popup = table.remove(PxlCashRegister.popups, id)
	popup.panel:Remove()
end

function PxlCashRegister.ClearPopup()
	for id, _ in pairs(PxlCashRegister.popups) do
		PxlCashRegister.RemovePopup(id)
	end
end
