# ==== MAIN CONTROLLER UPDATED FOR ENHANCED CHAPTER SYSTEM ====
extends Control

# Sistemas principales
var game_manager: GameManager
var enhanced_gacha_system: EnhancedGachaSystem
var battle_system: BattleSystem
var enhanced_chapter_system: EnhancedChapterSystem
var character_menu_system: CharacterMenuSystem
var equipment_manager: EquipmentManager

# Referencias UI
@onready var main_menu = $MainMenu

# Estado actual
var current_screen: String = "main_menu"

func _ready():
	print("=== STARTING ENHANCED GAME INITIALIZATION ===")
	add_to_group("main")
	_initialize_systems()
	_setup_main_menu_connections()
	await _initialize_characters_properly()
	_update_main_menu_display()
	print("Enhanced game initialization complete!")

func _initialize_systems():
	print("Initializing enhanced core systems...")
	
	# Sistemas que ya existen en la escena
	game_manager = $GameManager
	battle_system = $BattleSystem
	
	if game_manager:
		game_manager.add_to_group("game_manager")
	
	# Crear sistemas mejorados
	enhanced_gacha_system = EnhancedGachaSystem.new()
	enhanced_gacha_system.name = "EnhancedGachaSystem"
	enhanced_gacha_system.add_to_group("gacha_system")
	add_child(enhanced_gacha_system)
	
	# USAR EL SISTEMA MEJORADO DE CAPÍTULOS
	enhanced_chapter_system = EnhancedChapterSystem.new()
	enhanced_chapter_system.name = "EnhancedChapterSystem"
	enhanced_chapter_system.add_to_group("chapter_system")
	add_child(enhanced_chapter_system)
	
	character_menu_system = CharacterMenuSystem.new()
	character_menu_system.name = "CharacterMenuSystem"
	character_menu_system.add_to_group("character_menu")
	add_child(character_menu_system)
	
	equipment_manager = EquipmentManager.new()
	equipment_manager.name = "EquipmentManager"
	add_child(equipment_manager)
	
	print("✓ All enhanced systems initialized")

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

# ==== INICIALIZACIÓN MEJORADA DE PERSONAJES ====
func _initialize_characters_properly():
	"""Inicializar personajes de forma robusta desde Data/Characters"""
	if not game_manager:
		print("ERROR: GameManager no disponible para inicializar personajes")
		return
		
	print("Inicializando personajes desde Data/Characters...")
	
	# Limpiar inventario - será poblado desde archivos
	game_manager.player_inventory.clear()
	game_manager.player_team.clear()
	
	# Cargar personajes desde Data/Characters
	var characters = await _load_all_characters_from_data()
	
	if characters.is_empty():
		print("No se encontraron personajes, generando ejemplos...")
		_generate_essential_characters()
	else:
		game_manager.player_inventory = characters
		print("✓ Cargados ", characters.size(), " personajes en el inventario")
	
	# Configurar equipo inicial básico si no existe
	if game_manager.player_team.is_empty() and not game_manager.player_inventory.is_empty():
		var initial_team = game_manager.player_inventory.slice(0, min(2, game_manager.player_inventory.size()))
		game_manager.player_team = initial_team
		
		if character_menu_system:
			character_menu_system.set_team_formation(initial_team)
		
		print("✓ Configurado equipo inicial con ", initial_team.size(), " personajes")

func _load_all_characters_from_data() -> Array[Character]:
	"""Cargar todos los personajes desde Data/Characters"""
	var characters: Array[Character] = []
	var characters_path = "res://Data/Characters/"
	
	# Verificar si existe la carpeta
	if not DirAccess.dir_exists_absolute(characters_path):
		print("Main: Data/Characters no existe, la crearemos más tarde")
		return characters
	
	var dir = DirAccess.open(characters_path)
	if not dir:
		print("Main: Error al abrir Data/Characters")
		return characters
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	var loaded_count = 0
	
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var full_path = characters_path + file_name
			var character = _load_character_file(full_path)
			
			if character:
				characters.append(character)
				loaded_count += 1
				print("Main: ✓ Cargado: ", character.character_name, " (Lv.", character.level, ")")
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	print("Main: Cargados ", loaded_count, " personajes desde Data/Characters")
	return characters

func _load_character_file(file_path: String) -> Character:
	"""Cargar un archivo de personaje individual"""
	var resource = load(file_path)
	
	if not resource:
		print("Main: Error cargando ", file_path)
		return null
	
	# Si es un Character directo
	if resource is Character:
		return resource
	
	# Si es un CharacterTemplate, crear instancia
	if resource is CharacterTemplate:
		var level = randi_range(1, 5)
		return resource.create_character_instance(level)
	
	print("Main: Archivo no reconocido: ", file_path)
	return null

