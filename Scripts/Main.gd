# ==== MAIN CONTROLLER FIXED (Main.gd) ====
extends Control

# Sistema principal
var game_manager: GameManager
var gacha_system: GachaSystem
var battle_system: BattleSystem
var chapter_system: ChapterSystem
var character_menu_system: CharacterMenuSystem
var equipment_manager: EquipmentManager

# Interfaces de usuario (desde la escena)
@onready var main_menu = $MainMenu
@onready var chapter_ui = $ChapterUI
@onready var team_formation_ui = $TeamFormationUI
@onready var battle_ui = $BattleUI
@onready var gacha_ui = $GachaUI
@onready var inventory_ui = $InventoryUI
@onready var character_detail_ui = $CharacterDetailUI

# Estado actual
var current_screen: String = "main_menu"
var selected_chapter: int = 0
var selected_stage: int = 0

func _ready():
	print("=== STARTING GAME INITIALIZATION ===")
	print("Initializing game systems...")

	game_manager = get_node_or_null("GameManager")
	gacha_system = get_node_or_null("GachaSystem")
	battle_system = get_node_or_null("BattleSystem")

	main_menu = get_node_or_null("MainMenu")

	_setup_connections()
	_initialize_enhanced_starter_characters()  # Agregar esta línea
	print("Main.gd _ready() finished.")

	# Mostrar menú inicial claramente
	_show_screen("main_menu")

func _diagnose_input_blockers(node: Node, depth: int):
	if node is Control:
		var control_node = node as Control
		if control_node.mouse_filter != Control.MOUSE_FILTER_IGNORE and control_node.visible:
			print("Overlay posible detectado → ", "-".repeat(depth), node.get_path(), ", Visible: ", control_node.visible, ", Mouse filter: ", control_node.mouse_filter)

	for child in node.get_children():
		_diagnose_input_blockers(child, depth + 1)

func _initialize_systems():
	print("Initializing game systems...")
	
	# GameManager ya existe en la escena
	game_manager = $GameManager
	if game_manager == null:
		print("ERROR: GameManager not found in scene!")
		return
	else:
		print("✓ GameManager found")
	
	# GachaSystem ya existe en la escena
	gacha_system = $GachaSystem
	if gacha_system == null:
		print("ERROR: GachaSystem not found in scene!")
		return
	else:
		print("✓ GachaSystem found")
	
	# BattleSystem ya existe en la escena
	battle_system = $BattleSystem
	if battle_system == null:
		print("ERROR: BattleSystem not found in scene!")
		return
	else:
		print("✓ BattleSystem found")
	
	# Crear sistemas faltantes
	chapter_system = ChapterSystem.new()
	chapter_system.name = "ChapterSystem"
	add_child(chapter_system)
	print("✓ ChapterSystem created")
	
	character_menu_system = CharacterMenuSystem.new()
	character_menu_system.name = "CharacterMenuSystem"
	add_child(character_menu_system)
	print("✓ CharacterMenuSystem created")
	
	equipment_manager = EquipmentManager.new()
	equipment_manager.name = "EquipmentManager"
	add_child(equipment_manager)
	print("✓ EquipmentManager created")
	
	print("All systems initialized!")

func _setup_ui_references():
	print("Setting up UI references...")
	
	# Debug: Verificar que las UI existen
	print("MainMenu exists: ", main_menu != null)
	print("ChapterUI exists: ", chapter_ui != null)
	print("TeamFormationUI exists: ", team_formation_ui != null)
	print("BattleUI exists: ", battle_ui != null)
	print("GachaUI exists: ", gacha_ui != null)
	print("InventoryUI exists: ", inventory_ui != null)
	print("CharacterDetailUI exists: ", character_detail_ui != null)
	
	# Las referencias ya están configuradas con @onready
	# Solo necesitamos configurar elementos internos que falten
	
	# Configurar elementos faltantes en ChapterUI
	if chapter_ui and not chapter_ui.has_node("VBoxContainer"):
		_setup_chapter_ui_structure()
	
	# Configurar elementos faltantes en TeamFormationUI
	if team_formation_ui and not team_formation_ui.has_node("HBoxContainer"):
		_setup_team_formation_ui_structure()
	
	# Configurar elementos faltantes en CharacterDetailUI
	if character_detail_ui and not character_detail_ui.has_node("VBoxContainer"):
		_setup_character_detail_ui_structure()

