# ==== MAIN CONTROLLER CORREGIDO (Main.gd) ====
extends Control

# Sistema principal
var game_manager: GameManager
var gacha_system: GachaSystem
var battle_system: BattleSystem
var chapter_system: ChapterSystem
var character_menu_system: CharacterMenuSystem

# Interfaces de usuario
var main_menu: Control
var chapter_ui: Control
var team_formation_ui: Control
var battle_ui: Control
var gacha_ui: Control
var inventory_ui: Control
var character_detail_ui: Control

# Estado actual
var current_screen: String = "main_menu"
var selected_chapter: int = 0
var selected_stage: int = 0

func _ready():
	await get_tree().process_frame
	_initialize_systems()
	_initialize_ui()
	_setup_connections()
	_show_screen("main_menu")

func _initialize_systems():
	print("Initializing game systems...")
	
	# Buscar o crear GameManager
	game_manager = get_node_or_null("GameManager")
	if game_manager == null:
		print("Creating GameManager...")
		game_manager = GameManager.new()
		game_manager.name = "GameManager"
		add_child(game_manager)
	
	# Buscar o crear GachaSystem
	gacha_system = get_node_or_null("GachaSystem")
	if gacha_system == null:
		print("Creating GachaSystem...")
		gacha_system = GachaSystem.new()
		gacha_system.name = "GachaSystem"
		add_child(gacha_system)
	
	# Buscar o crear BattleSystem
	battle_system = get_node_or_null("BattleSystem")
	if battle_system == null:
		print("Creating BattleSystem...")
		battle_system = BattleSystem.new()
		battle_system.name = "BattleSystem"
		add_child(battle_system)
	
	# Buscar o crear ChapterSystem
	chapter_system = get_node_or_null("ChapterSystem")
	if chapter_system == null:
		print("Creating ChapterSystem...")
		chapter_system = ChapterSystem.new()
		chapter_system.name = "ChapterSystem"
		add_child(chapter_system)
	
	# Buscar o crear CharacterMenuSystem
	character_menu_system = get_node_or_null("CharacterMenuSystem")
	if character_menu_system == null:
		print("Creating CharacterMenuSystem...")
		character_menu_system = CharacterMenuSystem.new()
		character_menu_system.name = "CharacterMenuSystem"
		add_child(character_menu_system)
	
	print("All systems initialized!")

func _initialize_ui():
	print("Initializing UI...")
	
	# Buscar o crear MainMenu
	main_menu = get_node_or_null("MainMenu")
	if main_menu == null:
		print("Creating MainMenu...")
		main_menu = _create_main_menu()
		add_child(main_menu)
	
	# Buscar o crear otras UI
	chapter_ui = get_node_or_null("ChapterUI")
	if chapter_ui == null:
		print("Creating ChapterUI...")
		chapter_ui = _create_chapter_ui()
		add_child(chapter_ui)
	
	team_formation_ui = get_node_or_null("TeamFormationUI")
	if team_formation_ui == null:
		print("Creating TeamFormationUI...")
		team_formation_ui = _create_team_formation_ui()
		add_child(team_formation_ui)
	
	battle_ui = get_node_or_null("BattleUI")
	if battle_ui == null:
		print("Creating BattleUI...")
		battle_ui = _create_battle_ui()
		add_child(battle_ui)
	
	gacha_ui = get_node_or_null("GachaUI")
	if gacha_ui == null:
		print("Creating GachaUI...")
		gacha_ui = _create_gacha_ui()
		add_child(gacha_ui)
	
	inventory_ui = get_node_or_null("InventoryUI")
	if inventory_ui == null:
		print("Creating InventoryUI...")
		inventory_ui = _create_inventory_ui()
		add_child(inventory_ui)
	
	character_detail_ui = get_node_or_null("CharacterDetailUI")
	if character_detail_ui == null:
		print("Creating CharacterDetailUI...")
		character_detail_ui = _create_character_detail_ui()
		add_child(character_detail_ui)
	
	print("All UI initialized!")
	_initialize_enhanced_starter_characters()

