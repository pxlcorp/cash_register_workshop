local Language = {}
PxlCashRegister.Language = Language
Language.Dictionary = {}

function Language.Translate(tab, index, ...)
	local Config = PxlCashRegister.Config

	local lang = GetConVar("gmod_language"):GetString()

	local words = string.Split(index, ".")
	local dict

	if #words > 1 and Language.Dictionary[words[1]] then
		dict = Language.Dictionary[words[1]]
		tab = table.remove(words, 1)
		index = table.concat(words, ".")
	else
		dict = Language.Dictionary[tab]
	end


	lang = dict[lang] and lang or Config.DefaultLanguage

	local text = index

	if dict[lang] and dict[lang][index] then
		text = dict[lang][index]
	elseif dict[Config.DefaultLanguage] and dict[Config.DefaultLanguage][index] then
		text = dict[Config.DefaultLanguage][index]
	end

	local args = {...}
	for i,v in pairs(args) do
		args[i] = Language.Translate(tab, v)
	end

	return string.format(text, unpack(args))
end

function Language.AddDictionary(tab, lang, dictionary)
	Language.Dictionary[tab] = Language.Dictionary[tab] or {}
	Language.Dictionary[tab][lang] = Language.Dictionary[tab][lang] or {}
	table.Merge(Language.Dictionary[tab][lang], dictionary)
end

function Language.GetDictionary(tab)
	assert(Language.Dictionary[tab], "Pxl Cash Register - Invalid dictionary : " .. tab)

	return function(index, ...)
		return Language.Translate(tab, index, ...)
	end
end

local language_path = "cash_register/language/"

function Language.LoadDictionary()
	local _, dir = file.Find(language_path .. "*", "LUA")

	for k, lang in pairs(dir) do
		local files = file.Find(language_path .. lang .. "/*.lua", "LUA")

		for k, tab in pairs(files) do
			include(language_path .. lang .. "/" .. tab)

			if SERVER then
				AddCSLuaFile(language_path .. lang .. "/" .. tab)
			end
		end
	end
end



local last_lang

if CLIENT then
	timer.Create("PxlCashregister.RefreshLanguage", 0.1, 0, function()
		local lang = GetConVar("gmod_language"):GetString()
		if lang ~= last_lang then
			last_lang = lang

			for _, screen in pairs(PxlCashRegister.Screen.AllScreen) do
				if screen:IsBuilded() and screen:ActiveWindow() then
					local window = screen:ActiveWindow():Name()

					screen:Unlink(true)
					screen:RemovePanel()
					screen:InitPanel(window)
				end
			end
		end
	end)
end