func _generate_essential_characters():
	"""Generar personajes esenciales si no hay ninguno"""
	var characters_path = "res://Data/Characters/"
	
	# Crear carpeta si no existe
	if not DirAccess.dir_exists_absolute(characters_path):
		var dir = DirAccess.open("res://")
		if dir:
			dir.make_dir_recursive("Data/Characters")
			print("Main: ✓ Carpeta Data/Characters creada")
	
	# Personajes esenciales más poderosos para las nuevas batallas épicas
	var essential_data = [
		{"name": "Epic Starter Knight", "element": Character.Element.RADIANT, "rarity": Character.Rarity.RARE, "hp": 180, "attack": 35, "defense": 25, "speed": 70},
		{"name": "Epic Fire Mage", "element": Character.Element.FIRE, "rarity": Character.Rarity.RARE, "hp": 140, "attack": 45, "defense": 18, "speed": 85},
		{"name": "Epic Water Healer", "element": Character.Element.WATER, "rarity": Character.Rarity.RARE, "hp": 160, "attack": 30, "defense": 22, "speed": 80},
		{"name": "Epic Earth Guardian", "element": Character.Element.EARTH, "rarity": Character.Rarity.EPIC, "hp": 220, "attack": 28, "defense": 35, "speed": 65},
		{"name": "Epic Void Assassin", "element": Character.Element.VOID, "rarity": Character.Rarity.EPIC, "hp": 130, "attack": 55, "defense": 15, "speed": 95}
	]
	
	for data in essential_data:
		var character = Character.new()
		var level = randi_range(2, 4)  # Nivel más alto para las nuevas batallas
		
		character.setup(
			data.name,
			level,
			data.rarity,
			data.element,
			data.hp + (level - 1) * 12,
			data.attack + (level - 1) * 5,
			data.defense + (level - 1) * 4,
			data.speed + (level - 1) * 3,
			0.15 + randf() * 0.08,
			1.5 + randf() * 0.3
		)
		
		# Agregar al inventario
		game_manager.player_inventory.append(character)
		
		# Guardar archivo
		var filename = data.name.to_snake_case() + "_lv" + str(level) + ".tres"
		var result = ResourceSaver.save(character, characters_path + filename)
		
		if result == OK:
			print("Main: ✓ Generado: ", character.character_name, " guardado en ", filename)
		else:
			print("Main: ✗ Error guardando: ", character.character_name)
	
	print("Main: Personajes épicos generados y guardados en Data/Characters/")

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
			_load_enhanced_chapter_scene()
		"team_formation":
			_load_team_formation_scene()
		"gacha":
			_load_gacha_scene()
		"inventory":
			_load_inventory_scene()
		"battle":
			_load_enhanced_battle_scene()
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

func _load_enhanced_chapter_scene():
	"""Cargar la nueva escena de capítulos épica"""
	var scene = load("res://scenes/ChapterSelectionUI.tscn").instantiate()
	add_child(scene)
	
	# Conectar señales
	if scene.has_signal("back_pressed"):
		scene.back_pressed.connect(func(): _navigate_to_screen("main_menu"))
	
	if scene.has_signal("stage_selected"):
		scene.stage_selected.connect(_on_stage_selected)

func _load_enhanced_battle_scene():
	"""Cargar la nueva escena de batalla épica"""
	var scene = load("res://scenes/EnhancedBattleUI.tscn").instantiate()
	add_child(scene)
	
	# Conectar señales
	if scene.has_signal("battle_finished"):
		scene.battle_finished.connect(_on_battle_finished)
	
	if scene.has_signal("back_to_chapters"):
		scene.back_to_chapters.connect(func(): _navigate_to_screen("chapters"))

func _load_team_formation_scene():
	var scene = load("res://scenes/TeamFormationUI.tscn").instantiate()
	scene.add_to_group("team_formation")
	add_child(scene)
	
	# Conectar señales
	if scene.has_signal("back_pressed"):
		scene.back_pressed.connect(func(): _navigate_to_screen("main_menu"))
	if scene.has_signal("team_updated"):
		scene.team_updated.connect(_update_main_menu_display)
	
	# Forzar recarga de personajes si es necesario
	if scene.has_method("force_reload_characters"):
		scene.force_reload_characters()

func _load_gacha_scene():
	var scene = load("res://scenes/GachaUI.tscn").instantiate()
	add_child(scene)
	
	if scene.has_signal("back_pressed"):
		scene.back_pressed.connect(func(): _navigate_to_screen("main_menu"))