func _setup_chapter_ui_structure():
	# Ya tiene estructura en la escena, solo asegurar que esté completa
	var vbox = chapter_ui.get_node_or_null("VBoxContainer")
	if not vbox:
		vbox = VBoxContainer.new()
		vbox.position = Vector2(50, 50)
		chapter_ui.add_child(vbox)
		
		var title = Label.new()
		title.text = "Adventure"
		title.add_theme_font_size_override("font_size", 24)
		vbox.add_child(title)
		
		var scroll = ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(400, 300)
		vbox.add_child(scroll)
		
		var chapter_list = VBoxContainer.new()
		chapter_list.name = "ChapterList"
		scroll.add_child(chapter_list)
		
		var chapter_info = Label.new()
		chapter_info.name = "ChapterInfo"
		chapter_info.custom_minimum_size = Vector2(400, 100)
		vbox.add_child(chapter_info)
		
		var back_button = Button.new()
		back_button.name = "BackButton"
		back_button.text = "Back"
		vbox.add_child(back_button)

func _setup_team_formation_ui_structure():
	# Estructura ya existe en la escena
	pass

func _setup_character_detail_ui_structure():
	# Crear estructura completa para CharacterDetailUI
	var vbox = VBoxContainer.new()
	vbox.position = Vector2(50, 50)
	character_detail_ui.add_child(vbox)
	
	# Los otros elementos serán creados por CharacterDetailView.gd