func _create_main_menu() -> Control:
	var menu = Control.new()
	menu.name = "MainMenu"
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(50, 50)
	menu.add_child(vbox)
	
	var title = Label.new()
	title.text = "Epic Gacha RPG"
	title.add_theme_font_size_override("font_size", 32)
	vbox.add_child(title)
	
	var player_info = Label.new()
	player_info.name = "PlayerInfo"
	player_info.text = "Level 1 | Power: 0"
	vbox.add_child(player_info)
	
	var currency_label = Label.new()
	currency_label.name = "CurrencyLabel"
	currency_label.text = "Gold: 2000"
	vbox.add_child(currency_label)
	
	var chapter_button = Button.new()
	chapter_button.name = "ChapterButton"
	chapter_button.text = "Adventure"
	chapter_button.custom_minimum_size = Vector2(200, 50)
	vbox.add_child(chapter_button)
	
	var team_button = Button.new()
	team_button.name = "TeamButton"
	team_button.text = "Team"
	team_button.custom_minimum_size = Vector2(200, 50)
	vbox.add_child(team_button)
	
	var gacha_button = Button.new()
	gacha_button.name = "GachaButton"
	gacha_button.text = "Summon"
	gacha_button.custom_minimum_size = Vector2(200, 50)
	vbox.add_child(gacha_button)
	
	var inventory_button = Button.new()
	inventory_button.name = "InventoryButton"
	inventory_button.text = "Heroes"
	inventory_button.custom_minimum_size = Vector2(200, 50)
	vbox.add_child(inventory_button)
	
	return menu

func _create_chapter_ui() -> Control:
	var ui = Control.new()
	ui.name = "ChapterUI"
	ui.visible = false
	
	var script = load("res://scripts/ChapterSelectionUI.gd")
	ui.set_script(script)
	
	return ui

func _create_team_formation_ui() -> Control:
	var ui = Control.new()
	ui.name = "TeamFormationUI"
	ui.visible = false
	
	var script = load("res://scripts/TeamFormationUI.gd")
	ui.set_script(script)
	
	return ui

func _create_battle_ui() -> Control:
	var ui = Control.new()
	ui.name = "BattleUI"
	ui.visible = false
	
	var script = load("res://scripts/EnhancedBattleUI.gd")
	ui.set_script(script)
	
	return ui

func _create_gacha_ui() -> Control:
	var ui = Control.new()
	ui.name = "GachaUI"
	ui.visible = false
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(50, 50)
	ui.add_child(vbox)
	
	var title = Label.new()
	title.text = "Hero Summon"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var currency_label = Label.new()
	currency_label.name = "CurrencyLabel"
	currency_label.text = "Gold: 2000"
	vbox.add_child(currency_label)
	
	var pity_label = Label.new()
	pity_label.name = "PityLabel"
	pity_label.text = "Pity: 0/90"
	vbox.add_child(pity_label)
	
	var single_pull_button = Button.new()
	single_pull_button.name = "SinglePullButton"
	single_pull_button.text = "Single Summon (100)"
	single_pull_button.custom_minimum_size = Vector2(200, 50)
	vbox.add_child(single_pull_button)
	
	var ten_pull_button = Button.new()
	ten_pull_button.name = "TenPullButton"
	ten_pull_button.text = "10x Summon (900)"
	ten_pull_button.custom_minimum_size = Vector2(200, 50)
	vbox.add_child(ten_pull_button)
	
	var result_label = Label.new()
	result_label.name = "ResultLabel"
	result_label.text = "Results appear here"
	result_label.custom_minimum_size = Vector2(300, 200)
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(result_label)
	
	var back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(100, 40)
	vbox.add_child(back_button)
	
	return ui

func _create_inventory_ui() -> Control:
	var ui = Control.new()
	ui.name = "InventoryUI"
	ui.visible = false
	
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(50, 50)
	ui.add_child(vbox)
	
	var title = Label.new()
	title.text = "Hero Collection"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	var stats_label = Label.new()
	stats_label.name = "StatsLabel"
	stats_label.text = "Total Heroes: 0"
	vbox.add_child(stats_label)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 300)
	vbox.add_child(scroll)
	
	var inventory_list = VBoxContainer.new()
	inventory_list.name = "InventoryList"
	scroll.add_child(inventory_list)
	
	var back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(100, 40)
	vbox.add_child(back_button)
	
	return ui

