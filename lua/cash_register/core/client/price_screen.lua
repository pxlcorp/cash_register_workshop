local PScreen = PxlCashRegister.NewClass("PScreen")
PScreen:InitNet("CashRegister_PriceScreen")

surface.CreateFont("DSEG14", {font = "DSEG14 Classic", weight = 800, size = 64, italic = true})

local margin = 8

function PScreen:Construct(ent, id, pos, ang, width, height, count)
	self:SetID(id)

	self.parent	= ent
	self.pos   	= pos
	self.ang   	= ang
	self.width 	= width
	self.height	= height
	self.price 	= "0"
	self.count 	= count

	surface.SetFont("DSEG14")
	self.tw, self.th = surface.GetTextSize(string.rep("0", self.count))

	self.scale = self.width/(self.tw+margin*2)
end

function PScreen:Draw()
	local pos = self.parent:LocalToWorld(self.pos)
	local ang = self.parent:LocalToWorldAngles(self.ang)

	cam.Start3D2D(pos, ang, self.scale)
		draw.RoundedBox(0, 0, 0, self.width/self.scale, self.height/self.scale, Color(50,86,72))
		draw.SimpleText(string.rep("~", self.count), "DSEG14", margin, (self.height/self.scale-self.th)/2, Color(55,94,78))

		draw.SimpleText(self.price, "DSEG14", self.width/self.scale - margin, (self.height/self.scale-self.th)/2, Color(124,211,175), TEXT_ALIGN_RIGHT)
	cam.End3D2D()
end

function PScreen:SetPrice(price)
	if math.ceil(math.log10(price)) > self.count then
		local p = math.ceil(math.log10(price))-1
		self.price = math.Round(price/10^p, self.count - math.ceil(math.log10(p+1)) - 3) .. "e+" .. (p)
	else
		self.price = tostring(price)
	end 
end