func _setup_connections():
	print("\n=== Setting up connections ===")
	
	# Main Menu connections
	if main_menu:
		print("Setting up MainMenu connections...")
		var vbox = main_menu.get_node_or_null("VBoxContainer")
		if not vbox:
			print("ERROR: VBoxContainer not found in MainMenu!")
			return
			
		var chapter_btn = vbox.get_node_or_null("ChapterButton")
		var team_btn = vbox.get_node_or_null("TeamButton")
		var gacha_btn = vbox.get_node_or_null("GachaButton")
		var inventory_btn = vbox.get_node_or_null("InventoryButton")
		
		# Debug print
		print("ChapterButton found: ", chapter_btn != null)
		print("TeamButton found: ", team_btn != null)
		print("GachaButton found: ", gacha_btn != null)
		print("InventoryButton found: ", inventory_btn != null)
		
		# Conectar señales
		if chapter_btn:
			chapter_btn.pressed.connect(_on_chapter_button_pressed)
			print("✓ ChapterButton connected")
		else:
			print("ERROR: ChapterButton not found!")
			
		if team_btn:
			team_btn.pressed.connect(_on_team_button_pressed)
			print("✓ TeamButton connected")
		else:
			print("ERROR: TeamButton not found!")
			
		if gacha_btn:
			gacha_btn.pressed.connect(_on_gacha_button_pressed)
			print("✓ GachaButton connected")
		else:
			print("ERROR: GachaButton not found!")
			
		if inventory_btn:
			inventory_btn.pressed.connect(_on_inventory_button_pressed)
			print("✓ InventoryButton connected")
		else:
			print("ERROR: InventoryButton not found!")
	else:
		print("ERROR: MainMenu is null!")
	
	# Chapter system connections
	if chapter_ui and chapter_ui.has_signal("back_pressed"):
		if not chapter_ui.back_pressed.is_connected(_on_chapter_back_pressed):
			chapter_ui.back_pressed.connect(_on_chapter_back_pressed)
		if not chapter_ui.stage_selected.is_connected(_on_stage_selected):
			chapter_ui.stage_selected.connect(_on_stage_selected)
	
	# Team formation connections
	if team_formation_ui and team_formation_ui.has_signal("back_pressed"):
		if not team_formation_ui.back_pressed.is_connected(_on_team_back_pressed):
			team_formation_ui.back_pressed.connect(_on_team_back_pressed)
		if not team_formation_ui.team_updated.is_connected(_on_team_updated):
			team_formation_ui.team_updated.connect(_on_team_updated)
	
	# Battle connections
	if battle_system:
		if not battle_system.turn_started.is_connected(_on_battle_turn_started):
			battle_system.turn_started.connect(_on_battle_turn_started)
		if not battle_system.skill_used.is_connected(_on_battle_skill_used):
			battle_system.skill_used.connect(_on_battle_skill_used)
		if not battle_system.battle_phase_changed.is_connected(_on_battle_phase_changed):
			battle_system.battle_phase_changed.connect(_on_battle_phase_changed)
	
	if game_manager:
		if not game_manager.battle_ended.is_connected(_on_battle_ended):
			game_manager.battle_ended.connect(_on_battle_ended)
		if not game_manager.currency_changed.is_connected(_on_currency_changed):
			game_manager.currency_changed.connect(_on_currency_changed)
		if not game_manager.player_level_changed.is_connected(_on_player_level_changed):
			game_manager.player_level_changed.connect(_on_player_level_changed)
	
	# Gacha connections
	if gacha_ui:
		var single_btn = gacha_ui.get_node("VBoxContainer/SinglePullButton")
		var ten_btn = gacha_ui.get_node("VBoxContainer/TenPullButton")
		var back_btn = gacha_ui.get_node("VBoxContainer/BackButton")
		
		if single_btn and not single_btn.pressed.is_connected(_single_pull):
			single_btn.pressed.connect(_single_pull)
		if ten_btn and not ten_btn.pressed.is_connected(_ten_pull):
			ten_btn.pressed.connect(_ten_pull)
		if back_btn and not back_btn.pressed.is_connected(_on_gacha_back_pressed):
			back_btn.pressed.connect(_on_gacha_back_pressed)
	
	# Inventory connections
	if inventory_ui:
		var back_btn = inventory_ui.get_node("VBoxContainer/BackButton")
		if back_btn and not back_btn.pressed.is_connected(_on_inventory_back_pressed):
			back_btn.pressed.connect(_on_inventory_back_pressed)
		
		# Agregar StatsLabel si no existe
		var stats_label = inventory_ui.get_node_or_null("VBoxContainer/StatsLabel")
		if not stats_label:
			stats_label = Label.new()
			stats_label.name = "StatsLabel"
			stats_label.text = "Total Heroes: 0"
			# Insertar después del título
			inventory_ui.get_node("VBoxContainer").add_child(stats_label)
			inventory_ui.get_node("VBoxContainer").move_child(stats_label, 1)
	
	# Character detail connections
	if character_detail_ui and character_detail_ui.has_signal("back_pressed"):
		if not character_detail_ui.back_pressed.is_connected(_on_character_detail_back_pressed):
			character_detail_ui.back_pressed.connect(_on_character_detail_back_pressed)
		if not character_detail_ui.character_updated.is_connected(_on_character_updated):
			character_detail_ui.character_updated.connect(_on_character_updated)
	
	print("Connections setup complete!")

# Button handlers separados para mejor organización
func _on_chapter_button_pressed():
	print("Chapter button pressed!")
	_show_screen("chapters")

func _on_team_button_pressed():
	print("Team button pressed!")
	_show_screen("team_formation")

func _on_gacha_button_pressed():
	print("Gacha button pressed!")
	_show_screen("gacha")

func _on_inventory_button_pressed():
	print("Inventory button pressed!")
	_show_screen("inventory")

func _on_chapter_back_pressed():
	_show_screen("main_menu")

func _on_team_back_pressed():
	_show_screen("main_menu")

func _on_gacha_back_pressed():
	_show_screen("main_menu")

func _on_inventory_back_pressed():
	_show_screen("main_menu")

func _on_character_detail_back_pressed():
	_show_screen("team_formation")

func _on_currency_changed(new_amount: int):
	_update_currency_displays()

func _on_player_level_changed(new_level: int):
	_update_main_menu_display()

func _initialize_enhanced_starter_characters():
	if not game_manager:
		return
		
	print("Loading characters from Data folder...")
	
	# Limpiar inventario anterior
	game_manager.player_inventory.clear()
	game_manager.player_team.clear()
	
	# Cargar personajes desde la carpeta Data
	var characters_from_data = _load_characters_from_data_folder()
	
	if characters_from_data.is_empty():
		print("No characters found in Data folder, creating default characters...")
		_create_default_characters_from_templates()
	else:
		print("Loaded ", characters_from_data.size(), " characters from Data folder")
		game_manager.player_inventory = characters_from_data
		
		# Seleccionar primeros 2 personajes para el equipo inicial
		if characters_from_data.size() >= 2:
			game_manager.player_team = [characters_from_data[0], characters_from_data[1]]
		elif characters_from_data.size() == 1:
			game_manager.player_team = [characters_from_data[0]]
		
		if character_menu_system and not game_manager.player_team.is_empty():
			character_menu_system.set_team_formation(game_manager.player_team)