func _create_character_detail_ui() -> Control:
	var ui = Control.new()
	ui.name = "CharacterDetailUI"
	ui.visible = false
	
	var script = load("res://scripts/CharacterDetailView.gd")
	ui.set_script(script)
	
	return ui

func _setup_connections():
	print("Setting up connections...")
	
	# Main Menu connections
	if main_menu:
		var chapter_btn = main_menu.get_node_or_null("VBoxContainer/ChapterButton")
		var team_btn = main_menu.get_node_or_null("VBoxContainer/TeamButton")
		var gacha_btn = main_menu.get_node_or_null("VBoxContainer/GachaButton")
		var inventory_btn = main_menu.get_node_or_null("VBoxContainer/InventoryButton")
		
		if chapter_btn:
			chapter_btn.pressed.connect(func(): _show_screen("chapters"))
		if team_btn:
			team_btn.pressed.connect(func(): _show_screen("team_formation"))
		if gacha_btn:
			gacha_btn.pressed.connect(func(): _show_screen("gacha"))
		if inventory_btn:
			inventory_btn.pressed.connect(func(): _show_screen("inventory"))
	
	# Chapter system connections
	if chapter_ui and chapter_ui.has_signal("back_pressed"):
		chapter_ui.back_pressed.connect(func(): _show_screen("main_menu"))
		chapter_ui.stage_selected.connect(_on_stage_selected)
	
	# Team formation connections
	if team_formation_ui and team_formation_ui.has_signal("back_pressed"):
		team_formation_ui.back_pressed.connect(func(): _show_screen("main_menu"))
		team_formation_ui.team_updated.connect(_on_team_updated)
	
	# Battle connections
	if battle_system:
		battle_system.turn_started.connect(_on_battle_turn_started)
		battle_system.skill_used.connect(_on_battle_skill_used)
		battle_system.battle_phase_changed.connect(_on_battle_phase_changed)
	
	if game_manager:
		game_manager.battle_ended.connect(_on_battle_ended)
	
	# Gacha connections
	if gacha_ui:
		var single_btn = gacha_ui.get_node_or_null("VBoxContainer/SinglePullButton")
		var ten_btn = gacha_ui.get_node_or_null("VBoxContainer/TenPullButton")
		var back_btn = gacha_ui.get_node_or_null("VBoxContainer/BackButton")
		
		if single_btn:
			single_btn.pressed.connect(_single_pull)
		if ten_btn:
			ten_btn.pressed.connect(_ten_pull)
		if back_btn:
			back_btn.pressed.connect(func(): _show_screen("main_menu"))
	
	# Inventory connections
	if inventory_ui:
		var back_btn = inventory_ui.get_node_or_null("VBoxContainer/BackButton")
		if back_btn:
			back_btn.pressed.connect(func(): _show_screen("main_menu"))
	
	# Character detail connections
	if character_detail_ui and character_detail_ui.has_signal("back_pressed"):
		character_detail_ui.back_pressed.connect(func(): _show_screen("team_formation"))
		character_detail_ui.character_updated.connect(_on_character_updated)
	
	print("Connections setup complete!")

func _initialize_enhanced_starter_characters():
	if not game_manager:
		return
		
	print("Creating starter characters...")
	
	# Limpiar inventario anterior
	game_manager.player_inventory.clear()
	game_manager.player_team.clear()
	
	# Crear personajes iniciales con stats completos
	var warrior = Character.new()
	warrior.setup("Radiant Warrior", 1, Character.Rarity.RARE, Character.Element.RADIANT, 120, 25, 18, 75, 0.15, 1.5)
	
	var mage = Character.new()
	mage.setup("Void Mage", 1, Character.Rarity.RARE, Character.Element.VOID, 90, 30, 12, 85, 0.20, 1.6)
	
	var healer = Character.new()
	healer.setup("Water Priest", 1, Character.Rarity.RARE, Character.Element.WATER, 100, 20, 15, 80, 0.10, 1.4)
	
	# Agregar al inventario
	game_manager.player_inventory.append_array([warrior, mage, healer])
	
	# Equipo inicial
	game_manager.player_team = [warrior, mage]
	
	if character_menu_system:
		character_menu_system.set_team_formation([warrior, mage])

