local Config = {}
PxlCashRegister.Config = Config

-- The money format of a display - ex:
	-- "£%.2f" £231 123.43
	-- "%.2f$" 231 123.43$
	-- "%.2f€" 231 123.43€
	-- "¥%.2f" ¥231 123.43
	-- "%.2f credit" 231 123.43 credit
Config.MoneyFormat = "$%.2f"

function Config.LongNumberFormat(num)
	return num
end




-- Money style avalable: USD and EUR
Config.MoneyStyle = "USD"

Config.DefaultLanguage = "en"

-- The maximum distance to interact with the screen
Config.ScreenRange = 50

-- The delay sell automaticly a system after a player leave
Config.ResetTime = 10

-- The theme of the interface
-- 		(The only avalable is the "New" them)
Config.Theme = "New"

-- You can edit the color of the theme there
	-- You can go there: https://www.w3schools.com/colors/colors_picker.asp
	-- to get a color in hex
Config.ThemeAccentColor = "34495e"
Config.ThemePrimaryColor = "fff"
Config.ThemeSecondaryColor = "ececec"



-- For lua scripter
	-- This function determine if a player is able to have the admin access
if SERVER then
	function Config.IsAdmin(ply)
		return ply:IsAdmin()
	end
end
-- end


-- The listing for the DarkRP
	-- If you want to change the name of these items in the darkrp menu, you need to change it there
hook.Add("InitPostEntity","PxlCashRegister",function()
	DarkRP.createEntity(
		"Pxl Cash Register", -- cn: 收银机, ru: Кассовый аппарат
		{
			ent	= "pxl_cash_register",
			model = "models/pxl/cash_register_pxl/cash_register_pxl.mdl",
			max = 5,
			price = 5000,
			cmd = "buy_pxlcashregister"
		}
	)

	DarkRP.createEntity(
		"Pxl Scanner Holder", -- cn: 手持扫描设备, ru: Держатель сканера
		{
			ent	= "pxl_scanne_holder",
			model = "models/pxl/hand_scanner/pxl_scanner_main_ref.mdl",
			max = 5,
			price = 100,
			cmd = "buy_pxlscannerholder"
		}
	)

	DarkRP.createEntity(
		"Pxl Fixed Scanner", -- cn : 固定扫描器, ru: Фиксированный сканер
		{
			ent	= "pxl_fixed_scanne",
			model = "models/pxl/fix_scanner/scanner_fix_ref.mdl",
			max = 5,
			price = 100,
			cmd = "buy_pxlfixedscanner"
		}
	)
end)


Config.ARCBankErrorEnum = {
	[4]		= "arcbank_error_no_cash_player",
	[3]		= "arcbank_error_no_cash",
	[2]		= "arcbank_error_no_access",
	[1]		= "arcbank_error_nil_account",
	[5]		= "arcbank_error_player_forever_alone",
	[6]		= "arcbank_error_nil_player",
	[7]		= "arcbank_error_dupe_player",
	[8]		= "arcbank_error_too_much_cash",
	[9]		= "arcbank_error_debt",
	[10]	= "arcbank_error_busy",
	[11]	= "arcbank_error_timeout",
	[12]	= "arcbank_error_read_failure",
	[16]	= "arcbank_error_write_failure",
	[13]	= "arcbank_error_invalid_pin",
	[14]	= "arcbank_error_chunk_mismatch",
	[15]	= "arcbank_error_chunk_timeout",
	[17]	= "arcbank_error_exploit",
	[18]	= "arcbank_error_download_failed",
	[32]	= "arcbank_error_name_dupe",
	[33]	= "arcbank_error_name_too_long",
	[34]	= "arcbank_error_invalid_name",
	[35]	= "arcbank_error_underling",
	[36]	= "arcbank_error_invalid_rank",
	[37]	= "arcbank_error_too_many_accounts",
	[38]	= "arcbank_error_too_many_players",
	[39]	= "arcbank_error_delete_refused",
	[-127]	= "arcbank_error_not_loaded",
	[-128]	= "arcbank_error_unknown",
}
