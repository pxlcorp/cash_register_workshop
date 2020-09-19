PxlCashRegister.Scanner = PxlCashRegister.NewClass("Scanner")
local Scanner = PxlCashRegister.Scanner
Scanner:InitNet("CashRegister_Scanner")

local tr = PxlCashRegister.Language.GetDictionary("main")

function Scanner:Construct(id)
	self:SetID(id)

	self.title      	= self.title or "..."
	self.title_start	= nil
	self.title_p    	= 0

	self.title_wait  	= 2
	self.title_speed 	= 0.5	 -- screen width/sec
	self.title_margin	= 10
	self.title_height	= 0

	self.width	= 152
	self.height = 150

	self.messages        	= {}
	self.message_wait    	= 2
	self.message_margin  	= 2
	self.message_distance	= 3
	self.message_speed   	= 1 -- px/tick
	self.message_start   	= 20
	self.message_life    	= 5

	self:Send().GetTitle()
end

function Scanner:SetTitle(...)
	if #{...} ~= 0 then
		self.title = tr(...)
	else
		self.title = "..."
	end

	surface.SetFont("Cash_Register_Title")
	local tw, th = surface.GetTextSize(self.title)

	if tw > self.width - self.title_margin then
		self.title_start = CurTime()
	else
		self.title_start = nil
	end
end

function Scanner:MoveMessage(msg, pos)
	msg.pos = msg.pos + math.Clamp(pos - msg.pos, 0, self.message_speed)
end

function Scanner:DrawScreen(pos, ang, scale)
	cam.Start3D2D(pos, ang, scale)
		render.ClearStencil()
		render.SetStencilEnable(true)
			render.SetStencilWriteMask(15)
			render.SetStencilTestMask(15)
			render.SetStencilReferenceValue(15)
			render.SetStencilFailOperation(STENCILOPERATION_ZERO)
			render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
			render.SetStencilZFailOperation(STENCILOPERATION_KEEP)

			render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
			render.SetBlend(0)

				surface.SetDrawColor(Color(255, 255, 255))
				surface.SetMaterial(Material("pxl/vgui/scanner_backgroud.png"))
				surface.DrawTexturedRect(0, 0, self.width, self.height)

			render.SetBlend(1)
			render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)

				surface.SetFont("Cash_Register_Title")
				local tw, th = surface.GetTextSize(self.title)

				for i, msg in pairs(self.messages) do
					surface.SetFont("Cash_Register_Menu")
					local mw, mh = surface.GetTextSize(msg.text)

					if true then -- msg.created + self.message_life > CurTime() then
						if i == 1 then
							self:MoveMessage(msg, self.title_height + th + self.title_margin*2 + self.message_distance)
						else
							self:MoveMessage(msg, self.messages[i-1].pos + mh + self.message_margin*2 + self.message_distance)
						end
					else
						self:MoveMessage(msg, self.height)
					end

					if msg.pos >= self.height then
						table.remove(self.messages, i)
					end

					draw.RoundedBox(0, 0, msg.pos, self.width, mh + self.message_margin*2, Color(25, 25, 25, 125))


					if msg.start and msg.start + self.message_wait < CurTime() then
						local time = (CurTime() - (msg.start + self.message_wait))*self.width*self.title_speed
						local p1 = self.title_margin - time
						local p2 = math.max(self.title_margin + mw + self.width/4 - time, self.title_margin)

						if p2 == self.title_margin then
							msg.start = CurTime()
						end

						draw.DrawText(msg.text, "Cash_Register_Menu", p1, msg.pos + self.message_margin, Color( 255, 255, 255, 255 ))
						draw.DrawText(msg.text, "Cash_Register_Menu", p2, msg.pos + self.message_margin, Color( 255, 255, 255, 255 ))
					else
						draw.DrawText(msg.text, "Cash_Register_Menu", self.title_margin, msg.pos + self.message_margin, Color( 255, 255, 255, 255 ))
					end
				end

				draw.RoundedBox(0, 0, self.title_height, self.width, th + self.title_margin*2, Color(25, 25, 25, 125))

				if self.title_start and self.title_start + self.title_wait < CurTime() then
					local time = (CurTime() - (self.title_start + self.title_wait))*self.width*self.title_speed
					local p1 = self.title_margin - time
					local p2 = math.max(self.title_margin + tw + self.width/4 - time, self.title_margin)

					if p2 == self.title_margin then
						self.title_start = CurTime()
					end

					draw.DrawText(self.title, "Cash_Register_Title", p1, self.title_height + self.title_margin, Color( 255, 255, 255, 255 ))
					draw.DrawText(self.title, "Cash_Register_Title", p2, self.title_height + self.title_margin, Color( 255, 255, 255, 255 ))
				else
					draw.DrawText(self.title, "Cash_Register_Title", self.title_margin, self.title_height + self.title_margin, Color( 255, 255, 255, 255 ))
				end

		render.SetStencilEnable(false)
		render.ClearStencil()
	cam.End3D2D()
end

function Scanner:Message(...)
	local text = tr(...)

	surface.SetFont("Cash_Register_Menu")
	local tw, th = surface.GetTextSize(text)

    local message = {
		text = text,
		created = CurTime(),
		start = (tw + self.title_margin > self.width) and CurTime() or nil,
		pos = self.message_start
    }

    table.insert(self.messages, 1, message)
end