func _show_screen(screen_name: String):
	print("Showing screen: " + screen_name)
	
	# Ocultar todas las pantallas
	_hide_all_screens()
	
	# Mostrar la pantalla solicitada
	match screen_name:
		"main_menu":
			if main_menu:
				main_menu.visible = true
				_update_main_menu_display()
		
		"chapters":
			if chapter_ui:
				chapter_ui.visible = true
		
		"team_formation":
			if team_formation_ui:
				team_formation_ui.visible = true
		
		"battle":
			if battle_ui:
				battle_ui.visible = true
		
		"gacha":
			if gacha_ui:
				gacha_ui.visible = true
				_update_gacha_display()
		
		"inventory":
			if inventory_ui:
				inventory_ui.visible = true
				_update_inventory_display()
		
		"character_detail":
			if character_detail_ui:
				character_detail_ui.visible = true
	
	current_screen = screen_name

func _hide_all_screens():
	if main_menu:
		main_menu.visible = false
	if chapter_ui:
		chapter_ui.visible = false
	if team_formation_ui:
		team_formation_ui.visible = false
	if battle_ui:
		battle_ui.visible = false
	if gacha_ui:
		gacha_ui.visible = false
	if inventory_ui:
		inventory_ui.visible = false
	if character_detail_ui:
		character_detail_ui.visible = false

func _update_main_menu_display():
	if not main_menu or not game_manager:
		return
		
	var currency_label = main_menu.get_node_or_null("VBoxContainer/CurrencyLabel")
	var player_info = main_menu.get_node_or_null("VBoxContainer/PlayerInfo")
	
	if currency_label:
		currency_label.text = "Gold: " + str(game_manager.game_currency)
	
	if player_info:
		player_info.text = "Level: " + str(game_manager.player_level) + " | Team Power: " + str(_calculate_team_power())

func _calculate_team_power() -> int:
	if not game_manager:
		return 0
		
	var power = 0
	for character in game_manager.player_team:
		power += character.max_hp + character.attack * 5 + character.defense * 3
	return power

# ==== EVENT HANDLERS ====

func _on_stage_selected(chapter_id: int, stage_id: int):
	selected_chapter = chapter_id
	selected_stage = stage_id
	_start_stage_battle(chapter_id, stage_id)

func _start_stage_battle(chapter_id: int, stage_id: int):
	if not chapter_system or not game_manager:
		print("Error: Missing systems for battle")
		return
		
	var chapter_data = chapter_system.get_chapter_data(chapter_id)
	if chapter_data == null:
		print("Chapter not found!")
		return
	
	var stage_data = chapter_data.get_stage(stage_id)
	if stage_data == null:
		print("Stage not found!")
		return
	
	# Verificar que el equipo esté listo
	if game_manager.player_team.is_empty():
		print("No team selected!")
		return
	
	# Iniciar batalla
	var enemies = stage_data.enemies.duplicate()
	if battle_system:
		battle_system.start_battle(game_manager.player_team, enemies)
	_show_screen("battle")

func _on_team_updated():
	if current_screen == "main_menu":
		_update_main_menu_display()

func _on_battle_turn_started(character: Character):
	print(character.character_name + "'s turn started")

func _on_battle_skill_used(caster: Character, skill: Skill, targets: Array[Character], results: Array):
	print("Skill used: " + skill.skill_name + " by " + caster.character_name)

func _on_battle_phase_changed(phase):
	print("Battle phase changed to: " + str(phase))

func _on_battle_ended(result):
	if result == GameManager.BattleResult.VICTORY:
		_handle_stage_victory()
	else:
		_handle_stage_defeat()

func _handle_stage_victory():
	if not chapter_system or not game_manager:
		return
		
	# Completar stage y dar recompensas
	var rewards = chapter_system.complete_stage(selected_chapter, selected_stage)
	
	if rewards:
		# Aplicar recompensas
		game_manager.add_currency(rewards.gold)
		print("Stage completed! Rewards: " + str(rewards.gold) + " gold, " + str(rewards.experience) + " exp")
	
	# Regresar al menú después de un tiempo
	await get_tree().create_timer(3.0).timeout
	_show_screen("chapters")

