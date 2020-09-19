local tr = PxlCashRegister.Language.GetDictionary("main")
local Modules = PxlCashRegister.Modules


if ARCBank then
	if CLIENT then
		function Modules.Deposit.ARCBank(screen, info, callback)
			local acc = {}

			if isstring(info.More) then
				callback(info.More)
			else
				for _, group in pairs(info.More) do
					table.insert(acc, {group, function()
						callback(nil, {group = group})
					end})
				end

				table.insert(acc, "_")
				table.insert(acc, {tr"cancel", function()
					callback(true)
				end})
				table.insert(acc, false)

				screen:Popup(tr"arcbank_chose_account",
				{tr"arcbank_personal_account", function()
					callback()
				end
				}, unpack(acc))
			end
		end

		Modules.Payments.ARCBank = Modules.Deposit.ARCBank
	else
	--[[----------------------------------------------------------
	-	Payments												]]
		if ARCLib.IsVersion("1.4.0", "ARCBank") then
			Modules.Payments.ARCBank = {
				Name = "arcbank",
				Type = "credit",
				Pay = function(self, ply, amount, info, callback)
					local group = info.group or ""

					ARCBank.AddMoney(ply, group, -amount, ARCBANK_TRANSACTION_TRANSFER, info.description or "", function(err)
						if err == 0 then
							local override = callback(nil, {"with_account", group~="" and group or "personal"})

							if override ~= false and not info.dont_pay_machine then
								self:AddCredit(amount)
							end
						else
							callback(PxlCashRegister.Config.ARCBankErrorEnum[err])
						end
					end)
				end,
				ToCostomer = function(self, ply, callback)
					ARCBank.GetAccessableAccounts(ply, function(err, list)
						if not list or #list == 0 then
							callback(nil, "arcbank_you_dont_have_account")
							return
						end

						if err == 0 then
							local accounts = {}
							local accounts_count = #list
							local function add_account(name)
								table.insert(accounts, name)

								if #accounts == accounts_count then
									callback(nil, accounts)
								end
							end

							for _, id in pairs(list) do
								ARCBank.GetAccountName(id, function(err, name)
									if err == 0 then
										if string.sub(id, 0, 1) == "_" then
											accounts_count = accounts_count - 1

											if accounts_count == 0 then
												callback(nil, {})
											end
										else
											add_account(name)
										end
									else
										callback(err, nil)
										return
									end
								end)
							end
						else
							callback(PxlCashRegister.Config.ARCBankErrorEnum[err])
						end
					end)
				end
			}
		elseif ARCLib.IsVersion("1.3.0", "ARCBank") then
			Modules.Payments.ARCBank = {
				Name = "arcbank",
				Type = "credit",
				Pay = function(self, ply, amount, info, callback)
					local group = info.group or ""

					ARCBank.AddMoney(ply, -amount, group, info.description or "", function(err)
						if err == 0 then
							local override = callback(nil, {"with_account", group~="" and group or "personal"})

							if override ~= false then
								self:AddCredit(amount)
							end
						else
							callback(PxlCashRegister.Config.ARCBankErrorEnum[err])
						end
					end)
				end,
				ToCostomer = function(self, ply, callback)
					ARCBank.GroupAccountAcces(ply, function(err, groups)
						if err == 0 then
							callback(nil, groups)
						else
							callback(PxlCashRegister.Config.ARCBankErrorEnum[err])
						end
					end)
				end
			}
		end

	--[[----------------------------------------------------------
	-	Transfers												]]


		if ARCLib.IsVersion("1.4.0", "ARCBank") then
			Modules.Transfers.ARCBank = {
				Name = "arcbank",
				Type = "credit",
				Transfer = function(self, ply, amount, info, callback)
					local group = info.group or ""

					ARCBank.AddMoney(ply, group, amount, ARCBANK_TRANSACTION_TRANSFER, info.description or "", function(err)
						if err == 0 then
							self:AddCredit(-amount)
							callback()
						else
							callback(PxlCashRegister.Config.ARCBankErrorEnum[err])
						end
					end)
				end
			}
		elseif ARCLib.IsVersion("1.3.0", "ARCBank") then
			Modules.Transfers.ARCBank = {
				Name = "arcbank",
				Type = "credit",
				Transfer = function(self, ply, amount, info, callback)
					local group = info.group or ""

					ARCBank.AddMoney(ply, amount, group, info.description or "", function(err)
						if err == 0 then
							self:AddCredit(-amount)
							callback()
						else
							callback(PxlCashRegister.Config.ARCBankErrorEnum[err])
						end
					end)
				end
			}
		end
	end
end
