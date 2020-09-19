local Profile = {}
PxlCashRegister.Profile = Profile

local _path = "pxlcorp"

--[[
	Load a profile from a file

	@param id string - The id of the profile
	@return table|string - The loaded profile or return a error if there is something wrong
]]
function Profile.LoadProfile(id)
	local f = file.Read(_path .. "/profiles/" .. id .. ".txt")

	if f then
		return util.JSONToTable(f)
	else
		return "no_profile_found"
	end
end

--[[
	Save a profile in a file named by the id

	@param id string - The id of the profile
	@param profile table - The profile to save
	@return void/string - return a error if there is something wrong
]]
function Profile.SaveProfile(id, profile)
	if not file.Exists(_path .. "/profiles", "DATA") then
		file.CreateDir(_path .. "/profiles")
	end
	
	file.Write(_path .. "/profiles/" .. id .. ".txt", util.TableToJSON(profile, true))
end

--[[
	Get all files name

	@return table - return the list of files
]]
function Profile.GetProfilesList()
	local profiles = {}

	local files, _ = file.Find(_path .. "/profiles/*", "DATA")
	for _, f in pairs(files) do
		table.insert(profiles, string.Explode(".", f)[1])
	end

	return profiles
end

--[[
	Remove profile file by id

	@param string - The id of the profile to remove
]]
function Profile.RemoveProfile(id)
	file.Delete(_path .. "/profiles/" .. id .. ".txt")
end


if SERVER then
	function Profile.ValidateProfile(profile)
		for id, item in pairs(profile) do
			if not isstring(id) and
					not isstring(item.name) and
					not isnumber(item.cost) and
					not (not item.model or isstring(item.model)) then

				return false
			end
		end

		return true
	end

	function Profile.InportProfile(server, profile)
		for id, item in pairs(profile) do
			local itm = PxlCashRegister.New "Category" (server, id)
			itm.name = item.name
			itm.cost = item.cost
			itm.model = item.model
		end
	end

	function Profile.ExportProfile(server)
		local profile = {}

		for id, group in pairs(server.groups) do
			if group.name ~= "#" .. id then
				profile[id] = {
					name = group.name,
					cost = group.cost,
					model = group.model
				}
			end
		end

		return profile
	end
end
