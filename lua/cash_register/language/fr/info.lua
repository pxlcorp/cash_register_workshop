local Config = PxlCashRegister.Config

PxlCashRegister.Language.AddDictionary("info", "fr", {
	-- Main menu
	accept_transaction	= "Procéder à la transaction.",
	add_service 		= "Ajouter un service au panier.",
	clear_cart			= "Effacer tous les articles du panier.",
	inventory			= "Afficher et éditer n'importe quel article de l'inventaire.",
	money				= "Gérez et distribuez l'argent et le crédit que vous avez gagnés.",
	option				= "Gérer la caisse enregistreuse.",
	more				= "Voir plus d'option.",
	no_item_in_cart		= "Il n'y a pas d'article dans le panier.",
	remove_item_cart	= "Retire l'article du panier.",

	-- Inventory

	edit_item 				= "Modifiez les informations de l'article.",
	remove_item_inventory 	= "Supprimer l'article de l'inventaire.",
	clear_inventory 		= "Effacer tous les articles de l'inventaire.",
	no_item_in_inventory	= "Il n'y a pas d'article dans l'inventaire.",

	-- Profile
		show_empty = "Afficher les catégories d'articles vides.",
		load_profile = "Charger un profil.",
		save_profile = "Enregistrer un profil.",
		clear_profile = "Effacer le profil actuel.",
		remove_profile = "Supprimer un profil.",
		no_profile = "Il n'y a pas de profil.",

	-- Money menu
	credit				= "L'argent de la carte bancaire.",
	cash				= "L'argent dans la caisse.\nAttention, l'argent peut être volé!",
	transfer_credit_to 	= "Virement de crédit vers %s",
	take_money			= "Prendre de l'argent à la caisse.",
	deposit_money		= "Déposez de l'argent à la caisse.",

	-- Option
	employees		= "Gérer les joueurs autorisés et les permissions.",
		remove_player		= "Retirer le joueur des joueurs autorisés.",
		invitation_pending	= "Le joueur doit accepter l'invitation.",
		add_player			= "Ajouter le joueur aux joueurs autorisés.",
		authorized_player	= "La liste des joueurs autorisés à utiliser cette caisse enregistreuse.",
		unauthorized_player	= "La liste des joueurs non autorisés à utiliser cette caisse enregistreuse.",
		no_more_player		= "Il n'y a plus de joueur à ajouter.",
	accessories	= "Gérer les accessoires",
		accessories_help	= "Vous permet de personnaliser les paramètres des accessoires ou de les supprimer.",
	permission	= "Gérer les autorisations pour les joueurs autorisés.",
	server		= "Gérer les informations de la caisse et le lien vers d’autres.",
		linking_description	= "Entrez les informations du serveur de l'autre caisse enregistreuse.",
		link_description	= "Vous pouvez lier votre caisse à un groupe de caisses enregistreuses. Pour cela, vous avez besoin du nom et du mot de passe du serveur de l'autre caisse enregistreuse. Mais fais attention! Vous pouvez perdre la propriété de la caisse enregistreuse.",

		change_server_password	= "Changer le mot de passe",
		change_server_name		= "Changer de nom",
		change_server_message	= "Changer le message",
	adding_scanner	= "Vous devez scanner le code QR pour ajouter un scanner au système."
})
