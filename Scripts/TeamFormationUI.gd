# ==== TEAM FORMATION UI - ARREGLADO PARA CARGAR PERSONAJES ====
extends Control

# Referencias UI principales
@onready var back_button = $BackButton

# Left Panel
@onready var title_label = $MainContainer/LeftPanel/HeaderLeft/TitleLabel
@onready var stats_label = $MainContainer/LeftPanel/HeaderLeft/StatsLabel
@onready var character_list = $MainContainer/LeftPanel/CharacterListContainer/CharacterScrollContainer/CharacterList

# Filter buttons
@onready var all_button = $MainContainer/LeftPanel/FilterSection/FilterButtons/AllButton
@onready var water_button = $MainContainer/LeftPanel/FilterSection/FilterButtons/WaterButton
@onready var fire_button = $MainContainer/LeftPanel/FilterSection/FilterButtons/FireButton
@onready var earth_button = $MainContainer/LeftPanel/FilterSection/FilterButtons/EarthButton
@onready var radiant_button = $MainContainer/LeftPanel/FilterSection/FilterButtons/RadiantButton
@onready var void_button = $MainContainer/LeftPanel/FilterSection/FilterButtons/VoidButton

# Sort buttons
@onready var power_sort = $MainContainer/LeftPanel/SortSection/SortButtons/PowerSort
@onready var level_sort = $MainContainer/LeftPanel/SortSection/SortButtons/LevelSort
@onready var rarity_sort = $MainContainer/LeftPanel/SortSection/SortButtons/RaritySort
@onready var name_sort = $MainContainer/LeftPanel/SortSection/SortButtons/NameSort

# Right Panel
@onready var team_stats_label = $MainContainer/RightPanel/HeaderRight/TeamStatsLabel
@onready var team_slots = $MainContainer/RightPanel/TeamSlotsContainer/TeamSlots

# Quick Actions
@onready var clear_team_button = $MainContainer/RightPanel/QuickActions/ClearTeamButton
@onready var auto_fill_button = $MainContainer/RightPanel/QuickActions/AutoFillButton

# Sistemas (se buscan automáticamente)
var character_menu_system: CharacterMenuSystem
var game_manager: GameManager
var main_controller: Control

# Estado interno
var current_filter: String = "all"
var current_sort: String = "power"
var max_team_size: int = 4
var filter_buttons: Array[Button] = []
var sort_buttons: Array[Button] = []

# Señales
signal back_pressed()
signal team_updated()

func _ready():
	print("TeamFormationUI: Inicializando sistema con carga automática de personajes...")
	await _initialize_systems()
	await _ensure_characters_loaded()  # NUEVO: Cargar personajes siempre
	_setup_filter_and_sort_arrays()
	_setup_connections()
	_update_character_list()
	_update_team_display()
	print("TeamFormationUI: Listo para usar!")

# ==== NUEVO: CARGAR PERSONAJES AUTOMÁTICAMENTE ====
func _ensure_characters_loaded():
	"""Asegurar que los personajes estén cargados en el GameManager"""
	if not game_manager:
		print("TeamFormationUI: GameManager no disponible")
		return
	
	# Si el inventario está vacío, cargar desde Data/Characters
	if game_manager.player_inventory.is_empty():
		print("TeamFormationUI: Inventario vacío, cargando personajes desde Data/Characters...")
		var characters = _load_characters_from_data()
		game_manager.player_inventory = characters
		print("TeamFormationUI: Cargados ", characters.size(), " personajes")
	else:
		print("TeamFormationUI: Encontrados ", game_manager.player_inventory.size(), " personajes en inventario")