func _load_inventory_scene():
	var scene = load("res://scenes/InventoryUI.tscn").instantiate()
	add_child(scene)
	
	if scene.has_signal("back_pressed"):
		scene.back_pressed.connect(func(): _navigate_to_screen("main_menu"))

func _show_main_menu():
	if main_menu:
		main_menu.visible = true
		_update_main_menu_display()

# ==== EVENT HANDLERS MEJORADOS ====
func _on_stage_selected(chapter_id: int, stage_id: int):
	"""Manejar selección de stage con el sistema mejorado"""
	print("Epic Stage selected: Chapter ", chapter_id, " Stage ", stage_id)
	
	# Verificar que tenemos los sistemas necesarios
	if not enhanced_chapter_system or not game_manager:
		_show_message("Game systems not ready!")
		return
	
	var stage_data = enhanced_chapter_system.get_stage_data(chapter_id, stage_id)
	if not stage_data:
		_show_message("Stage data not found!")
		return
	
	# Verificar que hay equipo configurado
	if game_manager.player_team.is_empty():
		_show_message("No team configured! Please set up your team first.")
		return
	
	# Verificar que el equipo tiene personajes vivos
	var alive_members = game_manager.player_team.filter(func(char): return char.is_alive())
	if alive_members.is_empty():
		_show_message("All team members are defeated! Please heal them first.")
		return
	
	# Todo OK - iniciar batalla épica
	print("Starting epic battle with team of ", game_manager.player_team.size(), " vs ", stage_data.enemies.size(), " enemies")
	
	# Ir a la escena de batalla y configurarla
	_navigate_to_screen("battle")
	
	# Esperar a que se cree la escena y luego iniciar batalla
	await get_tree().process_frame
	
	var battle_scene = _find_current_battle_scene()
	if battle_scene and battle_scene.has_method("start_battle"):
		battle_scene.start_battle(chapter_id, stage_id)

func _find_current_battle_scene() -> Control:
	"""Encontrar la escena de batalla actual"""
	for child in get_children():
		if child.name == "EnhancedBattleUI" and child.has_method("start_battle"):
			return child
	return null

func _on_battle_finished(victory: bool):
	"""Manejar fin de batalla"""
	print("Battle finished! Victory: ", victory)
	
	if victory:
		print("Epic victory achieved!")
	else:
		print("Heroes were defeated, but they'll return stronger!")
	
	# La batalla ya manejó las recompensas y actualización del progreso
	# Solo necesitamos actualizar la UI principal
	_update_main_menu_display()

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
		var team_size = game_manager.player_team.size()
		var inventory_size = game_manager.player_inventory.size()
		player_info.text = "Level: " + str(game_manager.player_level) + " | Team: " + str(team_size) + "/4 | Heroes: " + str(inventory_size) + " | Power: " + str(team_power)

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
	popup.title = "Notice"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

# ==== PUBLIC INTERFACE ====
func get_game_manager() -> GameManager:
	return game_manager

func get_gacha_system() -> EnhancedGachaSystem:
	return enhanced_gacha_system

func get_character_menu_system() -> CharacterMenuSystem:
	return character_menu_system

func get_chapter_system() -> EnhancedChapterSystem:
	return enhanced_chapter_system

func get_battle_system() -> BattleSystem:
	return battle_system

func get_equipment_manager() -> EquipmentManager:
	return equipment_manager

# ==== FUNCIONES DE DEBUG/UTILIDAD ====
func debug_print_character_status():
	"""Función de debug para ver el estado de los personajes"""
	if not game_manager:
		print("DEBUG: No GameManager")
		return
	
	print("=== ENHANCED CHARACTER STATUS DEBUG ===")
	print("Inventory size: ", game_manager.player_inventory.size())
	print("Team size: ", game_manager.player_team.size())
	
	print("Epic Inventory characters:")
	for i in range(game_manager.player_inventory.size()):
		var char = game_manager.player_inventory[i]
		print("  ", i + 1, ": ", char.character_name, " Lv.", char.level, " (", char.get_element_name(), ") Power:", _calculate_character_power(char))
	
	print("Epic Team characters:")
	for i in range(game_manager.player_team.size()):
		var char = game_manager.player_team[i]
		print("  ", i + 1, ": ", char.character_name, " Lv.", char.level, " Power:", _calculate_character_power(char))
	print("===============================")

func _calculate_character_power(character: Character) -> int:
	return character.max_hp + character.attack * 5 + character.defense * 3 + character.speed * 2

# Funciones para pruebas rápidas desde la consola del editor
func _input(event):
	if event.is_action_pressed("ui_accept") and Input.is_action_pressed("ui_up"):
		# Ctrl+Enter para debug
		debug_print_character_status()
