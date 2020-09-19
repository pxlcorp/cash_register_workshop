local Service = PxlCashRegister.NewClass("Service")

function Service:Construct(cash_register, name, cost)
    self.id = cash_register:Server():NewIndex()
    self.name = name
    self.cost = cost
end

function Service:Name()
    return self.name
end

function Service:Cost()
    return self.cost
end

function Service:Model()
    return nil
end

function Service:GroupID()
    return nil
end

function Service:Sell(cutomer)
end