func _load_characters_from_data() -> Array[Character]:
	"""Cargar todos los personajes desde Data/Characters"""
	var characters: Array[Character] = []
	var characters_path = "res://Data/Characters/"
	
	# Verificar si la carpeta existe
	if not DirAccess.dir_exists_absolute(characters_path):
		print("TeamFormationUI: Data/Characters no existe, creando personajes de ejemplo...")
		_create_example_characters()
		return game_manager.player_inventory if game_manager else []
	
	var dir = DirAccess.open(characters_path)
	if not dir:
		print("TeamFormationUI: Error al abrir Data/Characters")
		return characters
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		# Solo procesar archivos .tres y .res
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var full_path = characters_path + file_name
			var loaded_character = _load_character_file(full_path)
			
			if loaded_character:
				characters.append(loaded_character)
				print("TeamFormationUI: ✓ Cargado: ", loaded_character.character_name, " desde ", file_name)
			else:
				print("TeamFormationUI: ✗ Error cargando: ", file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Si no se encontraron personajes, crear algunos de ejemplo
	if characters.is_empty():
		print("TeamFormationUI: No se encontraron personajes, creando ejemplos...")
		_create_example_characters()
		return game_manager.player_inventory if game_manager else []
	
	return characters

func _load_character_file(file_path: String) -> Character:
	"""Cargar un archivo de personaje específico"""
	var resource = load(file_path)
	
	if not resource:
		print("TeamFormationUI: Error: No se pudo cargar ", file_path)
		return null
	
	# Verificar si es un Character directo
	if resource is Character:
		return resource
	
	# Verificar si es un CharacterTemplate
	if resource is CharacterTemplate:
		var level = randi_range(1, 5)  # Nivel aleatorio 1-5
		var character = resource.create_character_instance(level)
		return character
	
	print("TeamFormationUI: Error: Archivo no es Character ni CharacterTemplate: ", file_path)
	return null

func _create_example_characters():
	"""Crear personajes de ejemplo si no hay ninguno en Data/Characters"""
	if not game_manager:
		return
	
	var characters_path = "res://Data/Characters/"
	
	# Crear carpeta si no existe
	if not DirAccess.dir_exists_absolute(characters_path):
		var dir = DirAccess.open("res://")
		if dir:
			dir.make_dir_recursive("Data/Characters")
			print("TeamFormationUI: ✓ Carpeta Data/Characters creada")
	
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
		
		# Agregar al inventario del game manager
		game_manager.player_inventory.append(character)
		
		# Intentar guardar en archivo también
		var filename = data.name.to_snake_case() + "_lv" + str(level) + ".tres"
		var result = ResourceSaver.save(character, characters_path + filename)
		
		if result == OK:
			print("TeamFormationUI: ✓ Generado: ", character.character_name, " en ", filename)
		else:
			print("TeamFormationUI: ✗ Error generando: ", character.character_name)
	
	print("TeamFormationUI: Personajes de ejemplo creados en Data/Characters/")

# ==== INICIALIZACIÓN DE SISTEMAS ====
func _initialize_systems():
	await get_tree().process_frame
	
	# Buscar Main controller
	main_controller = get_tree().get_first_node_in_group("main")
	if not main_controller:
		var current = get_parent()
		while current and not main_controller:
			if current.has_method("get_game_manager"):
				main_controller = current
				break
			current = current.get_parent()
	
	# Obtener sistemas desde Main o buscar directamente
	if main_controller and main_controller.has_method("get_game_manager"):
		game_manager = main_controller.get_game_manager()
		character_menu_system = main_controller.get_character_menu_system()
	else:
		# Buscar directamente en el árbol
		game_manager = get_tree().get_first_node_in_group("game_manager")
		if not game_manager:
			game_manager = _find_node_by_script("GameManager")
		
		character_menu_system = get_tree().get_first_node_in_group("character_menu")
		if not character_menu_system:
			character_menu_system = _find_node_by_script("CharacterMenuSystem")
	
	# Crear CharacterMenuSystem si no existe
	if not character_menu_system:
		print("TeamFormationUI: Creating CharacterMenuSystem...")
		character_menu_system = CharacterMenuSystem.new()
		character_menu_system.name = "CharacterMenuSystem"
		get_tree().current_scene.add_child(character_menu_system)
		
		# Configurar equipo actual si existe
		if game_manager and not game_manager.player_team.is_empty():
			character_menu_system.set_team_formation(game_manager.player_team)
	
	print("TeamFormationUI: ✓ Team Formation systems initialized")

func _find_node_by_script(script_name: String) -> Node:
	for node in get_tree().current_scene.get_children():
		if node.get_script() and node.get_script().get_global_name() == script_name:
			return node
	return null

func _setup_filter_and_sort_arrays():
	"""Configurar arrays de botones para fácil manejo"""
	filter_buttons = [all_button, water_button, fire_button, earth_button, radiant_button, void_button]
	sort_buttons = [power_sort, level_sort, rarity_sort, name_sort]

# ==== SETUP DE CONEXIONES ====
func _setup_connections():
	# Back button
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	# Filter buttons
	if all_button:
		all_button.pressed.connect(func(): _apply_filter("all"))
	if water_button:
		water_button.pressed.connect(func(): _apply_filter("water"))
	if fire_button:
		fire_button.pressed.connect(func(): _apply_filter("fire"))
	if earth_button:
		earth_button.pressed.connect(func(): _apply_filter("earth"))
	if radiant_button:
		radiant_button.pressed.connect(func(): _apply_filter("radiant"))
	if void_button:
		void_button.pressed.connect(func(): _apply_filter("void"))
	
	# Sort buttons
	if power_sort:
		power_sort.pressed.connect(func(): _apply_sort("power"))
	if level_sort:
		level_sort.pressed.connect(func(): _apply_sort("level"))
	if rarity_sort:
		rarity_sort.pressed.connect(func(): _apply_sort("rarity"))
	if name_sort:
		name_sort.pressed.connect(func(): _apply_sort("name"))
	
	# Quick action buttons
	if clear_team_button:
		clear_team_button.pressed.connect(_on_clear_team)
	if auto_fill_button:
		auto_fill_button.pressed.connect(_on_auto_fill)
	
	# Conectar con character_menu_system si tiene señales
	if character_menu_system and character_menu_system.has_signal("team_formation_changed"):
		character_menu_system.team_formation_changed.connect(_on_team_formation_changed)
	
	_update_button_states()

# ==== FILTROS Y ORDENAMIENTO ====
func _apply_filter(filter: String):
	current_filter = filter
	_update_button_states()
	_update_character_list()

func _apply_sort(sort: String):
	current_sort = sort
	_update_button_states()
	_update_character_list()

func _update_button_states():
	"""Actualizar estado de botones de filtro y ordenamiento"""
	# Filter buttons
	var filters = ["all", "water", "fire", "earth", "radiant", "void"]
	for i in range(filter_buttons.size()):
		if i < filters.size() and filter_buttons[i]:
			filter_buttons[i].disabled = (current_filter == filters[i])
	
	# Sort buttons
	var sorts = ["power", "level", "rarity", "name"]
	for i in range(sort_buttons.size()):
		if i < sorts.size() and sort_buttons[i]:
			sort_buttons[i].disabled = (current_sort == sorts[i])

# ==== ACTUALIZACIÓN DE LISTAS ====
func _update_character_list():
	if not character_list or not game_manager:
		print("TeamFormationUI: No character_list o game_manager para actualizar")
		return
		
	# Limpiar lista existente
	for child in character_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Obtener personajes filtrados (solo los que NO están en el equipo)
	var characters = _get_filtered_characters()
	var available_characters = _get_available_characters(characters)
	var sorted_characters = _sort_characters(available_characters)
	
	# Actualizar stats
	_update_stats_display(sorted_characters)
	
	# Si no hay personajes disponibles, mostrar mensaje
	if sorted_characters.is_empty():
		_show_no_characters_message()
		return
	
	# Crear cards para cada personaje disponible
	for character in sorted_characters:
		var card = _create_character_card(character)
		if card:  # Solo agregar si la card no es null
			character_list.add_child(card)

func _show_no_characters_message():
	"""Mostrar mensaje cuando no hay personajes disponibles"""
	var message_label = Label.new()
	message_label.text = "No characters available.\nAll characters are already in the team,\nor no characters have been loaded."
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(450, 100)
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.modulate = Color(0.8, 0.8, 0.9, 1)
	character_list.add_child(message_label)

func _get_available_characters(characters: Array[Character]) -> Array[Character]:
	"""Filtrar personajes que NO están en el equipo actual"""
	if not character_menu_system:
		return characters
	
	return characters.filter(func(char): return char not in character_menu_system.current_team)

func _get_filtered_characters() -> Array[Character]:
	if not game_manager:
		return []
	
	var characters = game_manager.player_inventory
	
	match current_filter:
		"water":
			return characters.filter(func(char): return char.element == Character.Element.WATER)
		"fire":
			return characters.filter(func(char): return char.element == Character.Element.FIRE)
		"earth":
			return characters.filter(func(char): return char.element == Character.Element.EARTH)
		"radiant":
			return characters.filter(func(char): return char.element == Character.Element.RADIANT)
		"void":
			return characters.filter(func(char): return char.element == Character.Element.VOID)
		_:
			return characters

func _sort_characters(characters: Array[Character]) -> Array[Character]:
	var sorted_chars = characters.duplicate()
	
	match current_sort:
		"power":
			sorted_chars.sort_custom(func(a, b): return _calculate_character_power(a) > _calculate_character_power(b))
		"level":
			sorted_chars.sort_custom(func(a, b): return a.level > b.level)
		"rarity":
			sorted_chars.sort_custom(func(a, b): return a.rarity > b.rarity)
		"name":
			sorted_chars.sort_custom(func(a, b): return a.character_name < b.character_name)
	
	return sorted_chars

func _update_stats_display(available_characters: Array[Character]):
	"""Actualizar estadísticas del panel izquierdo"""
	if not stats_label:
		return
	
	var total_heroes = game_manager.player_inventory.size() if game_manager else 0
	var available_heroes = available_characters.size()
	var current_team_size = character_menu_system.current_team.size() if character_menu_system else 0
	
	stats_label.text = "Total Heroes: " + str(total_heroes) + " | Available: " + str(available_heroes) + " | In Team: " + str(current_team_size)

func _create_character_card(character: Character) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(480, 70)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Verificar si está en el equipo ANTES de crear el texto
	var is_in_team = character_menu_system and character in character_menu_system.current_team
	
	# Solo mostrar personajes que NO están en el equipo
	if is_in_team:
		# NO crear la card para personajes que ya están en el equipo
		card.queue_free()
		return null
	
	# Crear texto detallado del personaje
	var card_text = character.character_name + " Lv." + str(character.level) + "\n"
	card_text += character.get_element_name() + " | " + Character.Rarity.keys()[character.rarity] + " | Power: " + str(_calculate_character_power(character))
	
	card.text = card_text
	card.modulate = character.get_rarity_color()
	
	# Conexión para agregar al equipo
	card.pressed.connect(func(): _add_character_to_team(character))
	
	return card

# ==== LÓGICA DEL EQUIPO ====
func _add_character_to_team(character: Character):
	if not character_menu_system:
		return
	
	if character_menu_system.add_to_team(character):
		print("TeamFormationUI: Added ", character.character_name, " to team")
		_update_character_list()  # Refrescar para mostrar que está en equipo
		_update_team_display()
		team_updated.emit()
	else:
		_show_message("Cannot add character to team (team full or already in team)")

func _remove_character_from_team(character: Character):
	if not character_menu_system:
		return
	
	if character_menu_system.remove_from_team(character):
		print("TeamFormationUI: Removed ", character.character_name, " from team")
		_update_character_list()  # Refrescar para mostrar disponible
		_update_team_display()
		team_updated.emit()

# ==== ACTUALIZACIÓN DE TEAM SLOTS ====
func _update_team_display():
	if not team_slots or not character_menu_system:
		return
		
	var current_team = character_menu_system.current_team
	
	# Actualizar cada slot (TeamSlot1, TeamSlot2, etc.)
	for i in range(max_team_size):
		var slot_name = "TeamSlot" + str(i + 1)
		var slot = team_slots.get_node_or_null(slot_name)
		
		if not slot:
			continue
		
		var slot_label = slot.get_node_or_null("SlotLabel")
		var character_info = slot.get_node_or_null("CharacterInfo")
		
		if i < current_team.size():
			# Slot ocupado
			var character = current_team[i]
			
			if slot_label:
				slot_label.visible = false
			
			if character_info:
				character_info.visible = true
				_update_character_info_in_slot(character_info, character)
				
				# Setup click para remover
				if not slot.gui_input.is_connected(_on_team_slot_input):
					slot.gui_input.connect(func(event): _on_team_slot_input(event, i))
		else:
			# Slot vacío
			if slot_label:
				slot_label.visible = true
				slot_label.text = "Slot " + str(i + 1) + " - Empty"
			
			if character_info:
				character_info.visible = false
	
	# Actualizar stats del equipo
	_update_team_stats()

func _update_character_info_in_slot(character_info: Control, character: Character):
	"""Actualizar información del personaje en el slot"""
	var name_label = character_info.get_node_or_null("CharacterName")
	var level_label = character_info.get_node_or_null("CharacterLevel")
	var element_label = character_info.get_node_or_null("CharacterElement")
	var power_label = character_info.get_node_or_null("CharacterPower")
	
	if name_label:
		name_label.text = character.character_name
		name_label.modulate = character.get_rarity_color()
	
	if level_label:
		level_label.text = "Level " + str(character.level)
	
	if element_label:
		element_label.text = character.get_element_name()
		element_label.modulate = character.get_element_color()
	
	if power_label:
		power_label.text = "Power: " + str(_calculate_character_power(character))

func _update_team_stats():
	"""Actualizar estadísticas del equipo"""
	if not team_stats_label or not character_menu_system:
		return
	
	var current_team = character_menu_system.current_team
	var team_power = 0
	
	for character in current_team:
		team_power += _calculate_character_power(character)
	
	team_stats_label.text = "Team Size: " + str(current_team.size()) + "/" + str(max_team_size) + " | Total Power: " + str(team_power)

func _on_team_slot_input(event: InputEvent, slot_index: int):
	"""Manejar input en slots del equipo"""
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# Click derecho para remover personaje
		if not character_menu_system:
			return
			
		var current_team = character_menu_system.current_team
		if slot_index < current_team.size():
			var character = current_team[slot_index]
			_remove_character_from_team(character)

# ==== ACCIONES RÁPIDAS ====
func _on_clear_team():
	"""Limpiar todo el equipo"""
	if character_menu_system:
		character_menu_system.clear_team()
		_update_character_list()
		_update_team_display()
		team_updated.emit()

func _on_auto_fill():
	"""Auto-llenar equipo con mejores personajes disponibles"""
	if not character_menu_system or not game_manager:
		return
	
	# Obtener personajes disponibles ordenados por poder
	var available_chars = game_manager.player_inventory.filter(
		func(char): return char not in character_menu_system.current_team
	)
	available_chars.sort_custom(func(a, b): return _calculate_character_power(a) > _calculate_character_power(b))
	
	# Llenar slots vacíos
	var slots_to_fill = max_team_size - character_menu_system.current_team.size()
	for i in range(min(slots_to_fill, available_chars.size())):
		character_menu_system.add_to_team(available_chars[i])
	
	_update_character_list()
	_update_team_display()
	team_updated.emit()

# ==== EVENT HANDLERS ====
func _on_team_formation_changed(new_team: Array[Character]):
	_update_team_display()
	_update_character_list()
	team_updated.emit()

func _on_back_pressed():
	back_pressed.emit()

# ==== UTILITIES ====
func _calculate_character_power(character: Character) -> int:
	return character.max_hp + character.attack * 5 + character.defense * 3 + character.speed * 2

func _show_message(text: String):
	var popup = AcceptDialog.new()
	popup.dialog_text = text
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

# ==== FUNCIONES PÚBLICAS ====
func refresh_display():
	"""Función pública para refrescar desde otros sistemas"""
	_update_character_list()
	_update_team_display()

func get_current_team() -> Array[Character]:
	"""Función pública para obtener el equipo actual"""
	if character_menu_system:
		return character_menu_system.current_team
	return []

func force_reload_characters():
	"""Función pública para forzar recarga de personajes"""
	await _ensure_characters_loaded()
	_update_character_list()
	_update_team_display()
