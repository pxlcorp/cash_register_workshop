local tr = PxlCashRegister.Language.GetDictionary("main")
local Modules = PxlCashRegister.Modules

if not CBLib then return end

local Accounts = CBLib.LoadModule("batm/bm_accounts.lua", false)
if not Accounts then return end

if CLIENT then
	function Modules.Deposit.BlueATM(screen, info, callback)
		callback()
	end

	function Modules.Payments.BlueATM(screen, data, callback)
		callback()
		-- screen:PopupTitle(tr"confirmation", tr("confirmation_text", "blueatm"),
		-- 	{tr"cancel", function()
		-- 		callback(true)
		-- 	end},
		-- 	{tr"accept", function()
		-- 		callback()
		-- 	end})
	end
else
--[[----------------------------------------------------------
-	Payments												]]
	Modules.Payments.BlueATM = {
		Name = "blueatm",
		Type = "credit",
		Pay = function(self, ply, amount, info, callback)
			Accounts.GetCachedPersonalAccount(ply:SteamID64(), function(account, didExist)
				if account.balance - amount >= 0 then
					local succ, err = info.dont_pay_machine or self:AddCredit(amount)

					if succ then
						account:AddBalance(-amount, info.description)
						account:SaveAccount()

						BATM.NetworkAccount(ply, account, false)

						callback()
					elseif err then
						callback(err)
					end
				else
					callback("you_not_enough_money")
				end
			end)
		end
	}

--[[----------------------------------------------------------
-	Transfers												]]


	Modules.Transfers.BlueATM = {
		Name = "blueatm",
		Type = "credit",
		Transfer = function(self, ply, amount, info, callback)
			Accounts.GetCachedPersonalAccount(ply:SteamID64(), function(account, didExist)
				if account.balance + amount >= 0 then
					local succ, err = self:AddCredit(-amount)

					if succ then
						account:AddBalance(amount, info.description)
						account:SaveAccount()

						BATM.NetworkAccount(ply, account, false)

						callback()
					elseif err then
						callback(err)
					end
				else
					callback("you_not_enough_money")
				end
			end)
		end
	}
end