func _handle_stage_defeat():
	print("Stage failed!")
	await get_tree().create_timer(2.0).timeout
	_show_screen("chapters")

func _on_character_updated():
	if current_screen == "team_formation":
		pass  # La UI se actualiza automáticamente

# ==== GACHA FUNCTIONS ====

func _single_pull():
	if not game_manager or not gacha_system:
		return
		
	if game_manager.game_currency >= 100:
		game_manager.game_currency -= 100
		var new_character = gacha_system.single_pull()
		game_manager.player_inventory.append(new_character)
		_show_gacha_result([new_character])
	else:
		_show_insufficient_currency_message()

func _ten_pull():
	if not game_manager or not gacha_system:
		return
		
	if game_manager.game_currency >= 900:
		game_manager.game_currency -= 900
		var new_characters = gacha_system.ten_pull()
		game_manager.player_inventory.append_array(new_characters)
		_show_gacha_result(new_characters)
	else:
		_show_insufficient_currency_message()

func _show_gacha_result(characters: Array[Character]):
	if not gacha_ui:
		return
		
	var result_text = "You got:\n\n"
	
	for character in characters:
		var rarity_name = Character.Rarity.keys()[character.rarity]
		var element_name = character.get_element_name()
		result_text += character.character_name + "\n"
		result_text += "  " + rarity_name + " | " + element_name + "\n"
		result_text += "  Power: " + str(_calculate_character_power(character)) + "\n\n"
	
	var result_label = gacha_ui.get_node_or_null("VBoxContainer/ResultLabel")
	if result_label:
		result_label.text = result_text
	
	_update_gacha_display()

func _calculate_character_power(character: Character) -> int:
	return character.max_hp + character.attack * 5 + character.defense * 3

func _show_insufficient_currency_message():
	var popup = AcceptDialog.new()
	popup.dialog_text = "Insufficient gold!"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

func _update_gacha_display():
	if not gacha_ui or not game_manager or not gacha_system:
		return
		
	var currency_label = gacha_ui.get_node_or_null("VBoxContainer/CurrencyLabel")
	var pity_label = gacha_ui.get_node_or_null("VBoxContainer/PityLabel")
	
	if currency_label:
		currency_label.text = "Gold: " + str(game_manager.game_currency)
	
	if pity_label:
		pity_label.text = "Pity: " + str(gacha_system.pity_counter) + "/90"

# ==== INVENTORY FUNCTIONS ====

func _update_inventory_display():
	if not inventory_ui or not game_manager:
		return
		
	var inventory_list = inventory_ui.get_node_or_null("VBoxContainer/ScrollContainer/InventoryList")
	var stats_label = inventory_ui.get_node_or_null("VBoxContainer/StatsLabel")
	
	if stats_label:
		stats_label.text = "Total Heroes: " + str(game_manager.player_inventory.size())
	
	if not inventory_list:
		return
		
	# Limpiar lista existente
	for child in inventory_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Ordenar personajes por poder
	var sorted_characters = game_manager.player_inventory.duplicate()
	sorted_characters.sort_custom(func(a, b): return _calculate_character_power(a) > _calculate_character_power(b))
	
	# Crear entradas para cada personaje
	for character in sorted_characters:
		var character_entry = _create_inventory_entry(character)
		inventory_list.add_child(character_entry)

func _create_inventory_entry(character: Character) -> Control:
	var entry = Button.new()
	entry.custom_minimum_size = Vector2(380, 60)
	
	var entry_text = character.character_name + " Lv." + str(character.level) + "\n"
	entry_text += character.get_element_name() + " | Power: " + str(_calculate_character_power(character))
	entry_text += " | HP: " + str(character.max_hp) + " ATK: " + str(character.attack)
	
	entry.text = entry_text
	entry.modulate = character.get_rarity_color()
	
	# Indicador si está en el equipo
	if character in game_manager.player_team:
		entry.text += " ★"
	
	return entry
