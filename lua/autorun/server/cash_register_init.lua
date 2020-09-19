PxlCashRegister          	= {}
PxlCashRegister.MetaTable	= {}

-- resource.AddWorkshop("861757645")

-- Included Files
AddCSLuaFile("cash_register/includes/vgui3d2d.lua")

include("cash_register/config.lua")
AddCSLuaFile("cash_register/config.lua")

-- Core
AddCSLuaFile("cash_register/core/shared/language.lua")

AddCSLuaFile("cash_register/core/client/object.lua")
AddCSLuaFile("cash_register/core/client/main.lua")
AddCSLuaFile("cash_register/core/client/scanner.lua")
AddCSLuaFile("cash_register/core/client/tab_panel.lua")
AddCSLuaFile("cash_register/core/client/window.lua")
AddCSLuaFile("cash_register/core/client/screen.lua")
AddCSLuaFile("cash_register/core/client/user_screen.lua")
AddCSLuaFile("cash_register/core/client/customer_screen.lua")
AddCSLuaFile("cash_register/core/client/price_screen.lua")
AddCSLuaFile("cash_register/core/shared/profile.lua")


include("cash_register/core/shared/language.lua")
PxlCashRegister.Language.LoadDictionary()

include("cash_register/core/server/object.lua")
include("cash_register/core/server/util.lua")
include("cash_register/core/server/main.lua")
include("cash_register/core/server/accessory.lua")
include("cash_register/core/server/scanner.lua")
include("cash_register/core/server/server.lua")
include("cash_register/core/server/cash_register.lua")
include("cash_register/core/server/persist.lua")
include("cash_register/core/shared/profile.lua")

local menu_path = "cash_register/core/client/user_screen_menus/"
local files, folders = file.Find(menu_path .. "*", "LUA")
for _, f in pairs(files) do
	AddCSLuaFile(menu_path .. f)
end

for _, folder in pairs(folders) do
	local menu_path = "cash_register/core/client/user_screen_menus/" .. folder .. "/"
	local files, __ = file.Find(menu_path .. "*", "LUA")
	for _, f in pairs(files) do
		AddCSLuaFile(menu_path .. f)
	end
end

local menu_path = "cash_register/core/client/customer_screen_menu/"
local files, folders = file.Find(menu_path .. "*", "LUA")
for _, f in pairs(files) do
	AddCSLuaFile(menu_path .. f)
end

local theme_path = "cash_register/core/client/theme/"
local files, _ = file.Find(theme_path .. "*", "LUA")
for _, f in pairs(files) do
	AddCSLuaFile(theme_path .. f)
end

local articles_path = "cash_register/core/server/articles/"
local files, _ = file.Find(articles_path .. "*", "LUA")
for _, f in pairs(files) do
	include(articles_path .. f)
end

local custom_path = "cash_register/custom/"
local _, dir = file.Find(custom_path .. "*", "LUA")
for k, ext in pairs(dir) do
	local ext_path = custom_path .. ext .. "/"

	if file.Exists(ext_path .. "init.lua", "LUA") then
		include(ext_path .. "init.lua")
	end

	if file.Exists(ext_path .. "cl_init.lua", "LUA") then
		AddCSLuaFile(ext_path .. "cl_init.lua")
	end

	if file.Exists(ext_path .. "shared.lua", "LUA") then
		include(ext_path .. "shared.lua")
		AddCSLuaFile(ext_path .. "shared.lua")
	end
end


PxlCashRegister.Modules = {}
PxlCashRegister.Modules.Payments = {}
PxlCashRegister.Modules.Transfers = {}

local module_path = "cash_register/modules/"
local files, _ = file.Find(module_path .. "*", "LUA")
for _, f in pairs(files) do
	include(module_path .. f)
	AddCSLuaFile(module_path .. f)
end


PxlCashRegister.Persist.Init()
PxlCashRegister.Persist.Load()


sound.Add({
	name = "PxlCashRegister.Scan",
	channel = CHAN_STATIC,
	volume = 1,
	level = 50,
	pitch = 100,
	sound = "pxl/cash_register/scan.ogg"
})

sound.Add({
	name = "PxlCashRegister.Drawer",
	channel = CHAN_STATIC,
	volume = 1,
	level = 70,
	pitch = 100,
	sound = "pxl/cash_register/drawer.ogg"
})

sound.Add({
	name = "PxlCashRegister.Print",
	channel = CHAN_STATIC,
	volume = 1,
	level = 60,
	pitch = 100,
	sound = "pxl/cash_register/print.ogg"
})

sound.Add({
	name = "PxlCashRegister.Click",
	channel = CHAN_STATIC,
	volume = 1,
	level = 50,
	pitch = 100,
	sound = "pxl/cash_register/click.ogg"
})

sound.Add({
	name = "PxlCashRegister.Typing",
	channel = CHAN_STATIC,
	volume = 1,
	level = 50,
	pitch = {80, 120},
	sound = "pxl/cash_register/typing.ogg"
})

sound.Add({
	name = "PxlCashRegister.Transition",
	channel = CHAN_STATIC,
	volume = 1,
	level = 60,
	pitch = {80, 120},
	sound = "pxl/cash_register/transition.ogg"
})
