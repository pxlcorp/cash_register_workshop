PxlCashRegister.CashRegister = PxlCashRegister.NewClass("CashRegister")
local CashRegister = PxlCashRegister.CashRegister
CashRegister:InitNet("CashRegister_UserScreen")
CashRegister:AddNet("Customer", "CashRegister_CustomerScreen")
CashRegister:AddNet("Price", "CashRegister_PriceScreen")

local tr = PxlCashRegister.Language.GetDictionary("main")

local function defbool(v, d) if v == nil or not isbool(v) then return d end return v end


--[[---------------------------------------------------------
	CashRegister Object
-----------------------------------------------------------]]

	function CashRegister:Construct(ent)
		self:Push()

		self.cash = 0
		self.accessories = {}
		self.parent = ent
		self.items = {}
		self.users = {}
		self.listening_customer = {}
		self.cutomer = NULL
		self.iswaitingforcustomer = false
		self.isfindingscanner = false
		self.hasbeenstole = false
		self.iswaitingtoprintreceipt = false

		self.neededinfo = {}
	end

	function CashRegister:DeleteAll()
		for _, accessory in pairs(self.accessories) do
			accessory:Remove()
		end

		self:Remove()
	end

	function CashRegister:Server()
		if not self.server then
			self.server = PxlCashRegister.New "Server" (self)

			local ply = self.parent:CPPIGetOwner()

			if not IsValid(ply) then
				ply = self.parent:Getowning_ent()
			end

			if IsValid(ply) then
				self.server:SetOwner(ply)
			end
		end

		return self.server
	end

	function CashRegister:Users()
		local users = {}
		for ply,valid in pairs(self.users) do
			if valid then
				if IsValid(ply) then
					table.insert(users, ply)
				else
					self.users[ply] = nil
				end
			end
		end

		return users
	end

	function CashRegister:Customers()
		local customers = {}
		for ply, is_listening in pairs(self.listening_customer) do
			if IsValid(ply) then
				table.insert(customers, ply)
			else
				self.listening_customer[ply] = nil
			end
		end

		return customers
	end

	function CashRegister:NeededInfo(info)
		local plys = {}

		for ply, ply_info in pairs(self.neededinfo) do
			if IsValid(ply) then
				for _, v in pairs(ply_info) do
					if v == info then
						table.insert(plys, ply)
					end
				end
			else
				self.neededinfo[ply] = nil
			end
		end

		return plys
	end

	function CashRegister:ConnectServer(name, password)
		local server

		for id, serv in pairs(PxlCashRegister.Get("Server"):GetAll()) do
			if serv:Name() == name then
				server = serv
				break
			end
		end

		if not server then
			return "no_server_found"
		end

		if server == self:Server() then
			return "already_connected_on_this_server"
		end

		if not server:CheckPassword(password) then
			return "bad_password"
		end

		self:Server():RemoveCashRegister(self)
		server:AddCashRegister(self)

		for _, ply in pairs(self:Users()) do
			if not self:Server():IsAllowed(ply) then
				self:Disconnect(ply)
			end
		end
	end

	function CashRegister:DisconnectServer()
		if self:Server().lan then
			return "can_not_disconnect_from_local_server"
		end

		self:Server():RemoveCashRegister(self)

		self.server = PxlCashRegister.New "Server" (self)

		local ply = self.parent:CPPIGetOwner()

		if not IsValid(ply) then
			ply = self.parent:Getowning_ent()
		end

		if IsValid(ply) then
			self:Server():SetOwner(ply)
		end
	end

	function CashRegister:Customer()
		if IsValid(self.customer) then
			return self.customer
		end
	end

	function CashRegister:Connect(ply)
		self.users[ply] = true

		local info = {
			hasbeenstole        	= self.hasbeenstole,
			iswaitingtoprintreceipt	= self.iswaitingtoprintreceipt,
			isfindingscanner    	= self.isfindingscanner,
			intransaction       	= self:InTransaction(),
			isowner					= self:Server():Owner() == ply:UniqueID()
		}

		self:Call("Connect", info)

		self.neededinfo[ply] = {}

		self:Send(ply).Connect(util.TableToJSON(info))
	end

	function CashRegister:CanConnect(ply)
		if self.users[ply] then
			return false, "already_connected"
		elseif not self:Server():IsAllowed(ply) then
			return false, "no_access"
		end

		return true
	end

	function CashRegister:Disconnect(ply)
		if not self.users[ply] then return end

		self.neededinfo[ply]  = nil

		self.users[ply] = nil
		self:Send(ply).Disconnect()
	end

	function CashRegister:Think()
		for _, ply in pairs(self:Users()) do
			if self.parent:GetPos():Distance(ply:GetShootPos()) > 200 then
				self:Disconnect(ply)
			end
		end
	end

	function CashRegister:OnRemove()
		local ent = self.parent

		timer.Simple(0, function()
			if IsValid(ent) then
				ent:Remove()
			end
		end)

		for _, scn in pairs(self.accessories) do
			self:RemoveAccessory(scn)
		end

		self:Server():RemoveCashRegister(self)
		-- self:Send(player.GetAll()).Remove()
	end

	function CashRegister:UpdateCustomers(ply)
		local info = {
			items = {},
			cost = 0,
			is_ready = self.iswaitingforcustomer,
			name = self:Server():Name()
		}

		for _,itm in pairs(self.items) do
		   	info.cost = info.cost + itm:Cost()

			table.insert(info.items, {
				name = itm:Name(),
				cost = itm:Cost()
			})
		end

		self:Send(ply or self:Customers(), "Customer").Update(info)
	end

	function CashRegister:AddItem(item)
		if self:Server():GetItem(item.id) ~= item then return "invalid_item" end
		if self.items[item.id] then return "already_in" end
		if self:InTransaction() then return "in_transaction" end

		self.items[item.id] = item
		item.cash_register = self

		self:Send(self:NeededInfo("items")).AddItem({
			id = item.id,
			name = item:Name(), 
			cost = item:Cost(), 
			model = item:Model(),
			groupid = item:GroupID()})
		self:UpdateCustomers()
	end

	function CashRegister:AddService(name, cost)
		if self:InTransaction() then return "in_transaction" end

		local service = PxlCashRegister.New "Service" (self, name, cost)
		self.items[service.id] = service

		self:Send(self:NeededInfo("items")).AddItem({
			id = service.id,
			name = service:Name(), 
			cost = service:Cost()})
		self:UpdateCustomers()
	end

	function CashRegister:HasItem(item)
		return self.items[item.id] and true or false
	end

	function CashRegister:RemoveItem(item)
		if self:InTransaction() then return end

		self.items[item.id] = nil
		item.cash_register = nil

		self:Send(self:NeededInfo("items")).RemoveItem(item.id)
		self:UpdateCustomers()
	end

	function CashRegister:ClearItems()
		if self:InTransaction() then return end

		self.items =  {}

		self:Send(self:NeededInfo("items")).ClearItems()
		self:UpdateCustomers()
	end

	function CashRegister:SendItems(ply)
		if not self.users[ply] then return end

		local info = {}

		for _, itm in pairs(self.items) do
			table.insert(info, {
				id = itm.id,
				name = itm:Name(), 
				cost = itm:Cost(), 
				model = itm:Model(),
				groupid = itm:GroupID()})
		end

		self:Send(self:NeededInfo("items")).SendItems(info)
	end

	function CashRegister:SendAccessOption(ply)
		local ply = istable(ply) and ply or {ply}

		local info = {
			allowed = {},
			notallowed = {},
			invitation = {},
		}

		for _, ply in pairs(player.GetAll()) do
			if not self:Server():IsAllowed(ply) and not self:Server().invitedplayers[ply:UniqueID()] then
				table.insert(info.notallowed, {name = ply:Name(), uid = ply:UniqueID()})
			end
		end

		for uid, name in pairs(self:Server().players) do
			table.insert(info.allowed, {name = name, uid = uid, isowner = (uid == self:Server():Owner())})
		end

		for uid, name in pairs(self:Server().invitedplayers) do
			table.insert(info.allowed, {name = name, uid = uid, invitation = true})
		end



		for _, pl in pairs(ply) do
			info.isowner = self:Server().owner == pl:UniqueID()
			info.permission = self:Server().permission

			self:Send(pl).GetEmployeesInfo(info)
		end

	end

	function CashRegister:SendServerItems(ply, show_empty_cat)
		local info = {}

		local passed_groups = {}

		for id, itm in pairs(self:Server().items) do
			table.insert(info, {
				id = itm.id,
				name = itm:Name(), 
				cost = itm:Cost(), 
				model = itm:Model(),
				groupid = itm:GroupID()})

			passed_groups[itm:GroupID()] = true
		end

		if show_empty_cat then
			for id, group in pairs(self:Server().groups) do
				if not passed_groups[id] and group.name ~= "#" .. id then
					table.insert(info, {
						name = group:Name(), 
						cost = group:Cost(), 
						model = group:Model(),
						groupid = id})
				end
			end
		end

		self:Send(ply).SendServerItems(info, show_empty_cat)
	end

	function CashRegister:SendMoneyInfo(ply)
		local info = {
			credit   	= self:Server().credit,
			cash     	= self.cash,
			transfers	= {},
			deposits 	= {},
			players  	= {}
		}

		for mod, data in pairs(PxlCashRegister.Modules.Transfers) do
			info.transfers[mod] = {Name = data.Name, Type = data.Type}
		end

		for _,ply in pairs(player.GetAll()) do
			if self:Server():IsAllowed(ply) then
				table.insert(info.players, {name = ply:Name(), uid = ply:UniqueID()})
			end
		end

		local pcount = 0
		function checkToSend()
			pcount = pcount + 1

			if table.Count(PxlCashRegister.Modules.Payments) == pcount then
				local ply = istable(ply) and ply or {ply}

				for _, pl in pairs(ply) do
					info.isallowed = self:Server():HasPermission(pl, "money")
					self:Send(ply).SendMoneyInfo(util.TableToJSON(info))
				end
			end
		end

		for mod, data in pairs(PxlCashRegister.Modules.Payments) do
			if isfunction(data.ToCostomer) then
				data.ToCostomer(self, ply, function(err, more)
					if not err then
						info.deposits[mod] = {Name = data.Name, Type = data.Type, More = more}
						checkToSend()
					else
						print("CashRegister Error: ", err)
					end
				end)
			else
				info.deposits[mod] = {Name = data.Name, Type = data.Type, More = {}}
				checkToSend()
			end
		end
	end

	function CashRegister:SendServerInfo(ply)
		local info = {
			name    	= self:Server():Name(),
			message 	= self:Server():Message(),
			password	= self:Server().password,
			lan     	= self:Server().lan
		}

		self:Send(ply).GetServerInfo(util.TableToJSON(info))
	end

	function CashRegister:SendLogs(ply)
		local info = {
			logs = {}
		}

		for id, log in pairs(self:Server().logs) do
			info.logs[id] = {
				id = id,
				time = log.__time,
				type = log.__type,
				args = {self:Server():FormatLog(log)}
			}
		end

		self:Send(ply).GetLogs(util.TableToJSON(info))
	end

	function CashRegister:SendPermissionInfo(ply)
		local ply = istable(ply) and ply or {ply}

		for _, pl in pairs(ply) do
			local info = {
				isowner = self:Server().owner == pl:UniqueID(),
				permission = self:Server().permission
			}

			self:Send(pl).GetPermissionInfo(util.TableToJSON(info))
		end
	end

	function CashRegister:SendConnectInfo(ply)
		local ply = istable(ply) and ply or {ply}

		local owner = player.GetByUniqueID(self:Server():Owner())

		for _, pl in pairs(ply) do
			local info = {
				forrenting = self:Server():IsPersistMod() and not self:Server():Owner(),
				isadmin = PxlCashRegister.Config.IsAdmin(pl),
				cansell = self:Server():IsPersistMod() and self:Server():Owner() == pl:UniqueID(),
				renting_cost = self:Server().renting_cost,
				selling_price = self:Server().selling_price,

				server_id	= self:Server():GetID(),
				server_name	= self:Server():Name(),
				cash_register_id	= self:GetID(),
				owner_name	= IsValid(owner) and owner:Name() or (self:Server():Owner() and "disconnected" or "none"),
			}

			self:Send(pl).GetConnectInfo(info)
		end
	end

	--[[----------------------------------------------------------
	-	Scanner													]]

		function CashRegister:FindScanner()
			self.isfindingscanner = true

			self:Send(self:Users()).FindScanner()
		end

		function CashRegister:IsFindingScanner()
			return self.isfindingscanner
		end

		function CashRegister:StopFindingScanner()
			if not self.isfindingscanner then return end

			self.isfindingscanner = false

			self:Send(self:Users()).StopFindingScanner()
		end

		function CashRegister:CheckScanner(scn)
			if not scn:CashRegister() then
				self:AddAccessory(scn)
				self:StopFindingScanner()
				self:Send(self:Users()).Message("scanner_added")
			else
				return "scanner_already_linked"
			end
		end

	--[[----------------------------------------------------------
	-	Accessories												]]

		function CashRegister:AddAccessory(accessory)
			self.accessories[accessory:GetID()] = accessory
			accessory:SetCashRegister(self)

			self:SendAccessoriesOption(self:NeededInfo("accessory"))
		end

		function CashRegister:RemoveAccessory(accessory)
			self.accessories[accessory:GetID()] = nil
			accessory:SetCashRegister(nil)

			self:SendAccessoriesOption(self:NeededInfo("accessory"))
		end

		function CashRegister:SendAccessoriesOption(ply)
			local info = {}

			for id, accessory in pairs(self.accessories) do
				table.insert(info, {id = id, type = accessory:AccessoryType() or "not_defined", editable = table.Count(accessory.Options or {}) > 0})
			end

			for id, accessory in pairs(self:Server().accessories) do
				table.insert(info, {id = id, type = accessory:AccessoryType() or "not_defined", editable = table.Count(accessory.Options or {}) > 0})
			end

			self:Send(ply).GetAccessoriesInfo(info)
		end

	--[[----------------------------------------------------------
	-	Transaction												]]

		function CashRegister:PreparePurchase(ply)
			self.iswaitingforcustomer = false
			self.customer = ply

			self:UpdateCustomers()

			local info = {
				items = {},
				payments = {},
				total = 0
			}

			for id, itm in pairs(self.items) do
				info.items[id] = {itm:Name(), itm:Cost()}
				info.total = info.total + itm:Cost()
			end

			local pcount = 0
			function checkToSend()
				pcount = pcount + 1
				if table.Count(PxlCashRegister.Modules.Payments) == pcount then
					self:Send(ply, "Customer").PreparePurchase(info)
				end
			end

			for mod, payment in pairs(PxlCashRegister.Modules.Payments) do
				if isfunction(payment.ToCostomer) then
					payment.ToCostomer(self, ply, function(err, more)
						if not err then
							info.payments[mod] = {Name = payment.Name, Type = payment.Type, More = more}
							checkToSend()
						else
							print("CashRegister Error: ", err)
						end
					end)
				else
					info.payments[mod] = {Name = payment.Name, Type = payment.Type, More = {}}
					checkToSend()
				end
			end
		end

		function CashRegister:QuitTransaction()
			self.iswaitingforcustomer = true

			self:UpdateCustomers()

			self.customer = NULL
		end

		function CashRegister:StartTransaction(ply)
			if self:InTransaction() then return end

			if table.Count(self.items) == 0 then
				self:Send(ply).MessageTitle("warning", "warning.no_item_in_cart_for_transaction")
				return
			end

			self.iswaitingforcustomer = true


			self:UpdateCustomers()

			self:Send(self:Users()).StartTransaction()
		end

		function CashRegister:StopTransaction()
			if self:Customer() then
				self:QuitTransaction()
			end

			self.iswaitingforcustomer = false

			self:UpdateCustomers()

			self:Send(self:Users()).StopTransaction()
		end

		function CashRegister:InTransaction()
			if self.iswaitingforcustomer then return true end
			if IsValid(self:Customer()) then return true end

			return false
		end

		function CashRegister:AddCash(amount)
			if self.cash + amount >= 0 then
				self.cash = self.cash + amount
				self:Send(self:NeededInfo("money")).UpdateMoney(self:GetCash(), self:GetCredit())

				return true
			else
				return false, "not_enough_money"
			end
		end

		function CashRegister:GetCash()
			return self.cash
		end

		function CashRegister:AddCredit(amount)
			return self:Server():AddCredit(amount)
		end

		function CashRegister:GetCredit()
			return self:Server():GetCredit()
		end

		function CashRegister:Purchase(customer, mod, info)
			assert(PxlCashRegister.Modules.Payments[mod], "The Payment mod " .. mod .. " doesn't exist")
			local paymod = PxlCashRegister.Modules.Payments[mod]
			local info = info or {}

			info.description = info.description or tr("purchase_to", self:Server():Name())

			local price = 0
			local items = {}

			for _,itm in pairs(self.items) do
				price = price + itm:Cost()
				table.insert(items, {name = itm:Name(), cost = itm:Cost()})
			end

			paymod.Pay(self, customer, price, info or {}, function(err, add)
				if err then
					self:Send(customer, "Customer").MessageTitle("payment_error", err)
					self:QuitTransaction()
				else
					self:StopTransaction()

					if paymod.Type == "cash" then
						self:Anim()
					end

					for _,itm in pairs(self.items) do
						itm:Sell(customer)
					end

					local receipt = {
						items       	= items,
						price       	= price,
						mod         	= mod,
						customer    	= customer:Name(),
						customer_uid	= customer:UniqueID(),
						operator    	= self:Users()[1]:Name(),
						operator_uid	= self:Users()[1]:UniqueID(),
						cash_register_id= self:GetID(),
						server_name 	= self:Server():Name(),
						message     	= self:Server():Message(),
						more        	= add,
					}
					self.lastreceipt = {receipt, customer}
					self.iswaitingtoprintreceipt = true

					self:Server():Log("Purchase", receipt)

					self:Send(customer).Notify("notify_purchase", receipt.__id, price, mod)

					self:ClearItems()

					self:Send(self:Users()).AskToPrintReceipt()
					self:Send(customer, "Customer").Message("payment_successful", "purchase_completed")
				end
			end)
		end

		function CashRegister:PrintReceipt(receipt, ply)
			if self.printer_busy then return "the_printer_is_busy" end

			self.printer_busy = true

			local receipt_ent = ents.Create("pxl_cr_receipt")
			receipt_ent:SetPos(self.parent:GetPos())
			receipt_ent:Spawn()
			receipt_ent:SetInfo(receipt)
			receipt_ent.onlyremover = true

			if IsValid(ply) then
				receipt_ent:Setowning_ent(ply)
				receipt_ent.SID = ply.SID

				ply:AddCleanup("PxlReceipt", receipt_ent)
			end


			local startang = -190
			local endang = -100

			local time = 2.7
			local tick = 60
			local radius = 2

			local pos = Vector(-22.5, -2.3, 1.8)
			local ang = Angle(0, -112, 0)

			local angcorect = -14

			sound.Play("PxlCashRegister.Print", self.parent:LocalToWorld(LocalToWorld(pos, Angle(), Vector(), ang)))

			local i = 0
			timer.Create("Selle.AnimPrint:" .. self:GetID(), time/tick, tick, function()
				i = i + 1

				local p = startang + (endang - startang)*(i/tick)

				receipt_ent:SetAngles(self.parent:LocalToWorldAngles(Angle(0, 0, p + angcorect) + ang))
				receipt_ent:SetPos(self.parent:LocalToWorld(LocalToWorld(Vector(0, -math.sin(p/180*math.pi)*radius, math.cos(p/180*math.pi)*radius) + pos, Angle(), Vector(), ang)))

				if i == tick then
					-- receipt_ent:GetPhysicsObject():Wake()
					self.printer_busy = false
				end
			end)

		end

		function CashRegister:Deposit(ply, mod, amount, info, callback)
			assert(PxlCashRegister.Modules.Payments[mod], "The payment mod " .. mod .. " doesn't exist")
			local info = info or {}

			info.description = info.description or tr("deposit_to", self:Server():Name())

			local paymod = PxlCashRegister.Modules.Payments[mod]

			paymod.Pay(self, ply, amount, info, function(err)
				if err then
					if callback then callback(err) end
				else
					if paymod.Type == "cash" then
						self:Anim()
					end

					self:Server():Log("Deposit", {
						target    	= ply:Name(),
						target_uid	= ply:UniqueID(),
						mod       	= mod,
						amount    	= math.Round(amount, 2),
					})

					self:Send(ply).Notify("notify_money_deposit", amount, mod)

					if callback then callback() end
				end
			end)
		end

		function CashRegister:Transfer(ply, mod, amount, info, callback)
			assert(PxlCashRegister.Modules.Transfers[mod], "The transfer mod " .. mod .. " doesn't exist")
			local info = info or {}

			info.description = info.description or tr("transfer_from", self:Server():Name())

			local tranmod = PxlCashRegister.Modules.Transfers[mod]

			tranmod.Transfer(self, ply, amount, info, function(err)
				if err then
					if callback then callback(err) end
				else
					if tranmod.Type == "cash" and info.do_anim ~= false then
						self:Anim()
					end

					self:Server():Log("Transfer", {
						target    	= ply:Name(),
						target_uid	= ply:UniqueID(),
						mod       	= mod,
						amount    	= math.Round(amount, 2),
					})

					self:Send(ply).Notify("notify_money_transer", amount, mod)

					if callback then callback() end
				end
			end)
		end

		function CashRegister:AnimOpen()
			self.parent:AnimOpen()
		end

		function CashRegister:AnimClose()
			self.parent:AnimClose()
		end

		function CashRegister:Anim()
			self.parent:Anim()
		end



	--[[----------------------------------------------------------
	-	Stealing												]]

		function CashRegister:CanLockPick(ply)
			if not self.hasbeenstole then
				local pos = self.parent:WorldToLocal(ply:GetEyeTrace().HitPos)

				if pos.x > 7.2 and pos.y > -7.2 and pos.y < 7.2 and pos.z > -1.6 and pos.z < 1.6 then
					return true
				end
			end
		end

		function CashRegister:onLockpickCompleted(ply, succ)
			if succ then
				self.hasbeenstole = true

				self:StopTransaction()

				self:AnimOpen()
				self:Transfer(ply, "Cash", self:GetCash(), {do_anim = false})
				self:Send(self:Users()).StolePopup()
			end
		end

		hook.Add("canLockpick", "PxlCashRegister", function(ply, ent, trace)
			if ent.IsCashRegister then
				return ent:CashRegister():CanLockPick(ply)
			end
		end)

		hook.Add("onLockpickCompleted", "PxlCashRegister", function(ply, succ, ent)
			if ent.IsCashRegister then
				ent:CashRegister():onLockpickCompleted(ply, succ)
			end
		end)

