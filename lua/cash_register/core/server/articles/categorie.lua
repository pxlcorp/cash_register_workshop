local Category = PxlCashRegister.NewClass("Category")

function Category:Construct(server, class)
    self.id = class
    server.groups[self.id] = self

    self.items = {}
    self.server = server
    self.name =  "#" .. self.id
    self.cost = 100
end

function Category:Edit(name, cost)
    self.name = name
    self.cost = cost
end

function Category:Name()
    return self.name
end

function Category:Cost()
    return self.cost
end

function Category:Model()
    return self.model
end

function Category:OnRemove()
    for _, item in pairs(self.items) do
        item:Remove()
    end

    self:Server().groups[self.id] = nil
end