func _load_characters_from_data_folder() -> Array[Character]:
	var characters: Array[Character] = []
	var data_path = "res://Data/"
	
	# Verificar si la carpeta Data existe
	if not DirAccess.dir_exists_absolute(data_path):
		print("Data folder not found at: ", data_path)
		return characters
	
	var dir = DirAccess.open(data_path)
	if not dir:
		print("Could not open Data folder")
		return characters
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var full_path = data_path + file_name
			print("Trying to load: ", full_path)
			
			var resource = load(full_path)
			if resource:
				if resource is Character:
					characters.append(resource)
					print("✓ Loaded Character: ", resource.character_name)
				elif resource is CharacterTemplate:
					var character = resource.create_character_instance(randi_range(1, 5))
					characters.append(character)
					print("✓ Loaded CharacterTemplate: ", resource.character_name)
				else:
					print("- Skipped unknown resource type in: ", file_name)
			else:
				print("- Failed to load resource: ", file_name)
		
		file_name = dir.get_next()
	
	return characters

func _create_default_characters_from_templates():
	print("Creating default characters using CharacterDatabase...")
	
	# Intentar usar CharacterDatabase
	var character_db = CharacterDatabase.get_instance()
	if character_db and character_db.character_templates.size() > 0:
		print("Found CharacterDatabase with ", character_db.character_templates.size(), " templates")
		
		# Crear personajes desde templates
		for template in character_db.character_templates:
			var level = randi_range(1, 3)  # Nivel aleatorio 1-3
			var character = template.create_character_instance(level)
			game_manager.player_inventory.append(character)
			print("Created character from template: ", character.character_name, " Lv.", level)
		
		# Equipo inicial: primeros 2 personajes
		if game_manager.player_inventory.size() >= 2:
			game_manager.player_team = [game_manager.player_inventory[0], game_manager.player_inventory[1]]
		elif game_manager.player_inventory.size() == 1:
			game_manager.player_team = [game_manager.player_inventory[0]]
		
		if character_menu_system and not game_manager.player_team.is_empty():
			character_menu_system.set_team_formation(game_manager.player_team)
		
		# Opcionalmente, guardar en Data para futuras cargas
		_save_characters_to_data_folder()
	else:
		print("CharacterDatabase not available, creating minimal fallback characters...")
		_create_minimal_fallback_characters()

func _save_characters_to_data_folder():
	print("Saving generated characters to Data folder...")
	var data_path = "res://Data/"
	
	# Crear carpeta Data si no existe
	if not DirAccess.dir_exists_absolute(data_path):
		var dir_access = DirAccess.open("res://")
		if dir_access:
			dir_access.make_dir("Data")
			print("Created Data folder")
	
	# Guardar cada personaje
	for i in range(game_manager.player_inventory.size()):
		var character = game_manager.player_inventory[i]
		var filename = character.character_name.to_snake_case() + "_" + str(i) + ".tres"
		var full_path = data_path + filename
		
		var result = ResourceSaver.save(character, full_path)
		if result == OK:
			print("✓ Saved character: ", filename)
		else:
			print("✗ Failed to save character: ", filename, " Error: ", result)

func _create_minimal_fallback_characters():
	print("Creating minimal fallback characters...")
	
	var warrior = Character.new()
	warrior.setup("Basic Warrior", 1, Character.Rarity.COMMON, Character.Element.RADIANT, 100, 20, 15, 70, 0.12, 1.4)
	
	var mage = Character.new()
	mage.setup("Basic Mage", 1, Character.Rarity.COMMON, Character.Element.FIRE, 80, 25, 10, 80, 0.15, 1.5)
	
	game_manager.player_inventory.append_array([warrior, mage])
	game_manager.player_team = [warrior, mage]
	
	if character_menu_system:
		character_menu_system.set_team_formation(game_manager.player_team)

