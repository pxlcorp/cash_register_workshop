local Config = PxlCashRegister.Config

PxlCashRegister.Language.AddDictionary("info", "en", {
	-- Main menu
	accept_transaction	= "Proceed to the transaction.",
	add_service 		= "Add a service to the shopping cart.",
	clear_cart			= "Clear all articles of the shopping cart.",
	inventory			= "Show and edit any article of the inventory.",
	money				= "Manage and distribute the money and the credit that you earned.",
	option				= "Manage the cash register.",
	more				= "See more option.",
	no_item_in_cart		= "There is no article in the shopping cart.",
	remove_item_cart	= "Remove the article from the shopping cart.",

	-- Inventory

	edit_item 				= "Edit the information of the article.",
	remove_item_inventory 	= "Remove the article from the inventory.",
	clear_inventory 		= "Clear all articles from the inventory.",
	no_item_in_inventory	= "There is no article in the inventory.",

	-- Profile
		show_empty = "Show empty article categories.",
		load_profile = "Load a profile.",
		save_profile = "Save a profile.",
		clear_profile = "Clear the current profile.",
		remove_profile = "Remove a profile.",
		no_profile = "There is no profile.",

	-- Money menu
	credit				= "The money from the bank card.",
	cash				= "The cash in the cash register.\nBe careful, the cash can be stolen!",
	transfer_credit_to 	= "Transfer credit to %s",
	take_money			= "Take cash from the cash register.",
	deposit_money		= "Deposit money to the cash register.",

	-- Option
	employees		= "Manage authorized players and permissions.",
		remove_player		= "Remove the player from authorized players.",
		invitation_pending	= "The player has to accept the invitation.",
		add_player			= "Add the player to authorized players.",
		authorized_player	= "The list of players that's authorized to use this cash register.",
		unauthorized_player	= "The list of players that's not authorized to use this cash register.",
		no_more_player		= "There is no more player to add.",
	accessories	= "Manage accessories",
		accessories_help	= "Allows you to customize the settings of the accessories or to remove them.",
	permission	= "Manage permissions for authorized players.",
	server		= "Manage the cash register information and the link to other.",
		linking_description	= "Enter the information of the other cash register's server.",
		link_description	= "You can link your cash register to a group of cash registers. For that, you need the name and the password of the other cash register's server. But be careful! You may lose the ownership of the cash register.",

		change_server_password	= "Change Password",
		change_server_name		= "Change Name",
		change_server_message	= "Change Message",
	adding_scanner	= "You have to scan the QR code to add a scanner to the system."
})


PxlCashRegister.Language.AddDictionary("accessories", "en", {
	scanner_holded = "Hand scanner",
	scanner_fixed = "Fix scanner",
})
