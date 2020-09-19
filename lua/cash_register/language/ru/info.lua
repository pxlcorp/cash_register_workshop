local Config = PxlCashRegister.Config

PxlCashRegister.Language.AddDictionary("info", "ru", {
	-- Main menu
	accept_transaction	= "Перейдите к транзакции.",
	add_service 		= "Добавить услугу в корзину.",
	clear_cart			= "Очистить все статьи корзины.",
	inventory			= "Покажите и отредактируйте любую статью инвентаря.",
	money				= "Управляйте и распределяйте деньги и кредит, который вы заработали.",
	option				= "Управлять кассовым аппаратом.",
	more				= "Смотрите больше вариантов.",
	no_item_in_cart		= "В корзине нет товара.",
	remove_item_cart	= "Удалить товар из корзины.",

	-- Inventory

	edit_item 				= "Редактировать информацию статьи.",
	remove_item_inventory 	= "Удалить статью из инвентаря.",
	clear_inventory 		= "Очистить все предметы из инвентаря.",
	no_item_in_inventory	= "В инвентаре нет статьи.",

	-- Profile
		show_empty = "Показать пустые категории статей.",
		load_profile = "Загрузить профиль.",
		save_profile = "Сохранить профиль.",
		clear_profile = "Очистить текущий профиль.",
		remove_profile = "Удалить профиль.",
		no_profile = "Там нет профиля.",

	-- Money menu
	credit				= "Деньги с банковской карты.",
	cash				= "Наличные в кассе.\nБудьте осторожны, деньги могут быть украдены!",
	transfer_credit_to 	= "Перевести кредит на %s",
	take_money			= "Возьмите наличные в кассе.",
	deposit_money		= "Внести деньги в кассу.",

	-- Option
	employees		= "Управление авторизованными игроками и разрешениями.",
		remove_player		= "Удалить игрока из авторизованных игроков.",
		invitation_pending	= "Игрок должен принять приглашение.",
		add_player			= "Добавьте игрока к авторизованным игрокам.",
		authorized_player	= "Список игроков, которым разрешено использовать этот кассовый аппарат.",
		unauthorized_player	= "Список игроков, которые не имеют права использовать этот кассовый аппарат.",
		no_more_player		= "Нет больше игрока.",
	accessories	= "Управление аксессуарами",
		accessories_help	= "Позволяет настроить параметры аксессуаров или удалить их.",
	permission	= "Управление разрешениями для авторизованных игроков.",
	server		= "Управляйте информацией кассового аппарата и связывайтесь с другими.",
		linking_description	= "Введите информацию о сервере другого кассового аппарата.",
		link_description	= "Вы можете связать свой кассовый аппарат с группой кассовых аппаратов. Для этого вам нужно имя и пароль сервера другого кассового аппарата. Но будь осторожен! Вы можете потерять право собственности на кассу.",

		change_server_password	= "Изменить пароль",
		change_server_name		= "Сменить имя",
		change_server_message	= "Изменить сообщение",
	adding_scanner	= "Вы должны отсканировать QR-код, чтобы добавить сканер в систему."
})


PxlCashRegister.Language.AddDictionary("accessories", "ru", {
	scanner_holded = "Ручной сканер",
	scanner_fixed = "Исправить сканер",
})