func _show_screen(screen_name: String):
	print("Mostrando pantalla:", screen_name)

	# Limpia la escena anterior si existe
	for child in get_children():
		if child.name.ends_with("UI") and child.name != "MainMenu":
			child.queue_free()

	# Oculta el menú principal
	if main_menu:
		main_menu.visible = false

	var new_scene = null

	match screen_name:
		"chapters":
			new_scene = load("res://scenes/ChapterUI.tscn").instantiate()
		"team_formation":
			new_scene = load("res://scenes/TeamFormationUI.tscn").instantiate()
		"battle":
			new_scene = load("res://scenes/BattleUI.tscn").instantiate()
		"gacha":
			new_scene = load("res://scenes/GachaUI.tscn").instantiate()
		"inventory":
			new_scene = load("res://scenes/InventoryUI.tscn").instantiate()
			# MODIFICACIÓN: Configurar el inventario después de cargar
			if new_scene:
				call_deferred("_setup_inventory_scene", new_scene)
		"character_detail":
			new_scene = load("res://scenes/CharacterDetailUI.tscn").instantiate()
		"main_menu":
			if main_menu:
				main_menu.visible = true
				_update_main_menu_display()  # Actualizar display al volver
				return  # No hace falta cargar otra escena aquí

	# Añade la nueva escena como hija
	if new_scene:
		add_child(new_scene)

# NUEVA FUNCIÓN: Configurar la escena de inventario
func _setup_inventory_scene(inventory_scene: Control):
	print("Setting up inventory scene...")
	
	# Conectar botón de back si existe
	var back_button = inventory_scene.get_node_or_null("VBoxContainer/BackButton")
	if back_button:
		back_button.pressed.connect(_on_inventory_back_pressed)
	
	# IMPORTANTE: Limpiar cualquier contenido existente del scroll container
	var scroll_container = inventory_scene.get_node_or_null("VBoxContainer/ScrollContainer")
	if scroll_container:
		# Eliminar TODOS los hijos existentes para evitar duplicados
		for child in scroll_container.get_children():
			child.queue_free()
		await get_tree().process_frame
	
	# Llenar con personajes del inventario
	_populate_inventory_scene(inventory_scene)

# NUEVA FUNCIÓN: Llenar inventario con personajes
func _populate_inventory_scene(inventory_scene: Control):
	if not game_manager:
		return
	
	# Actualizar estadísticas
	var stats_label = inventory_scene.get_node_or_null("VBoxContainer/StatsLabel")
	if stats_label:
		stats_label.text = "Total Heroes: " + str(game_manager.player_inventory.size()) + " | Total Power: " + str(_calculate_total_inventory_power())
	
	# Buscar o crear contenedor de personajes
	var scroll_container = inventory_scene.get_node_or_null("VBoxContainer/ScrollContainer")
	if not scroll_container:
		return
	
	# CAMBIO: Buscar InventoryList existente primero
	var inventory_list = scroll_container.get_node_or_null("InventoryList")
	if not inventory_list:
		# Si no existe, buscarlo en diferentes ubicaciones
		inventory_list = scroll_container.get_node_or_null("CharacterGrid")
		if not inventory_list:
			# Crear nuevo contenedor VBoxContainer para lista vertical
			inventory_list = VBoxContainer.new()
			inventory_list.name = "InventoryList"
			scroll_container.add_child(inventory_list)
	
	# IMPORTANTE: Limpiar TODOS los hijos del scroll container para evitar duplicados
	for child in scroll_container.get_children():
		if child != inventory_list:
			child.queue_free()
	
	# Limpiar lista existente
	for child in inventory_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Ordenar personajes por poder
	var sorted_characters = game_manager.player_inventory.duplicate()
	sorted_characters.sort_custom(func(a, b): return _calculate_character_power(a) > _calculate_character_power(b))
	
	# Crear entrada para cada personaje (SOLO VERSION RECTANGULAR)
	for character in sorted_characters:
		var character_entry = _create_inventory_entry(character)
		inventory_list.add_child(character_entry)

# NUEVA FUNCIÓN: Calcular poder total del inventario
func _calculate_total_inventory_power() -> int:
	if not game_manager:
		return 0
	
	var total_power = 0
	for character in game_manager.player_inventory:
		total_power += _calculate_character_power(character)
	return total_power

