# ==== MAIN CONTROLLER SIMPLIFICADO (Main.gd) ====
# Solo maneja navegación entre escenas y inicialización básica
extends Control

# Sistemas principales (autoload o nodos)
var game_manager: GameManager
var enhanced_gacha_system: EnhancedGachaSystem
var battle_system: BattleSystem
var chapter_system: ChapterSystem
var character_menu_system: CharacterMenuSystem
var equipment_manager: EquipmentManager

# Referencias a UI desde la escena
@onready var main_menu = $MainMenu

# Estado actual
var current_screen: String = "main_menu"

func _ready():
	print("=== STARTING GAME INITIALIZATION ===")
	_initialize_systems()
	_setup_main_menu_connections()
	_initialize_starter_characters()
	print("Game initialization complete!")

func _initialize_systems():
	print("Initializing core systems...")
	
	# Sistemas que ya existen en la escena
	game_manager = $GameManager
	battle_system = $BattleSystem
	
	# Crear sistemas faltantes
	enhanced_gacha_system = EnhancedGachaSystem.new()
	enhanced_gacha_system.name = "EnhancedGachaSystem"
	add_child(enhanced_gacha_system)
	
	chapter_system = ChapterSystem.new()
	chapter_system.name = "ChapterSystem"
	add_child(chapter_system)
	
	character_menu_system = CharacterMenuSystem.new()
	character_menu_system.name = "CharacterMenuSystem"
	add_child(character_menu_system)
	
	equipment_manager = EquipmentManager.new()
	equipment_manager.name = "EquipmentManager"
	add_child(equipment_manager)
	
	print("✓ All systems initialized")

func _setup_main_menu_connections():
	if not main_menu:
		print("ERROR: MainMenu not found!")
		return
		
	var vbox = main_menu.get_node("VBoxContainer")
	if not vbox:
		print("ERROR: VBoxContainer not found in MainMenu!")
		return
	
	# Conectar botones del menú principal
	var chapter_btn = vbox.get_node("ChapterButton")
	var team_btn = vbox.get_node("TeamButton")
	var gacha_btn = vbox.get_node("GachaButton")
	var inventory_btn = vbox.get_node("InventoryButton")
	
	if chapter_btn:
		chapter_btn.pressed.connect(func(): _navigate_to_screen("chapters"))
	if team_btn:
		team_btn.pressed.connect(func(): _navigate_to_screen("team_formation"))
	if gacha_btn:
		gacha_btn.pressed.connect(func(): _navigate_to_screen("gacha"))
	if inventory_btn:
		inventory_btn.pressed.connect(func(): _navigate_to_screen("inventory"))
	
	# Conectar con game manager para actualizaciones
	if game_manager:
		game_manager.currency_changed.connect(_update_main_menu_display)
		game_manager.player_level_changed.connect(_update_main_menu_display)
	
	# Actualizar display inicial
	_update_main_menu_display()

func _initialize_starter_characters():
	if not game_manager:
		return
		
	print("Verificando personajes en Data/Characters...")
	
	# Limpiar inventario - será poblado por InventoryUIController
	game_manager.player_inventory.clear()
	game_manager.player_team.clear()
	
	# Verificar si existe la carpeta y tiene personajes
	var characters_path = "res://Data/Characters/"
	if not DirAccess.dir_exists_absolute(characters_path) or _is_characters_folder_empty(characters_path):
		print("Data/Characters vacía o inexistente, generando personajes de ejemplo...")
		_generate_example_characters(characters_path)
	else:
		print("Data/Characters contiene archivos, será cargado por InventoryUIController")

func _is_characters_folder_empty(path: String) -> bool:
	"""Verificar si la carpeta de personajes está vacía"""
	var dir = DirAccess.open(path)
	if not dir:
		return true
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			dir.list_dir_end()
			return false
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return true

