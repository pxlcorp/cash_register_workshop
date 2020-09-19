local Config = PxlCashRegister.Config

PxlCashRegister.Language.AddDictionary("info", "zh-CN", {
	-- Main menu
	accept_transaction	= "继续进行交易。",
	add_service 		= "将服务添加到购物车。",
	clear_cart			= "清除购物车的所有文章。",
	inventory			= "显示和编辑库存的任何文章。",
	money				= "管理和分配您赚取的金钱和信用。",
	option				= "管理收银机。",
	more				= "查看更多选项。",
	no_item_in_cart		= "购物车中没有文章。",
	remove_item_cart	= "从购物车中删除文章。",
	
	-- Inventory
	
	edit_item 				= "编辑文章的信息。",
	remove_item_inventory 	= "从清单中删除该文章。",
	clear_inventory 		= "清除广告资源中的所有文章。",
	no_item_in_inventory	= "清单中没有文章。",

	-- Profile
		show_empty = "显示空文章类别。",
		load_profile = "加载配置文件。",
		save_profile = "保存个人资料。",
		clear_profile = "清除当前配置文件。",
		remove_profile = "删除个人资料。",
		no_profile = "没有个人资料。",

	-- Money menu
	credit				= "银行卡的钱。",
	cash				= "收银机中的现金。\n小心，现金可以被盗！",
	transfer_credit_to 	= "将信用转给%s",
	take_money			= "从收银台拿现金。",
	deposit_money		= "存钱到收银台。",
	
	-- Option
	employees		= "管理授权玩家和权限。",
		remove_player		= "从授权玩家中移除播放器。",
		invitation_pending	= "玩家必须接受邀请。",
		add_player			= "将玩家添加到授权玩家。",
		authorized_player	= "有权使用此收银机的玩家列表。",
		unauthorized_player	= "未授权使用此收银机的玩家列表。",
		no_more_player		= "没有更多的玩家可以添加。",
	accessories	= "管理配件",
		accessories_help	= "允许您自定义附件的设置或删除它们。",
	permission	= "管理授权玩家的权限。",
	server		= "管理收银机信息和其他链接。",
		linking_description	= "输入其他收银机服务器的信息。",
		link_description	= "您可以将收银机链接到一组收银机。 为此，您需要其他收银机服务器的名称和密码。 不过要小心！ 您可能会失去收银机的所有权。",
	
		change_server_password	= "更改密码",
		change_server_name		= "更换名字",
		change_server_message	= "改变消息",
	adding_scanner	= "您必须扫描QR码才能将扫描仪添加到系统中。"
})


PxlCashRegister.Language.AddDictionary("accessories", "zh-CN", {
	scanner_holded = "手扫描仪",
	scanner_fixed = "修复扫描仪",
})