func _hide_all_screens():
	_set_visibility_recursive(main_menu, false)
	_set_visibility_recursive(chapter_ui, false)
	_set_visibility_recursive(team_formation_ui, false)
	_set_visibility_recursive(battle_ui, false)
	_set_visibility_recursive(gacha_ui, false)
	_set_visibility_recursive(inventory_ui, false)
	_set_visibility_recursive(character_detail_ui, false)

func _set_visibility_recursive(node: Node, visibility: bool):
	if node and node is CanvasItem:
		(node as CanvasItem).visible = visibility
	for child in node.get_children():
		_set_visibility_recursive(child, visibility)

func _update_main_menu_display():
	if not main_menu or not game_manager:
		return
		
	var currency_label = main_menu.get_node_or_null("VBoxContainer/CurrencyLabel")
	var player_info = main_menu.get_node_or_null("VBoxContainer/PlayerInfo")
	
	if currency_label:
		currency_label.text = "Gold: " + str(game_manager.game_currency)
	
	if player_info:
		player_info.text = "Level: " + str(game_manager.player_level) + " | Team Power: " + str(_calculate_team_power())

func _update_currency_displays():
	# Actualizar currency en todas las pantallas
	_update_main_menu_display()
	_update_gacha_display()

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
		_show_insufficient_team_message()
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
		game_manager.add_experience(rewards.experience)
		print("Stage completed! Rewards: " + str(rewards.gold) + " gold, " + str(rewards.experience) + " exp")
		
		# Agregar personaje garantizado si existe
		if rewards.guaranteed_character:
			game_manager.player_inventory.append(rewards.guaranteed_character)
			print("New character obtained: " + rewards.guaranteed_character.character_name)
	
	# Regresar al menú después de un tiempo
	await get_tree().create_timer(3.0).timeout
	_show_screen("chapters")

func _handle_stage_defeat():
	print("Stage failed!")
	await get_tree().create_timer(2.0).timeout
	_show_screen("chapters")

func _on_character_updated():
	if current_screen == "team_formation":
		# La UI se actualiza automáticamente
		_update_main_menu_display()

# ==== GACHA FUNCTIONS ====

func _single_pull():
	if not game_manager or not gacha_system:
		return
		
	if game_manager.game_currency >= 100:
		game_manager.spend_currency(100)
		var new_character = gacha_system.single_pull()
		game_manager.player_inventory.append(new_character)
		_show_gacha_result([new_character])
	else:
		_show_insufficient_currency_message()

func _ten_pull():
	if not game_manager or not gacha_system:
		return
		
	if game_manager.game_currency >= 900:
		game_manager.spend_currency(900)
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

func _show_insufficient_team_message():
	var popup = AcceptDialog.new()
	popup.dialog_text = "Please select a team before starting battle!"
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

# ==== INVENTORY FUNCTIONS SIMPLIFICADAS ====

# Esta función ya no es necesaria porque _populate_inventory_scene hace todo
# func _update_inventory_display(): 
#	Eliminada para evitar duplicación

func _create_inventory_entry(character: Character) -> Control:
	var entry = Button.new()
	entry.custom_minimum_size = Vector2(380, 80)  # Hacer más alto para mejor visibilidad
	
	# Crear texto con información del personaje
	var entry_text = character.character_name + " Lv." + str(character.level) + "\n"
	entry_text += character.get_element_name() + " | " + Character.Rarity.keys()[character.rarity] + " | Power: " + str(_calculate_character_power(character)) + "\n"
	entry_text += "HP: " + str(character.max_hp) + " | ATK: " + str(character.attack) + " | DEF: " + str(character.defense) + " | SPD: " + str(character.speed)
	
	entry.text = entry_text
	entry.modulate = character.get_rarity_color()
	
	# Indicador si está en el equipo
	if character in game_manager.player_team:
		entry.text += " ★"
	
	# Click para ver detalles
	entry.pressed.connect(func(): _show_character_details(character))
	
	return entry

func _show_character_details(character: Character):
	if character_detail_ui and character_detail_ui.has_method("show_character"):
		character_detail_ui.show_character(character)
		_show_screen("character_detail")
