PxlCashRegister.Server = PxlCashRegister.NewClass("Server")
local Server = PxlCashRegister.Server
Server.Logs = {}

local Util = PxlCashRegister.Util


--[[---------------------------------------------------------
	Server Object
-----------------------------------------------------------]]

	function Server.GetByName(name)
		for _, server in pairs(Server:GetAll()) do
			if server:Name() == name then
				return server
			end
		end
	end

	function Server.GetByPersistID(id)
		for _, server in pairs(Server:GetAll()) do
			if server.persistid == id then
				return server
			end
		end
	end

	function Server:Construct(cash_register)
		self:Push()

		self.name = "Server #" .. self:GetID()

		self.items = {}
		self.groups = {}
		self.idxcount = 0

		self.logs = {}
		self.receipts = {}

		self.persistmod = false

		self.owner = nil
		self.players = {}
		self.invitedplayers = {}

		self.lan = false
		self.cash_registers = {}
		self.password = nil

		self.credit = 0

		self.accessories = {}

		self.permission = {
			money = true,
			option = true,
			items = true,
		}

		if cash_register then
			self:AddCashRegister(cash_register)
		end
	end

	function Server:IsPersistMod()
		return self.persistmod
	end

	function Server:DeleteAll()
		for _, accessory in pairs(self.accessories) do
			accessory:Remove()
		end

		for _, cash_register in pairs(self.cash_registers) do
			cash_register:DeleteAll()
		end

		for _, ent in pairs(self.persistents or {}) do
			if IsValid(ent) then
				ent:Remove()
			end
		end

		self:Remove()
	end

	function Server:OnRemove()
		self:Clear()
	end


	--[[----------------------------------------------------------
	-	Server info												]]

		function Server:SetName(name, persist)
			if name == self:Name() then return end

			if string.sub(name, 0, 8) == "Server #" then
				return "server_name_cant_start_by", "Server #"
			end

			if Server.GetByName(name) then
				return "this_name_is_already_used"
			end

			if not persist then
				for id, info in pairs(PxlCashRegister.Persist.Data) do
					if name == info.name then
						return "this_name_is_already_used"
					end
				end
			end

			self.name = name

			self:NeededInfo("server", function(cash_register, ply)
				cash_register:SendServerInfo(ply)
			end)
		end

		function Server:Name()
			return self.name
		end

		function Server:SetMessage(message)
			self.message = message

			self:NeededInfo("server", function(cash_register, ply)
				cash_register:SendServerInfo(ply)
			end)
		end

		function Server:Message()
			return self.message
		end

		function Server:SetPassword(pwd)
			if pwd == self.password then
				return
			end

			self.password = pwd

			self:NeededInfo("server", function(cash_register, ply)
				cash_register:SendServerInfo(ply)
			end)
		end

		function Server:CheckPassword(pwd)
			if not self.password then return false end

			return self.password == pwd
		end


	--[[----------------------------------------------------------
	-	Items Management										]]

		function Server:NewIndex()
			self.idxcount = self.idxcount + 1
			return self.idxcount
		end

		function Server:HasAccess(ent)
			if not IsValid(ent) then return end

			local ply = ent:CPPIGetOwner()
			if not isentity(ply) or not IsValid(ply) then
				if ent.Getowning_ent then
					ply = ent:Getowning_ent()
				else
					return true
				end
			end

			return self:IsAllowed(ply)
		end

		local blockedEnts = {
			["func_breakable_surf"] = true,
			["prop_door_rotating"] = true,
			["prop_physics_multiplayer"] = true,
			["func_door_rotating"] = true,
			["func_brush"] = true,
			["func_door"] = true,
			["func_breakable"] = true,
			["func_button"] = true,
			["func_reflective_glass"] = true,
		}

		function Server:AddItem(ent)
			-- if isentity(ent) and ent:IsWorld() then return _, "you_cant_scanne_the_world" end
			if not IsValid(ent) then return _, "invalid_entity" end
			if ent.CRSItem then return ent.CRSItem, "already_registed" end

			local item
			local group = Util.GetAllEntities(ent)

			for _, ent in pairs(group) do
				if blockedEnts[ent:GetClass()] then
					return _, "invalid_entity"
				end

				if ent:GetPersistent() then
					return _, "invalid_entity"
				end

				if ent:IsPlayer() or ent:IsNPC() then
					return _, "invalid_entity"
				end

				if ent.CRSItem then
					return _, "already_registed"
				end

				if ent.PxlDisableRegister then
					return _, "invalid_entity"
				end


				if not self:HasAccess(ent) then
					return _, "no_access"
				end
			end

			if #group == 1 then
				item = PxlCashRegister.New "Item" (self, ent)
			else
				item = PxlCashRegister.New "Group" (self, group)
			end

			self:NeededInfo("server_items", function(cash_register, ply)
				cash_register:Send(ply).AddServerItem({
					id = item.id,
					name = item:Name(), 
					cost = item:Cost(), 
					model = item:Model(),
					groupid = item:GroupID()})
			end)

			return item
		end

		function Server:GetItem(var)
			if isentity(var) and IsValid(var) then
				return ent.CRSItem
			elseif isnumber(var) then
				return self.items[var]
			end
		end

		function Server:OnItemRemove(item)
			self.items[item.id] = nil

			self:NeededInfo("server_items", function(cash_register, ply)
				cash_register:Send(ply).RemoveServerItem(item.id)
			end)
		end

		function Server:RemoveItem(ent)
			local item = self:GetItem(ent)
			if not item then return end

			item:Remove()
		end

		function Server:RemoveItemGroup(id)
			local group = self.groups[id]

			if group then
				if table.Count(group.items) == 0 then
					self.groups[id] = nil

					self:NeededInfo("server_items", function(cash_register, ply)
						cash_register:Send(ply).RemoveServerItemGroup(id)
					end)
				else
					return "error"
				end
			else
				return "error"
			end
		end


		--[[
			Edit the information of an item

			@param id number 	index of the item
			@param name string	the new name
			@param cost number	the new cost
		]]
		function Server:EditItem(id, name, cost)
			local item = self:GetItem(id)

			if item then
				item:Edit(name, cost)

				self:NeededInfo("server_items", function(cash_register, ply)
					cash_register:Send(ply).EditServerItem({
						id = item.id,
						name = item:Name(), 
						cost = item:Cost(), 
						model = item:Model(),
						groupid = item:GroupID()})
				end)
			end
		end

		--[[
			Edit the information of an items group

			@param id string 	index of the items group
			@param name string	the new name
			@param cost number	the new cost
		]]
		function Server:EditItemGroup(id, name, cost)
			local group = self.groups[id]

			group:Edit(name, cost)

			self:NeededInfo("server_items", function(cash_register, ply)
				cash_register:Send(ply).EditServerItemGroup({
					id = group.id,
					name = group.name, 
					cost = group.cost, 
					model = group.model})
			end)
		end

		function Server:Clear()
			for id, itm in pairs(self.items) do
				itm:Remove()
				self.items[id] = nil
			end
		end

	--[[----------------------------------------------------------
	-	Player Management										]]

		function Server:AddPlayer(ply)
			self.players[ply:UniqueID()] = ply:Name()

			self:NeededInfo("access", function(cash_register, ply)
				cash_register:SendAccessOption(ply)
			end)
		end

		function Server:RemovePlayer(uid)
			local uid = isentity(uid) and uid:UniqueID() or uid

			if uid == self.owner then
				return "you_cant_remove_the_owner"
			end

			if self:IsAllowed(uid) then
				self.players[uid] = nil
			elseif self.invitedplayers[uid] then
				self.invitedplayers[uid] = nil
			else
				return
			end

			self:NeededInfo("access", function(cash_register, ply)
				cash_register:SendAccessOption(ply)
			end)
		end

		function Server:IsAllowed(uid)
			local uid = isentity(uid) and uid:UniqueID() or uid

			if uid == self.owner then
				return true
			elseif self.players[uid] then
				return true
			end

			return false
		end


		function Server:InvitatPlayer(ply)
			self.invitedplayers[ply:UniqueID()] = ply:Name()

			self:NeededInfo("access", function(cash_register, ply)
				cash_register:SendAccessOption(ply)
			end)
		end

		function Server:NeededInfo(info, callback)
			for _, cash_register in pairs(self:CashRegisters()) do
				local ply = cash_register:NeededInfo(info)

				callback(cash_register, ply)
			end
		end

		function Server:SetOwner(ply)
			if not self:IsAllowed(ply) then
				self:AddPlayer(ply)
			end

			self.owner = ply:UniqueID()
		end

		function Server:Owner()
			return self.owner
		end

		function Server:ChangePermission(permission, act)
			if self.permission[permission] ~= nil then
				self.permission[permission] = act

				self:NeededInfo("permission", function(cash_register, ply)
					cash_register:SendPermissionInfo(ply)
				end)
			else
				return "non_existing_permission"
			end
		end

		function Server:HasPermission(ply, permission)
			if self.permission[permission] ~= nil then
				if self.permission[permission] or ply:UniqueID() == self.owner then
					return true
				else
					return false, "not_allowed"
				end
			else
				return false, "non_existing_permission"
			end
		end

	--[[----------------------------------------------------------
	-	CashRegisters Management										]]

		function Server:AddCashRegister(cash_register)
			self.cash_registers[cash_register:GetID()] = cash_register
			cash_register.server = self

			self.lan = table.Count(self.cash_registers) == 1

			self:NeededInfo("server", function(cash_register, ply)
				cash_register:SendServerInfo(ply)
			end)
		end

		function Server:RemoveCashRegister(cash_register)
			self.cash_registers[cash_register:GetID()] = nil

			self.lan = table.Count(self.cash_registers) == 1

			if table.Count(self.cash_registers) == 0 then
				self:Remove()
			else
				self:NeededInfo("server", function(cash_register, ply)
					cash_register:SendServerInfo(ply)
				end)
			end
		end

		function Server:CashRegisters()
			local cash_registers = {}

			for id, cash_register in pairs(self.cash_registers) do
				table.insert(cash_registers, cash_register)
			end

			return cash_registers
		end

		function Server:AddCredit(amount)
			if self.credit + amount >= 0 then
				self.credit = self.credit + amount

				self:NeededInfo("money", function(cash_register, ply)
					cash_register:Send(ply).UpdateMoney(cash_register:GetCash(), self:GetCredit())
				end)

				return true
			else
				return false, "not_enough_credit"
			end
		end

		function Server:GetCredit()
			return self.credit
		end

	--[[----------------------------------------------------------
	-	Renting													]]

		function Server:Rent(ply, info)
			self:SetOwner(ply)
			self.rent_info = info

			self:NeededInfo("connect", function(cash_register, ply)
				cash_register:SendConnectInfo(ply)
			end)
		end

		function Server:Sell()
			PxlCashRegister.Persist.LoadServer(self.persistid)
		end

	--[[----------------------------------------------------------
	-	Accessory												]]

		function Server:Accessories()
			return self.accessories or {}
		end

		function Server:AddAccessory(accessory)
			self.accessories[accessory:GetID()] = accessory
			accessory:SetServer(self)

			self:NeededInfo("accessory", function(cash_register, ply)
				cash_register:SendAccessoriesOption(ply)
			end)
		end

		function Server:RemoveAccessory(accessory)
			self.accessories[accessory:GetID()] = nil
			accessory:SetServer(nil)

			self:NeededInfo("accessory", function(cash_register, ply)
				cash_register:SendAccessoriesOption(ply)
			end)
		end

	--[[----------------------------------------------------------
	-	Loging													]]

		function Server:Log(type, log)
			log.__type = type
			log.__time = os.time()

			log.__id = table.insert(self.logs, log)

			self:NeededInfo("log", function(cash_register, ply)
				cash_register:Send(ply).AddLog(log.__id, {
					id = log.__id,
					time = log.__time,
					type = log.__type,
					args = {self:FormatLog(log)}
				})
			end)
		end

		function Server:FormatLog(log)
			if Server.Logs[log.__type] then
				return Server.Logs[log.__type](log)
			else

			end
		end

		Server.Logs.Purchase = function(log)
			return "log_purchase", log.__id, os.date("%Y/%m/%d - %H:%M:%S", log.__time), log.customer, log.price
		end

		Server.Logs.Deposit = function(log)
			return "log_deposit", log.__id, os.date("%Y/%m/%d - %H:%M:%S", log.__time), log.target, log.amount, log.mod
		end

		Server.Logs.Transfer = function(log)
			return "log_transfer", log.__id, os.date("%Y/%m/%d - %H:%M:%S", log.__time), log.target, log.amount, log.mod
		end

		Server.Logs.PasswordChanged = function(log)
			return "log_passwordchanged", log.__id, os.date("%Y/%m/%d - %H:%M:%S", log.__time), log.user_name, log.password_old or "no_password", log.password_new or "no_password"
		end
