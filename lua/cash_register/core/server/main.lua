
hook.Add("EntityRemoved", "PxlCashRegister.Item", function(ent)
	if ent.CRSItem then
		ent.CRSItem:Remove()
	end
end)

hook.Add("PlayerUse", "PxlCashRegister.Item", function(ply, ent)
	if ent.CRSItem then
		return false
	end
end)

hook.Add("PlayerCanPickupWeapon", "PxlCashRegister.Item", function(ply, wep)
	if wep.CRSItem then
		return false
	end
end)

hook.Add("ItemStoreCanPickup", "PxlCashRegister.Item", function(ply, _, ent)
	if ent.CRSItem then
		return false
	end
end)

hook.Add("canPocket", "PxlCashRegister.Item", function(ply, ent)
	if ent.CRSItem then
		return false
	end
end)

hook.Add("PlayerDisconnected", "PxlCashRegister.Persist", function(ply)
	local uid = ply:UniqueID()

	timer.Simple(PxlCashRegister.Config.ResetTime, function()
		for _, server in pairs(PxlCashRegister.Server:GetAll()) do
			if server:IsPersistMod() and uid == server:Owner() then
				if player.GetByUniqueID(uid) then return end
				server:Sell()
			end
		end
	end)
end)


hook.Add("canLockpick", "PxlCashRegister_Item", function(ply, ent, trace)
	if ent.CRSItem and not (ent.CRSItem.cash_register and IsValid(ent.CRSItem.cash_register.customer)) then
		return true
	end
end)

hook.Add("onLockpickCompleted", "PxlCashRegister_Item", function(ply, succ, ent)
	if ent.CRSItem and succ and not (ent.CRSItem.cash_register and IsValid(ent.CRSItem.cash_register.customer)) then
		ent.CRSItem:Remove()
	end
end)
