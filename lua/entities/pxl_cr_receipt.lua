AddCSLuaFile()
DEFINE_BASECLASS("base_anim")

ENT.Spawnable = false
ENT.PxlDisableRegister	= true

cleanup.Register("PxlReceipt")

local _BLACK = Color(70, 70, 70)
local _FONT = "Cash_Register_Receipt"

if SERVER then
	util.AddNetworkString("CashRegister_Receipt")
	util.AddNetworkString("CashRegister_Receipt_Destroy")

	function ENT:SetInfo(info)
		self.info = info
		self:SendInfo()
	end

	function ENT:SendInfo(ply)
		ply = ply or player.GetAll()

		net.Start("CashRegister_Receipt")
			net.WriteEntity(self)
			net.WriteString(util.TableToJSON(self.info))
		net.Send(ply)
	end

	net.Receive("CashRegister_Receipt", function(_, ply)
		local ent = net.ReadEntity()

		if IsValid(ent) then
			if not ent.info then return end

			ent:SendInfo(ply)
		end
	end)

	net.Receive("CashRegister_Receipt_Destroy", function(_, ply)
		local ent = net.ReadEntity()
		if ply.SID ~= ent.SID then return end

		if IsValid(ent) and ent:GetClass() == "pxl_cr_receipt" then
			ent:Remove()
		end
	end)
else
	surface.CreateFont("Cash_Register_Receipt",       	{font = "Courier New", weight = 500, size = 16})
	surface.CreateFont("Cash_Register_Receipt_Medium",	{font = "Courier New", weight = 500, size = 24})
	surface.CreateFont("Cash_Register_Receipt_Large", 	{font = "Courier New", weight = 800, size = 32})

	local tr = PxlCashRegister.Language.GetDictionary("main")

	function ENT:BeingLookedAtByLocalPlayer(distance)
		distance = distance or 256
		if LocalPlayer():GetEyeTrace().Entity ~= self then return false end
		if LocalPlayer():GetViewEntity() == LocalPlayer() and LocalPlayer():GetShootPos():Distance(self:GetPos()) > distance then return false end
		if LocalPlayer():GetViewEntity() ~= LocalPlayer() and LocalPlayer():GetViewEntity():GetPos():Distance(self:GetPos()) > distance then return false end

		return true
	end

	function ENT:AddText(text, font, color, margin)
		font = font or _FONT
		color = color or _BLACK
		margin = margin or 0

		surface.SetFont(font)
		local x, y = surface.GetTextSize(text)

		table.insert(self.texts, {text, font, color, self.size.y + margin})

		self.size.x = math.max(x, self.size.x)
		self.size.y = self.size.y + y + margin
	end

	function ENT:UpdateInfo()
		local wide = 30
		local margin = 1
		local spacing = 2

		self.texts = {}
		self.size = {x = 0, y = 0}

		local i = self.info

		self:AddText(i.server_name, "Cash_Register_Receipt_Large")

		local date = os.date("%Y/%m/%d - %H:%M:%S", i.time)
		self:AddText(date .. string.rep(" ", wide - #date), nil, nil, 10)

		local sid = tostring(i.cash_register_id)
		local tid = tostring(i.__id)
		local idraw = "Post #" .. string.rep("0", 4 - #sid) .. sid .. " - Trs #" .. string.rep("0", 6 - #tid) .. tid
		self:AddText(idraw .. string.rep(" ", wide - #idraw))

		self:AddText(string.rep("-", wide))

		for _, item in pairs(i.items) do
			local cost = tr("$", item.cost)
			local name = (#item.name > wide - #cost - margin*2 - spacing) and (string.sub(item.name, 0, wide - #cost - 3 - margin*2 - spacing)) .. "..." or item.name

			self:AddText(name .. string.rep(" ", wide - margin*2 - #name - #cost) .. cost)
		end

		self:AddText(string.rep("-", wide))

		self:AddText("Total: " .. tr("$", i.price), "Cash_Register_Receipt_Medium")

		self:AddText(tr("paid_with", i.mod))

		if i.more then
			self:AddText(tr(unpack(i.more)))
		end

		local name = tr("sold_by", i.operator)
		local cutname = (#name > wide) and (string.sub(name, 0, wide - 3) .. "...") or name
		self:AddText(cutname)

		if i.message then
			self:AddText(string.rep("-", wide))
			local lines = string.Explode("\n", i.message)

			for _,line in pairs(lines) do
				self:AddText(line)
			end
		end
	end

	net.Receive("CashRegister_Receipt", function()
		local ent = net.ReadEntity()

		if IsValid(ent) and ent.UpdateInfo then
			ent.info = util.JSONToTable(net.ReadString())

			ent:UpdateInfo()
		end
	end)

	net.Receive("CashRegister_Receipt_Destroy", function()
		local ent = net.ReadEntity()

		if IsValid(ent) then
			PxlCashRegister.Popup(tr("receipt_id", ent.info.__id), tr"would_you_destroy_this_receipt",
				{tr"no"},
				{tr"yes", function()
					net.Start("CashRegister_Receipt_Destroy")
						net.WriteEntity(ent)
					net.SendToServer()
				end})
		end
	end)
end

function ENT:SetupDataTables()
	self:NetworkVar("Entity", 1, "owning_ent")
end

function ENT:Initialize()
	if SERVER then
		self:SetModel("models/pxl/paper_bill/facture_papier_pxl_ref.mdl")
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
	else
		net.Start("CashRegister_Receipt")
			net.WriteEntity(self)
		net.SendToServer()

		self.texts = {}
		self.size = {x = 0, y = 0}
	end
end

function ENT:DrawReceiptOverlay()
	local pos = self:GetPos():ToScreen()

	local distance = 24
	local border = 1

	local padding = 10

	local size = {
		x = self.size.x + padding*2,
		y = self.size.y + padding*2
	}

	if #self.texts > 0 then
		local epos = {
			x = pos.x - size.x - distance,
			y = pos.y - size.y - distance
		}

		draw.RoundedBox(0, epos.x - border, epos.y - border, size.x + border*2, size.y + border*2, _BLACK)
		draw.RoundedBox(4, epos.x, epos.y, size.x, size.y, Color(235,235,225))

		for _, text in pairs(self.texts) do
			draw.SimpleText(text[1], text[2], epos.x + size.x/2, epos.y + text[4] + padding, text[3], TEXT_ALIGN_CENTER)
		end
	end
end

function ENT:Use(ply)
	if ply.SID ~= self.SID then return end

	net.Start("CashRegister_Receipt_Destroy")
		net.WriteEntity(self)
	net.Send(ply)
end

hook.Add("HUDPaint", "CashRegister_Receipt", function()
	local ent = LocalPlayer():GetEyeTrace().Entity

	if IsValid(ent) and ent.BeingLookedAtByLocalPlayer and ent:BeingLookedAtByLocalPlayer(75) and ent.DrawReceiptOverlay then
		ent:DrawReceiptOverlay()
	end
end)