--[[---------------------------------------------------------
	Receive
-----------------------------------------------------------]]
	local ByPassAction = {
		["GetInitialInfo"]	= true,
		["GetConnectInfo"]	= true,
		["GetRentInfo"]		= true,
		["NeededInfo"]		= function(info)
			if info == "connect" then
				return true
			end
		end
	}

	function CashRegister:ReceiveCallback(ply, action, ...)
		local tr = ply:GetEyeTrace()

		if ByPassAction[action] then
			if isfunction(ByPassAction[action]) then
				if ByPassAction[action](...) then
					return
				end
			else
				return
			end
		end


		if tr.Entity ~= self.parent then
			return false
		elseif tr.HitPos:Distance(tr.StartPos) > PxlCashRegister.Config.ScreenRange then
			return false
		end
	end

	--[[----------------------------------------------------------
	-	User Screen												]]
	 	function CashRegister.Receive:Connect(ply)
	 		local succ, err = self:CanConnect(ply)
	 		if succ then
	 			self:Connect(ply)
	 		elseif self:Server().invitedplayers[ply:UniqueID()] then
				self:Send(ply).AskForInvitation()
			elseif isstring(err) then
	 			self:Send(ply).Message("connection_failed", err)
	 		end
	 	end

		function CashRegister.Receive:Disconnect(ply)
			if self.users[ply] then
				self:Disconnect(ply)
			end
		end

		function CashRegister.Receive:NeededInfo(ply, ...)
			local args = {...}

			if self.users[ply] or #args == 0 or (#args == 1 and args[1] == "connect") then
				self.neededinfo[ply] = {...}
			end
		end

		function CashRegister.Receive:GetItems(ply)
			if not self.users[ply] then return end

			self:SendItems(ply)
		end

		function CashRegister.Receive:RemoveItem(ply, id)
			if not isnumber(id) then return end
			local item = self.items[id]

			if not item then return end
			if not self.users[ply] then return end

			self:RemoveItem(item)
		end

		function CashRegister.Receive:ClearItems(ply)
			if not self.users[ply] then return end

			if table.Count(self.items) == 0 then
				self:Send(ply).Message("no_item_to_clear")
				return
			end

			self:ClearItems()
		end

		function CashRegister.Receive:ClearServer(ply)
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "items") then
				self:Send(ply).Message("not_allowed")
				return
			end

			if table.Count(self:Server().items) == 0 then
				self:Send(ply).Message("no_item_to_clear_server")
				return
			end

			self:Server():Clear()
			self:Send(self:NeededInfo("server_items")).ClearServerItems(true)
		end

		function CashRegister.Receive:FindScanner(ply)
			if not self.users[ply] then return end

			if not self:Server():HasPermission(ply, "option") then
				self:Send(ply).Message("not_allowed")
				return
			end
			if self:Server():IsPersistMod() and not self:Server().can_edit_accessory and not PxlCashRegister.Config.IsAdmin(ply) then
				self:Send(ply).Message("not_allowed")
				return
			end

			self:FindScanner()
		end

		function CashRegister.Receive:StopFindingScanner(ply)
			if not self.users[ply] then return end

			self:StopFindingScanner()
		end

		function CashRegister.Receive:StartTransaction(ply)
			if not self.users[ply] then return end

			self:StartTransaction(ply)
		end

		function CashRegister.Receive:StopTransaction(ply)
			if not self.users[ply] then return end
			if not self:InTransaction() then return end

			self:StopTransaction()
		end

		function CashRegister.Receive:GetServerItems(ply, show_empty_cat)
			if not self.users[ply] then return end

			self:SendServerItems(ply, show_empty_cat)
		end

		function CashRegister.Receive:RemoveServerItem(ply, id)
			if not isnumber(id) then return end
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "items") then
				self:Send(ply).Message("not_allowed")
				return
			end

			self:Server():RemoveItem(id)
		end

		function CashRegister.Receive:RemoveServerItemGroup(ply, id)
			if not isstring(id) then return end
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "items") then
				self:Send(ply).Message("not_allowed")
				return
			end

			self:Server():RemoveItemGroup(id)
		end

		function CashRegister.Receive:EditItem(ply, id, name, cost)
			if not isstring(name) then return end
			if not isnumber(cost) then return end

			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "items") then
				self:Send(ply).Message("not_allowed")
				return
			end

			cost = math.Round(cost, 2)
			
			if not isstring(name) or #name > 32 then
				self:Send(ply).Message("invalid_name", name)
				return
			end
			
			if not isnumber(cost) or cost < 0 or cost > 2^32 then
				self:Send(ply).Message("invalid_cost", cost)
				return
			end
			
			if isnumber(id) then
				self:Server():EditItem(id, name, cost)
			elseif isstring(id) then
				self:Server():EditItemGroup(id, name, cost)
			end
			
			self:UpdateCustomers()
		end

		function CashRegister.Receive:GetEmployeesInfo(ply)
			if not self.users[ply] then return end

			self:SendAccessOption(ply)
		end

		function CashRegister.Receive:AddPlayer(ply, uid)
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "option") then
				self:Send(ply).Message("not_allowed")
				return
			end

			local pl = player.GetByUniqueID(uid)

			if IsValid(pl) and not self:Server():IsAllowed(pl) and not self:Server().invitedplayers[uid] then
				self:Server():InvitatPlayer(pl)
			else
				self:Send(ply).Message("player_disconnected")
			end
		end

		function CashRegister.Receive:RemovePlayer(ply, uid)
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "option") then
				self:Send(ply).Message("not_allowed")
				return
			end

			if self:Server():IsAllowed(uid) or self:Server().invitedplayers[uid] then
				local err = self:Server():RemovePlayer(uid)

				if err then
					self:Send(ply).Message(err)
				else
					local pl = player.GetByUniqueID(uid)
					if self.users[pl] then
						self:Disconnect(pl)
					end
				end
			end
		end

		function CashRegister.Receive:GetAccessoriesInfo(ply)
			if not self.users[ply] then return end

			self:SendAccessoriesOption(ply)
		end

		function CashRegister.Receive:GetMoneyInfo(ply)
			if not self.users[ply] then return end

			self:SendMoneyInfo(ply)
		end

		function CashRegister.Receive:RemoveAccessory(ply, id)
			if not isnumber(id) then return end
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "option") then
				self:Send(ply).Message("not_allowed")
				return
			end
			if self:Server():IsPersistMod() and not self:Server().can_edit_accessory and not PxlCashRegister.Config.IsAdmin(ply) then
				self:Send(ply).Message("not_allowed")
				return
			end

			if self.accessories[id] then
				self:RemoveAccessory(self.accessories[id])
			elseif self:Server().accessories[id] then
				self:Server():RemoveAccessory(self:Server().accessories[id])
			end
		end

		function CashRegister.Receive:GetAccessoryOptions(ply, id)
			if not isnumber(id) then return end
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "option") then
				self:Send(ply).Message("not_allowed")
				return
			end
			if self:Server():IsPersistMod() and not self:Server().can_edit_accessory and not PxlCashRegister.Config.IsAdmin(ply) then
				self:Send(ply).Message("not_allowed")
				return
			end

			local accessory = self.accessories[id] or self:Server().accessories[id]

			if IsValid(accessory) then
				local options = {}

				for name, option in pairs(accessory.Options) do
					options[name] = {}

					for key, value in pairs(option) do
						if not isfunction(value) then
							options[name][key] = value
						end
					end

					options[name].Value = accessory:Option(name)
				end

				return options
			else
				self:Send(ply).Message("no_accessory_found")
				return
			end
		end

		function CashRegister.Receive:SetAccessoryOptions(ply, id, options)
			if not isnumber(id) then return end
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "option") then
				self:Send(ply).Message("not_allowed")
				return
			end
			if self:Server():IsPersistMod() and not self:Server().can_edit_accessory and not PxlCashRegister.Config.IsAdmin(ply) then
				self:Send(ply).Message("not_allowed")
				return
			end

			local accessory = self.accessories[id] or self:Server().accessories[id]

			if IsValid(accessory) then
				for name, value in pairs(options) do
					accessory:SetOption(name, value)
				end
			else
				self:Send(ply).Message("no_accessory_found")
				return
			end
		end

		function CashRegister.Receive:SendMoney(ply, uid, amount, mod)
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "money") then
				self:Send(ply).Message("not_allowed")
				return
			end

			local pl = player.GetByUniqueID(uid)

			if IsValid(pl) then
				self:Transfer(pl, mod, math.Round(amount, 2), {}, function(err)
					if err then
						self:Send(ply).Message("transfer_error", err)
					else
						self:SendMoneyInfo(ply)
						self:Send(ply).Message("transfer_success")
					end
				end)
			end
		end

		function CashRegister.Receive:AddService(ply, name, cost)
			if not self.users[ply] then return end
			name = isstring(name) and name or ""
			cost = isnumber(cost) and math.Round(cost, 2) or 0
			local maxlength = 128
			local maxcost = 2^31

			if #name > maxlength then
				self:Send(ply).Message("invalid_service_desc_long", maxlength)
				return
			elseif #name == 0 then
				self:Send(ply).Message("invalid_service_desc_short", maxlength)
				return
			end

			if cost > maxcost then
				self:Send(ply).Message("invalid_service_cost_big", maxcost)
				return
			elseif cost <= -maxcost then
				self:Send(ply).Message("invalid_service_cost_small", 0)
				return
			end

			local err = self:AddService(name, cost)

			if err then
				self:Send(ply).Message(err)
			end
		end

		function CashRegister.Receive:StoleOk(ply)
			if not self.users[ply] then return end
			if not self.hasbeenstole then return end
			self.hasbeenstole = false

			self:AnimClose()
			self:Send(self:Users()).CloseStolePopup()
		end

		function CashRegister.Receive:GetServerInfo(ply)
			if not self.users[ply] then return end

			self:SendServerInfo(ply)
		end

		function CashRegister.Receive:EditServerName(ply, name)
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "option") then
				self:Send(ply).Message("not_allowed")
				return
			end

			name = isstring(name) and name or ""
			local maxlength = 32

			if #name > maxlength then
				self:Send(ply).Message("invalid_server_name_long", maxlength)
				return
			elseif #name == 0 then
				self:Send(ply).Message("invalid_server_name_short", maxlength)
				return
			end

			local err = {self:Server():SetName(name)}

			if #err > 0 then
				self:Send(ply).Message(unpack(err))
			end
		end

		function CashRegister.Receive:EditServerMessage(ply, message)
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "option") then
				self:Send(ply).Message("not_allowed")
				return
			end

			message = message ~= "" and message or nil

			self:Server():SetMessage(message)
		end

		function CashRegister.Receive:ReplyToPrintReceipt(ply, answer)
			if not self.users[ply] then return end
			if not self.iswaitingtoprintreceipt then return end

			self.iswaitingtoprintreceipt = false
			self:Send(self:Users()).CloseReceiptPopup()

			if answer and self.lastreceipt then
				local err = self:PrintReceipt(unpack(self.lastreceipt))
				if err then
					self:Send(ply).Message(err)
				end
			end
		end

		function CashRegister.Receive:GetLogs(ply)
			if not self.users[ply] then return end

			self:SendLogs(ply)
		end

		function CashRegister.Receive:PrintReceipt(ply, receipt_id)
			if not self.users[ply] then return end

			local receipt = self:Server().logs[receipt_id]

			if not receipt then
				self:Send(ply).Message("invalid_receipt_id")
				return
			end

			local err = self:PrintReceipt(receipt, ply)
			if err then
				self:Send(ply).Message(err)
			end
		end

		function CashRegister.Receive:PrintReceiptToCustomer(ply, receipt_id)
			if not self.users[ply] then return end

			local receipt = self:Server().logs[receipt_id]

			if not receipt then
				self:Send(ply).Message("invalid_receipt_id")
				return
			end

			local pl = player.GetByUniqueID(receipt.customer_uid)
			if not IsValid(pl) then
				self:Send(ply).Message("player_not_connected")
			else
				local err = self:PrintReceipt(receipt, pl)
				if err then
					self:Send(ply).Message(err)
				end
			end
		end

		function CashRegister.Receive:EmitSound(ply)
			sound.Play("PxlCashRegister.Click", self.parent:GetPos())
		end

		function CashRegister.Receive:KeyTyping(ply)
			sound.Play("PxlCashRegister.Typing", self.parent:GetPos())
		end

		function CashRegister.Receive:DepositMoney(ply, amount, mod, more)
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "money") then
				self:Send(ply).Message("not_allowed")
				return
			end
			amount = isnumber(amount) and amount or 0
			if amount <= 0 then
				self:Send(ply).Message("you_cannot_deposit_negative_amount")
				return
			end

			self:Deposit(ply, mod, amount, more or {}, function(err)
				if err then
					self:Send(ply).Message(err)
				else
					self:Send(ply).Message("deposit_successful")
				end
			end)
		end

		function CashRegister.Receive:OpenPage(ply, page, lang)
			local path = "data/cash_register/" .. page .. "/"

			if not file.Exists(path .. lang .. ".txt", "GAME") then
				lang = PxlCashRegister.Config.DefaultLanguage
			end

			if not file.Exists(path .. lang .. ".txt", "GAME") then
				return "<h1>Error 404</h1>"
			else
				return file.Read(path .. lang .. ".txt", "GAME")
			end

		end

		function CashRegister.Receive:ChangerServerPassword(ply, password)
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "option") then
				self:Send(ply).Message("not_allowed")
				return
			end
			if self:Server():IsPersistMod() and not self:Server().can_edit_server and not PxlCashRegister.Config.IsAdmin(ply) then
				self:Send(ply).Message("not_allowed")
				return
			end

			local maxlength = 16
			local minlength = 4

			if #password > maxlength then
				self:Send(ply).Message("invalid_server_password_long", maxlength)
				return
			elseif #password < minlength then
				self:Send(ply).Message("invalid_server_password_short", minlength)
				return
			end

			local password_old = self:Server().password or "no_password"

			local err = self:Server():SetPassword(password)

			if err then
				self:Send(ply).Message(err)
			else
				self:Server():Log("PasswordChanged", {
					user_name   	= ply:Name(),
					user_uid    	= ply:UniqueID(),
					password_old	= password_old,
					password_new	= password
				})
			end
		end

		function CashRegister.Receive:ConnectServer(ply, name, password)
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "option") then
				self:Send(ply).Message("not_allowed")
				return
			end
			if self:Server():IsPersistMod() and not self:Server().can_edit_server and not PxlCashRegister.Config.IsAdmin(ply) then
				self:Send(ply).Message("not_allowed")
				return
			end

			local err = self:ConnectServer(name, password)

			if err then
				self:Send(ply).Message(err)
			else
				if not self:Server():IsAllowed(ply) then
					self:Server():AddPlayer(ply)
				end

				self:Send(ply).Message("server_connection_successful")
			end
		end

		function CashRegister.Receive:DisconnectServer(ply)
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "option") then
				self:Send(ply).Message("not_allowed")
				return
			end
			if self:Server():IsPersistMod() and not self:Server().can_edit_server and not PxlCashRegister.Config.IsAdmin(ply) then
				self:Send(ply).Message("not_allowed")
				return
			end

			local err = self:DisconnectServer()

			if err then
				self:Send(ply).Message(err)
			end
		end

		function CashRegister.Receive:MakeServerPrivate(ply)
			if not self.users[ply] then return end
			if not self:Server():HasPermission(ply, "option") then
				self:Send(ply).Message("not_allowed")
				return
			end
			if self:Server():IsPersistMod() and not self:Server().can_edit_server and not PxlCashRegister.Config.IsAdmin(ply) then
				self:Send(ply).Message("not_allowed")
				return
			end

			if not self:Server().password then
				self:Send(ply).Message("server_already_private")
				return
			end

			self:Server():SetPassword()
		end

		function CashRegister.Receive:GetPermissionInfo(ply)
			if not self.users[ply] then return end

			self:SendPermissionInfo(ply)
		end

		function CashRegister.Receive:ChangePermission(ply, permission, val)
			if not self.users[ply] then return end

			if ply:UniqueID() ~= self:Server().owner then
				self:Send(ply).Message("you_are_not_the_owner")
				return
			end

			if not isbool(val) then
				self:Send(ply).Message("bad_entry")
				return
			end

			local err = self:Server():ChangePermission(permission, val)

			if err then
				self:Send(ply).Message(err)
			end
		end

		function CashRegister.Receive:AnswerForInvitation(ply, answer)
			if not self:Server().invitedplayers[ply:UniqueID()] then return end

			if answer then
				self:Server().invitedplayers[ply:UniqueID()] = nil
				self:Server():AddPlayer(ply)
				self:Connect(ply)
			else
				self:Server():RemovePlayer(ply)
			end
		end

		function CashRegister.Receive:GetConnectInfo(ply)
			self:SendConnectInfo(ply)
		end

		function CashRegister.Receive:GetRentInfo(ply)
			if not PxlCashRegister.Config.IsAdmin(ply) then
				self:Send(ply).Message("not_allowed")
				return
			end

			local info = {
				ispersist 	= self:Server():IsPersistMod(),
				server		= defbool(self:Server().can_edit_server, false),
				accessory	= defbool(self:Server().can_edit_accessory, true),
				rend		= self:Server().renting_cost or 1000,
				sell		= self:Server().selling_price or 800
			}

			return util.TableToJSON(info)
		end

		function CashRegister.Receive:GetRentingInfo(ply)
			local info = {
				cost		= self:Server().renting_cost,
				payments	= {},
				isadmin		= PxlCashRegister.Config.IsAdmin(ply)
			}

			local pcount = 0
			function checkToSend()
				pcount = pcount + 1

				if table.Count(PxlCashRegister.Modules.Payments) == pcount then
					self:Send(ply).GetRentingInfo(util.TableToJSON(info))
				end
			end

			for mod, data in pairs(PxlCashRegister.Modules.Payments) do
				if isfunction(data.ToCostomer) then
					data.ToCostomer(self, ply, function(err, more)
						if not err then
							info.payments[mod] = {Name = data.Name, Type = data.Type, More = more}
							checkToSend()
						else
							print("CashRegister Error: ", err)
						end
					end)
				else
					info.payments[mod] = {Name = data.Name, Type = data.Type, More = {}}
					checkToSend()
				end
			end
		end

		function CashRegister.Receive:GetSellingInfo(ply)
			if ply:UniqueID() ~= self:Server():Owner() then return end

			if self:Server().rent_info then
				local r_info = self:Server().rent_info

				if r_info.admin then
					self:Server():Sell()
					return
				else
					info = {
						cost = self:Server().selling_price,
						mod = r_info.mod
					}

					local money = self:Server():GetCredit() > 0
					if not money then
						for _, cash_register in pairs(self:Server():CashRegisters()) do
							if cash_register:GetCash() > 0 then
								money = true
								break
							end
						end
					end
					info.money = money

					self:Send(ply).GetSellingInfo(util.TableToJSON(info))

					return
				end
			end

			local info = {
				cost		= self:Server().selling_price,
				payments	= {},
				isadmin		= PxlCashRegister.Config.IsAdmin(ply)
			}

			local money = self:Server():GetCredit() > 0
			if not money then
				for _, cash_register in pairs(self:Server():CashRegisters()) do
					if cash_register:GetCash() > 0 then
						money = true
						break
					end
				end
			end
			info.money = money

			local pcount = 0
			function checkToSend()
				pcount = pcount + 1

				if table.Count(PxlCashRegister.Modules.Payments) == pcount then
					self:Send(ply).GetSellingInfo(util.TableToJSON(info))
				end
			end

			for mod, data in pairs(PxlCashRegister.Modules.Payments) do
				if isfunction(data.ToCostomer) then
					data.ToCostomer(self, ply, function(err, more)
						if not err then
							info.payments[mod] = {Name = data.Name, Type = data.Type, More = more}
							checkToSend()
						else
							print("CashRegister Error: ", err)
						end
					end)
				else
					info.payments[mod] = {Name = data.Name, Type = data.Type, More = {}}
					checkToSend()
				end
			end
		end

		function CashRegister.Receive:MakePersist(ply, can_edit_server, can_edit_accessory, renting_cost, selling_price)
			if not PxlCashRegister.Config.IsAdmin(ply) then return end

			self:Server().can_edit_server	= defbool(can_edit_server, false)
			self:Server().can_edit_accessory= defbool(can_edit_accessory, true)
			self:Server().renting_cost		= isnumber(renting_cost) and renting_cost or 1000
			self:Server().selling_price		= isnumber(selling_price) and selling_price or 800

			local err = {PxlCashRegister.Persist.SaveServer(self:Server())}

			if #err > 0 then
				self:Send(ply).Message(unpack(err))
			else
				PxlCashRegister.Persist.SaveServerSetting(self:Server())
				PxlCashRegister.Persist.LoadServer(self:Server():Name())
			end
		end

		function CashRegister.Receive:SaveSettingPersist(ply, can_edit_server, can_edit_accessory, renting_cost, selling_price)
			if not PxlCashRegister.Config.IsAdmin(ply) then return end

			self:Server().can_edit_server	= defbool(can_edit_server, false)
			self:Server().can_edit_accessory= defbool(can_edit_accessory, true)
			self:Server().renting_cost		= isnumber(renting_cost) and renting_cost or 1000
			self:Server().selling_price		= math.min(isnumber(selling_price) and selling_price or 800, self:Server().renting_cost)

			PxlCashRegister.Persist.SaveServerSetting(self:Server())

			self:Server():NeededInfo("connect", function(cash_register, ply)
				cash_register:SendConnectInfo(ply)
			end)
		end

		function CashRegister.Receive:SaveSetupPersist(ply)
			if not PxlCashRegister.Config.IsAdmin(ply) then return end

			PxlCashRegister.Persist.SaveServer(self:Server())

			self:Server():NeededInfo("connect", function(cash_register, ply)
				cash_register:SendConnectInfo(ply)
			end)
		end

		function CashRegister.Receive:ReloadPersist(ply)
			if not PxlCashRegister.Config.IsAdmin(ply) then return end
			if not self:Server():IsPersistMod() then return end

			PxlCashRegister.Persist.LoadServer(self:Server().persistid or self:Server():Name())
		end

		function CashRegister.Receive:RemovePersist(ply)
			if not PxlCashRegister.Config.IsAdmin(ply) then return end
			if not self:Server():IsPersistMod() then return end

			PxlCashRegister.Persist.RemoveServer(self:Server().persistid or self:Server():Name())
		end

		function CashRegister.Receive:Rent(ply, mod, info)
			if mod == "admin" then
				if PxlCashRegister.Config.IsAdmin(ply) then
					self:Server():Rent(ply, {mod = mod, admin = true})
				else
					self:Send(ply).Message("you_dont_have_access")
				end
			else
				local paymod = PxlCashRegister.Modules.Payments[mod]
				if not paymod then
					self:Send(ply).Message("invalid_payment_method")
				end

				info = info or {}
				info.description = info.description or tr("renting_server", self:Server():Name())
				info.dont_pay_machine = true

				paymod.Pay(self, ply, self:Server().renting_cost, info, function(err, add)
					if err then
						self:Send(ply).Message(err)
					else
						self:Server():Rent(ply, {mod = mod, info = info})
						return false
					end
				end)
			end
		end

		function CashRegister.Receive:Sell(ply, mod, info)
			if ply:UniqueID() ~= self:Server().owner then
				self:Send(ply).Message("you_are_not_the_owner")
				return
			end

			if self:Server().rent_info then
				local r_info = self:Server().rent_info

				mod = r_info.mod
				info = r_info.more
			end

			if mod == "admin" then
				if PxlCashRegister.Config.IsAdmin(ply) then
					self:Server():Sell(ply)
				else
					self:Send(ply).Message("you_dont_have_access")
				end
			else
				local paymod = PxlCashRegister.Modules.Payments[mod]
				if not paymod then
					self:Send(ply).Message("invalid_payment_method")
				end

				info = info or {}
				info.description = info.description or tr("selling_server", self:Server():Name())
				info.dont_pay_machine = true

				paymod.Pay(self, ply, -self:Server().selling_price, info or {}, function(err, add)
					if err then
						self:Send(ply).Message(err)
					else
						self:Server():Sell(ply)
						return false
					end
				end)
			end
		end



