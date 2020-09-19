local Item = PxlCashRegister.NewClass("Item")

local Util = PxlCashRegister.Util

function Item:Construct(server, ent)
    local id = server:NewIndex()
    self.id = id
    self.cash_register = nil
    self.ent = ent

    local class = ent:GetClass() .. ":" .. Util.NiceModel(ent:GetModel())
    self.group = server.groups[class] or PxlCashRegister.New "Category"(server, class)
    self.group.model = ent:GetModel()

    self.group.items[id] = self
    server.items[id] = self

    ent.CRSItem = self
end

function Item:Name()
    return self.group.name
end

function Item:Cost()
    return self.group.cost
end

function Item:Model()
    return self.ent:GetModel()
end

function Item:GroupID()
    return self.group.id
end

function Item:Server()
    return self.group.server
end

function Item:Sell(cutomer)
    Util.ChangeOwnership({self.ent}, cutomer)
    self:Remove()
end

function Item:Edit(name, cost)
    self.group.name = name
    self.group.cost = cost
end

function Item:OnRemove()
    self:Server():OnItemRemove(self)
    self.group.items[self.id] = nil
    self.ent.CRSItem = nil

    if self.cash_register then
        self.cash_register:RemoveItem(self)
    end
end