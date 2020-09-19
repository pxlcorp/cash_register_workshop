local Group = PxlCashRegister.NewClass("Group")

local Util = PxlCashRegister.Util

function Group:Construct(server, group)
    local id = server:NewIndex()
    server.items[id] = self

    self.server = server
    self.id = id
    self.ents = group
    self.name =  "Group #" .. id
    self.cost = 100
    self.cash_register = nil

    for _, ent in pairs(group) do
        ent.CRSItem = self
    end
end

function Group:Name()
    return self.name
end

function Group:Cost()
    return self.cost
end

function Group:Model()
    return nil
end

function Group:GroupID()
    return nil
end

function Group:Server()
    return self.server
end

function Group:Sell(cutomer)
    Util.ChangeOwnership(self.ents, cutomer)
    self:Remove()
end

function Group:Edit(name, cost)
    self.name = name
    self.cost = cost
end

function Group:Remove()
    self:Server():OnItemRemove(self)

    if self.cash_register then
        self.cash_register:RemoveItem(self)
    end

    for _, ent in pairs(self.ents) do
        ent.CRSItem = nil
    end
end