-- TODO - to rework a little bit!


		function CashRegister.Receive:GetProfilesList(ply, for_saving)
			if not self.users[ply] then return false end
			if ply:IsListenServerHost() then return false end
			if for_saving and not PxlCashRegister.Config.IsAdmin(ply) then return false end

			return PxlCashRegister.Profile.GetProfilesList()
		end



		function CashRegister.Receive:LoadProfile(ply, id, profile)
			if not self.users[ply] then return "not_allowed" end
			if not self:Server():HasPermission(ply, "items") then return "not_allowed" end

			if not PxlCashRegister.Profile.ValidateProfile(profile) then return "profile_error" end

			PxlCashRegister.Profile.InportProfile(self:Server(), profile)

			

			self:Server():NeededInfo("server_items", function(cash_register, ply)
				cash_register:SendServerItems(ply, true)
			end)

			return true
		end



		function CashRegister.Receive:SaveProfile(ply, name, on_server)
			if not self.users[ply] then return "not_allowed" end
			if not isstring(name) then return "format_error" end
			
			if string.match(name, "[%p]") then return "format_error" end

			if on_server then
				local profile = PxlCashRegister.Profile.ExportProfile(self:Server())

				PxlCashRegister.Profile.SaveProfile(name, profile)

				return true
			else
				return PxlCashRegister.Profile.ExportProfile(self:Server())
			end
		end

		function CashRegister.Receive:RemoveProfile(ply, id)
			if not self.users[ply] then return "not_allowed" end
			if not PxlCashRegister.Config.IsAdmin(ply) then return "not_allowed" end

			PxlCashRegister.Profile.RemoveProfile(id)
			return false
		end

		function CashRegister.Receive:ClearProfile(ply, name)
			if not self.users[ply] then return "not_allowed" end
			if not self:Server():HasPermission(ply, "items") then return "not_allowed" end

			for id, group in pairs(self:Server().groups) do
				group.name = "#" .. id
				group.cost = 100
			end

			self:Server():NeededInfo("server_items", function(cash_register, ply)
				cash_register:SendServerItems(ply)
			end)
			
			return true
		end

	--[[----------------------------------------------------------
	-	Customer Screen											]]


		function CashRegister.Receive.Customer:EmitSound(ply)
			sound.Play("PxlCashRegister.Click", self.parent:GetPos())
		end


		function CashRegister.Receive.Customer:GetPurchaseInfo(ply)
			if self:Customer() then return end
			if not self.iswaitingforcustomer then return end

			self:PreparePurchase(ply)
		end

		function CashRegister.Receive.Customer:Quit(ply)
			if self.customer ~= ply then return end

			self:QuitTransaction()
		end

		function CashRegister.Receive.Customer:Purchase(ply, mode, more)
			if self.customer ~= ply then return end
			if not PxlCashRegister.Modules.Payments[mode] then return end

			self:Purchase(ply, mode, more)
		end

		function CashRegister.Receive.Customer:Listen(ply)
			self.listening_customer[ply] = true

			self:UpdateCustomers(ply)
		end

		function CashRegister.Receive.Customer:StopListening(ply)
			self.listening_customer[ply] = nil
		end