func _generate_example_characters(path: String):
	"""Generar personajes de ejemplo en Data/Characters"""
	
	# Crear carpeta si no existe
	if not DirAccess.dir_exists_absolute(path):
		var dir = DirAccess.open("res://")
		if dir:
			dir.make_dir_recursive("Data/Characters")
			print("✓ Carpeta Data/Characters creada")
	
	# Datos de personajes de ejemplo
	var character_data = [
		{"name": "Forest Warrior", "element": Character.Element.EARTH, "rarity": Character.Rarity.COMMON, "hp": 120, "attack": 22, "defense": 18, "speed": 70},
		{"name": "Fire Mage", "element": Character.Element.FIRE, "rarity": Character.Rarity.RARE, "hp": 90, "attack": 35, "defense": 12, "speed": 85},
		{"name": "Water Healer", "element": Character.Element.WATER, "rarity": Character.Rarity.RARE, "hp": 110, "attack": 18, "defense": 20, "speed": 80},
		{"name": "Radiant Knight", "element": Character.Element.RADIANT, "rarity": Character.Rarity.EPIC, "hp": 150, "attack": 28, "defense": 25, "speed": 65},
		{"name": "Void Assassin", "element": Character.Element.VOID, "rarity": Character.Rarity.EPIC, "hp": 85, "attack": 40, "defense": 10, "speed": 95}
	]
	
	for data in character_data:
		var character = Character.new()
		var level = randi_range(1, 3)
		
		character.setup(
			data.name,
			level,
			data.rarity,
			data.element,
			data.hp + (level - 1) * 8,
			data.attack + (level - 1) * 3,
			data.defense + (level - 1) * 2,
			data.speed + (level - 1) * 1,
			0.15 + randf() * 0.05,
			1.5 + randf() * 0.2
		)
		
		var filename = data.name.to_snake_case() + "_lv" + str(level) + ".tres"
		var result = ResourceSaver.save(character, path + filename)
		
		if result == OK:
			print("✓ Generado: ", character.character_name, " en ", filename)
		else:
			print("✗ Error generando: ", character.character_name)
	
	print("Personajes de ejemplo generados en Data/Characters/")

func _create_minimal_characters():
	"""Solo crear si es absolutamente necesario para evitar crashes"""
	print("Creando personajes mínimos de emergencia...")
	
	var warrior = Character.new()
	warrior.setup("Emergency Warrior", 1, Character.Rarity.COMMON, Character.Element.RADIANT, 100, 20, 15, 70)
	
	var mage = Character.new()
	mage.setup("Emergency Mage", 1, Character.Rarity.COMMON, Character.Element.FIRE, 80, 25, 10, 80)
	
	game_manager.player_inventory.append_array([warrior, mage])
	game_manager.player_team = [warrior, mage]
	
	if character_menu_system:
		character_menu_system.set_team_formation(game_manager.player_team)
	
	print("NOTA: Estos son personajes de emergencia. Agrega personajes reales en Data/Characters/")

# ==== NAVEGACIÓN PRINCIPAL ====
func _navigate_to_screen(screen_name: String):
	print("Navegating to: ", screen_name)
	current_screen = screen_name
	
	# Ocultar menú principal
	if main_menu:
		main_menu.visible = false
	
	# Limpiar escenas anteriores
	_clear_ui_scenes()
	
	# Cargar nueva escena
	match screen_name:
		"chapters":
			_load_chapter_scene()
		"team_formation":
			_load_team_formation_scene()
		"gacha":
			_load_gacha_scene()
		"inventory":
			_load_inventory_scene()
		"battle":
			_load_battle_scene()
		"main_menu":
			_show_main_menu()

func _clear_ui_scenes():
	# Remover todas las escenas UI excepto MainMenu y sistemas
	var nodes_to_remove = []
	for child in get_children():
		if child.name.ends_with("UI") or child.name.ends_with("Scene"):
			nodes_to_remove.append(child)
	
	for node in nodes_to_remove:
		node.queue_free()

func _load_chapter_scene():
	var scene = load("res://scenes/ChapterUI.tscn").instantiate()
	add_child(scene)
	
	# Conectar botón de back
	if scene.has_signal("back_pressed"):
		scene.back_pressed.connect(func(): _navigate_to_screen("main_menu"))
	
	# Conectar selección de stage
	if scene.has_signal("stage_selected"):
		scene.stage_selected.connect(_on_stage_selected)

