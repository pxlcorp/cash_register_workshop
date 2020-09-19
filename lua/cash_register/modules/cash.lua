local tr = PxlCashRegister.Language.GetDictionary("main")
local Modules = PxlCashRegister.Modules

if SERVER then
	Modules.Payments.Cash = {
		Name = "cash",
		Type = "cash",
		Pay = function(self, ply, amount, info, callback)
			if not ply:canAfford(amount) and amount > 0 then
				callback("you_not_enough_money")
				return
			end

			local succ, err = info.dont_pay_machine or self:AddCash(amount)

			if succ then
				ply:addMoney(-amount)

				callback()
			elseif err then
				callback(err)
			end
		end
	}

	Modules.Transfers.Cash = {
		Name = "cash",
		Type = "cash",
		Transfer = function(self, ply, amount, info, callback)
			if self:GetCash() >= amount then
				local succ, err = self:AddCash(-amount)

				if succ then
					ply:addMoney(amount)

					callback()
				elseif err then
					callback(err)
				end
			else
				callback("not_enough_money")
			end
		end
	}
end
