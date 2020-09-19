local Persist = {}
PxlCashRegister.Persist = Persist
Persist.Data = {}

local _path = "pxlcorp"
local _file = "cash_register_persist"

local function defbool(v, d) if v == nil or not isbool(v) then return d end return v end

function Persist.Init()
	if not file.Exists(_path, "DATA") then
		file.CreateDir(_path)
	end

	if not file.Exists(_path .. "/persist", "DATA") then
		file.CreateDir(_path .. "/persist")
	end

	-- 
	if file.Exists(_path .. "/" .. _file .. ".txt", "DATA") then
		Persist.ConvertOldSystem()
	end

	local f = file.Read(_path .. "/persist/" .. game.GetMap() .. ".txt")

	if f then
		Persist.Data = util.JSONToTable(f)
	else
		Persist.Data = {}
	end
end

function Persist.ConvertOldSystem()
	local f = file.Read(_path .. "/" .. _file .. ".txt", "DATA")

	local data = util.JSONToTable(f)

	for map, map_info in pairs(data) do
		file.Write(_path .. "/persist/" .. map .. ".txt", util.TableToJSON(map_info, true))
	end

	file.Delete(_path .. "/" .. _file .. ".txt")
end

local wait_for_saving
function Persist.Save()
	if not wait_for_saving then
		wait_for_saving = true

		timer.Simple(0, function()
			file.Write(_path .. "/persist/" .. game.GetMap() .. ".txt", util.TableToJSON(Persist.Data, true))
			wait_for_saving = false
		end)
	end
end

function Persist.SaveServer(server)
	if string.sub(server:Name(), 0, 8) == "Server #" then
		return "server_name_cant_start_by", "Server #"
	end


	if not server.persistid then
		if Persist.Data[server:Name()] then
			return "this_name_is_already_used_by_persist_server"
		end

		server.persistid = server:Name()
	end


	local data = {
		name = server:Name(),
		id = server.persistid,
		cash_registers = {},
		accessories = {}
	}

	if server.loadedprofile then
		data.profile = server.loadedprofile
	else
		data.profile = {}

		for id, group in pairs(server.groups) do
			if group.name ~= "#" .. id then
				data.profile[id] = {
					name = group.name,
					cost = group.cost,
					model = group.model
				}
			end
		end
	end

	for _, cash_register in pairs(server.cash_registers) do
		local ent = cash_register.parent

		local info = {
			class		= ent:GetClass(),
			pos			= ent:GetPos(),
			ang			= ent:GetAngles(),
			accessories	= {}
		}

		for _, accessory in pairs(cash_register.accessories) do
			local acc_info = accessory:Save()

			if istable(acc_info) then
				acc_info.type = accessory:Type()
				table.insert(info.accessories, acc_info)
			end
		end

		table.insert(data.cash_registers, info)
	end

	for _, accessory in pairs(server.accessories) do
		local acc_info = accessory:Save()

		if istable(acc_info) then
			acc_info.type = accessory:Type()
			table.insert(data.accessories, acc_info)
		end
	end

	Persist.Data[data.id] = data

	Persist.Save()
end

function Persist.SaveServerSetting(server)
	local data = Persist.Data[server:Name()]

	if data then
		data.name = server:Name()
		data.can_edit_server = defbool(server.can_edit_server, false)
		data.can_edit_accessory = defbool(server.can_edit_accessory, true)
		data.renting_cost = math.max(server.renting_cost, 0) or 1000
		data.selling_price = math.max(server.selling_price, 0) or 800
	end


	Persist.Save()
end

function Persist.Load()
	for name, _ in pairs(Persist.Data) do
		Persist.LoadServer(name)
	end
end

function Persist.LoadServer(id)
	local data = Persist.Data[id]
	data.profile = data.profile or data.profil or {}

	if data then
		local server = PxlCashRegister.Server.GetByPersistID(id)

		if server then
			server:DeleteAll()
		end

		timer.Simple(0.1, function()
			local server = PxlCashRegister.New "Server" ()
			server:SetName(data.name, true)
			server.persistmod = true

			server.persistid = data.id
			server.can_edit_server = defbool(data.can_edit_server, false)
			server.can_edit_accessory = defbool(data.can_edit_accessory, true)
			server.renting_cost = data.renting_cost or 1000
			server.selling_price = data.selling_price or 800

			server.persistents = {}

			for _, cash_register in pairs(data.cash_registers) do
				local slr = ents.Create(cash_register.class)
				slr:SetPos(cash_register.pos)
				slr:SetAngles(cash_register.ang)
				slr:Spawn()

				table.insert(server.persistents, slr)

				local phys = slr:GetPhysicsObject()
				if IsValid(phys) then
					phys:EnableMotion(false)
				end

				server:AddCashRegister(slr:CashRegister())

				if cash_register.accessories then
					for _, info in pairs(cash_register.accessories) do
						local class = PxlCashRegister.MetaTable[info.type]

						local load = class.Load or PxlCashRegister.MetaTable.Accessory.Load
						if class and load then
							local obj = load(class, info)

							table.insert(server.persistents, obj)

							slr:CashRegister():AddAccessory(obj:Accessory())
						end
					end
				end
			end

			if data.accessories then
				for _, info in pairs(data.accessories) do
					local class = PxlCashRegister.MetaTable[info.type]

					local load = class.Load or PxlCashRegister.MetaTable.Accessory.Load
					if class and load then
						local obj = load(class, info)

						table.insert(server.persistents, obj)

						server:AddAccessory(obj:Accessory())
					end
				end
			end

			if isstring(data.profile) then
				-- TODO Implementer un systeme de profile pour les items enregistré

			else
				for id, item in pairs(data.profile) do
					local itm = PxlCashRegister.New "ItemGroup" (server, id)
					itm.name = item.name
					itm.cost = item.cost
					itm.model = item.model
				end
			end
		end)
	end
end

function Persist.ChangeServerID(old, new)
	local data = Persist.Data[old]

	if Persist.Data[old] and not Persist.Data[new] then
		Persist.Data[new] = Persist.Data[old]
		Persist.Data[old] = nil
		Persist.Data[new].id = new

		local server = PxlCashRegister.Server.GetByPersistID(old)
		if server then
			server.persistid = new
		end

		Persist.Save()
	end
end

function Persist.RemoveServer(id)
	Persist.Data[id] = nil

	Persist.Save()

	local server = PxlCashRegister.Server.GetByPersistID(id)

	if server then
		server:DeleteAll()
	end
end