func _load_team_formation_scene():
	var scene = load("res://scenes/TeamFormationUI.tscn").instantiate()
	add_child(scene)
	
	# Conectar señales
	if scene.has_signal("back_pressed"):
		scene.back_pressed.connect(func(): _navigate_to_screen("main_menu"))
	if scene.has_signal("team_updated"):
		scene.team_updated.connect(_update_main_menu_display)

func _load_gacha_scene():
	var scene = load("res://scenes/GachaUI.tscn").instantiate()
	add_child(scene)
	
	# El GachaUIController manejará toda su lógica internamente
	if scene.has_signal("back_pressed"):
		scene.back_pressed.connect(func(): _navigate_to_screen("main_menu"))

func _load_inventory_scene():
	var scene = load("res://scenes/InventoryUI.tscn").instantiate()
	add_child(scene)
	
	# El InventoryUIController manejará toda su lógica internamente
	if scene.has_signal("back_pressed"):
		scene.back_pressed.connect(func(): _navigate_to_screen("main_menu"))
	if scene.has_signal("character_selected"):
		scene.character_selected.connect(_on_character_selected)

func _load_battle_scene():
	var scene = load("res://scenes/BattleUI.tscn").instantiate()
	add_child(scene)
	
	# El EnhancedBattleUI manejará toda su lógica internamente
	if scene.has_signal("battle_exit"):
		scene.battle_exit.connect(func(): _navigate_to_screen("chapters"))

func _show_main_menu():
	if main_menu:
		main_menu.visible = true
		_update_main_menu_display()

# ==== EVENT HANDLERS ====
func _on_stage_selected(chapter_id: int, stage_id: int):
	# Iniciar batalla con el stage seleccionado
	if not chapter_system or not game_manager:
		return
	
	var chapter_data = chapter_system.get_chapter_data(chapter_id)
	if not chapter_data:
		return
		
	var stage_data = chapter_data.get_stage(stage_id)
	if not stage_data:
		return
	
	# Verificar equipo
	if game_manager.player_team.is_empty():
		_show_message("Please select a team first!")
		return
	
	# Iniciar batalla
	if battle_system:
		battle_system.start_battle(game_manager.player_team, stage_data.enemies)
	
	_navigate_to_screen("battle")

func _on_character_selected(character: Character):
	# Mostrar detalles del personaje
	print("Character selected: ", character.character_name)
	# TODO: Implementar pantalla de detalles si es necesario

# ==== UI UPDATES ====
func _update_main_menu_display():
	if not main_menu or not game_manager:
		return
		
	var vbox = main_menu.get_node_or_null("VBoxContainer")
	if not vbox:
		return
	
	var currency_label = vbox.get_node_or_null("CurrencyLabel")
	var player_info = vbox.get_node_or_null("PlayerInfo")
	
	if currency_label:
		currency_label.text = "Gold: " + str(game_manager.game_currency)
	
	if player_info:
		var team_power = _calculate_team_power()
		player_info.text = "Level: " + str(game_manager.player_level) + " | Team Power: " + str(team_power)

func _calculate_team_power() -> int:
	if not game_manager:
		return 0
		
	var power = 0
	for character in game_manager.player_team:
		power += character.max_hp + character.attack * 5 + character.defense * 3
	return power

# ==== UTILITIES ====
func _show_message(text: String):
	var popup = AcceptDialog.new()
	popup.dialog_text = text
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

# ==== PUBLIC INTERFACE ====
# Métodos para que otros sistemas accedan a los managers
func get_game_manager() -> GameManager:
	return game_manager

func get_gacha_system() -> EnhancedGachaSystem:
	return enhanced_gacha_system

func get_character_menu_system() -> CharacterMenuSystem:
	return character_menu_system

func get_chapter_system() -> ChapterSystem:
	return chapter_system
