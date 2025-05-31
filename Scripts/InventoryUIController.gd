# ==== INVENTORY UI CONTROLLER - NAVEGACIÓN ARREGLADA ====
extends Control

# Referencias UI
@onready var title_label = $VBoxContainer/TitleLabel
@onready var stats_label = $VBoxContainer/StatsLabel
@onready var filter_container = $VBoxContainer/FilterContainer
@onready var scroll_container = $VBoxContainer/ScrollContainer
@onready var back_button = $VBoxContainer/BackButton

# Sistemas (se buscan automáticamente)
var game_manager: GameManager
var character_menu_system: CharacterMenuSystem
var main_controller: Control

# Estado interno
var current_filter: String = "all"
var current_sort: String = "power"
var character_list: VBoxContainer
var filter_buttons: Array[Button] = []
var sort_buttons: Array[Button] = []

# Control de navegación
var is_showing_details: bool = false
var current_detail_scene: Control = null

# Señales
signal back_pressed()
signal character_selected(character: Character)

func _ready():
	print("InventoryUIController: Inicializando con personajes de Data/Characters...")
	await _initialize_systems()
	await _setup_ui_if_needed()
	_setup_connections()
	_create_filter_buttons()
	_create_sort_buttons()
	_load_characters_from_data()
	print("InventoryUIController: Listo para usar!")

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
	
	print("✓ Inventory systems initialized")

func _find_node_by_script(script_name: String) -> Node:
	for node in get_tree().current_scene.get_children():
		if node.get_script() and node.get_script().get_global_name() == script_name:
			return node
	return null

# ==== CARGA DE PERSONAJES DESDE DATA/CHARACTERS ====
func _load_characters_from_data():
	"""Cargar SOLO personajes desde la carpeta Data/Characters"""
	print("Cargando personajes desde Data/Characters...")
	
	if not game_manager:
		print("Error: GameManager no disponible")
		return
	
	# Limpiar inventario actual
	game_manager.player_inventory.clear()
	
	var characters_path = "res://Data/Characters/"
	var loaded_characters = _load_all_character_files(characters_path)
	
	if loaded_characters.is_empty():
		print("No se encontraron personajes en Data/Characters/")
		_show_no_characters_message()
		return
	
	# Agregar personajes cargados al GameManager
	game_manager.player_inventory = loaded_characters
	print("Cargados ", loaded_characters.size(), " personajes desde Data/Characters")
	
	# Poblar inventario
	_populate_inventory()

func _load_all_character_files(data_path: String) -> Array[Character]:
	"""Cargar todos los archivos de personajes desde una carpeta específica"""
	var characters: Array[Character] = []
	
	# Verificar si la carpeta existe
	if not DirAccess.dir_exists_absolute(data_path):
		print("Carpeta no encontrada: ", data_path)
		return characters
	
	var dir = DirAccess.open(data_path)
	if not dir:
		print("Error al abrir carpeta: ", data_path)
		return characters
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		# Solo procesar archivos .tres y .res
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var full_path = data_path + file_name
			var loaded_character = _load_character_file(full_path)
			
			if loaded_character:
				characters.append(loaded_character)
				print("✓ Cargado: ", loaded_character.character_name, " desde ", file_name)
			else:
				print("✗ Error cargando: ", file_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return characters

func _load_character_file(file_path: String) -> Character:
	"""Cargar un archivo de personaje específico"""
	var resource = load(file_path)
	
	if not resource:
		print("Error: No se pudo cargar ", file_path)
		return null
	
	# Verificar si es un Character directo
	if resource is Character:
		return resource
	
	# Verificar si es un CharacterTemplate
	if resource is CharacterTemplate:
		var level = randi_range(1, 5)  # Nivel aleatorio 1-5
		var character = resource.create_character_instance(level)
		return character
	
	print("Error: Archivo no es Character ni CharacterTemplate: ", file_path)
	return null

func _show_no_characters_message():
	"""Mostrar mensaje cuando no hay personajes"""
	if not character_list:
		_ensure_character_list()
	
	# Limpiar lista
	for child in character_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Crear mensaje
	var message_label = Label.new()
	message_label.text = "No characters found in Data/Characters/\n\nPlease add character files (.tres or .res) to the Data/Characters/ folder"
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.custom_minimum_size = Vector2(600, 200)
	message_label.add_theme_font_size_override("font_size", 16)
	character_list.add_child(message_label)
	
	# Actualizar stats
	if stats_label:
		stats_label.text = "No Characters Found"

# ==== SETUP DE UI ====
func _setup_ui_if_needed():
	# Verificar y crear elementos que puedan faltar
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		_create_main_structure()
		return
	
	if not title_label:
		title_label = vbox.get_node_or_null("TitleLabel")
		if not title_label:
			_create_title_label(vbox)
	
	if not stats_label:
		stats_label = vbox.get_node_or_null("StatsLabel")
		if not stats_label:
			_create_stats_label(vbox)
	
	if not filter_container:
		filter_container = vbox.get_node_or_null("FilterContainer")
		if not filter_container:
			_create_filter_container(vbox)
	
	if not scroll_container:
		scroll_container = vbox.get_node_or_null("ScrollContainer")
		if not scroll_container:
			_create_scroll_container(vbox)
	
	if not back_button:
		back_button = vbox.get_node_or_null("BackButton")
		if not back_button:
			_create_back_button(vbox)
	
	# Asegurar que existe el contenedor de personajes
	_ensure_character_list()

func _create_main_structure():
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.position = Vector2(50, 50)
	vbox.size = Vector2(800, 550)
	add_child(vbox)
	
	_create_title_label(vbox)
	_create_stats_label(vbox)
	_create_filter_container(vbox)
	_create_scroll_container(vbox)
	_create_back_button(vbox)

func _create_title_label(parent: VBoxContainer):
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Character Collection (Data/Characters)"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	parent.add_child(title_label)

func _create_stats_label(parent: VBoxContainer):
	stats_label = Label.new()
	stats_label.name = "StatsLabel"
	stats_label.text = "Loading characters..."
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.add_theme_font_size_override("font_size", 16)
	parent.add_child(stats_label)

func _create_filter_container(parent: VBoxContainer):
	filter_container = VBoxContainer.new()
	filter_container.name = "FilterContainer"
	parent.add_child(filter_container)

func _create_scroll_container(parent: VBoxContainer):
	scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.custom_minimum_size = Vector2(750, 350)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll_container)

func _create_back_button(parent: VBoxContainer):
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Back to Main Menu"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_button.add_theme_font_size_override("font_size", 18)
	parent.add_child(back_button)

func _ensure_character_list():
	character_list = scroll_container.get_node_or_null("CharacterList")
	if not character_list:
		character_list = VBoxContainer.new()
		character_list.name = "CharacterList"
		scroll_container.add_child(character_list)

# ==== FILTROS Y ORDENAMIENTO ====
func _create_filter_buttons():
	if not filter_container:
		return
	
	# Crear contenedor de filtros si no existe
	var filter_hbox = filter_container.get_node_or_null("FilterButtons")
	if not filter_hbox:
		var filter_label = Label.new()
		filter_label.text = "Filter by Element:"
		filter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		filter_container.add_child(filter_label)
		
		filter_hbox = HBoxContainer.new()
		filter_hbox.name = "FilterButtons"
		filter_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		filter_container.add_child(filter_hbox)
	else:
		# Limpiar botones existentes
		for child in filter_hbox.get_children():
			child.queue_free()
		filter_buttons.clear()
	
	# Crear botones de filtro
	var filters = ["All", "Water", "Fire", "Earth", "Radiant", "Void"]
	
	for filter_name in filters:
		var button = Button.new()
		button.text = filter_name
		button.custom_minimum_size = Vector2(80, 30)
		button.pressed.connect(func(): _apply_filter(filter_name.to_lower()))
		filter_hbox.add_child(button)
		filter_buttons.append(button)
	
	_update_filter_button_states()

func _create_sort_buttons():
	if not filter_container:
		return
	
	# Crear contenedor de ordenamiento si no existe
	var sort_hbox = filter_container.get_node_or_null("SortButtons")
	if not sort_hbox:
		var sort_label = Label.new()
		sort_label.text = "Sort by:"
		sort_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		filter_container.add_child(sort_label)
		
		sort_hbox = HBoxContainer.new()
		sort_hbox.name = "SortButtons"
		sort_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		filter_container.add_child(sort_hbox)
	else:
		# Limpiar botones existentes
		for child in sort_hbox.get_children():
			child.queue_free()
		sort_buttons.clear()
	
	# Crear botones de ordenamiento
	var sorts = [
		{"name": "Power", "key": "power"},
		{"name": "Level", "key": "level"},
		{"name": "Rarity", "key": "rarity"},
		{"name": "Name", "key": "name"}
	]
	
	for sort_data in sorts:
		var button = Button.new()
		button.text = sort_data.name
		button.custom_minimum_size = Vector2(80, 30)
		button.pressed.connect(func(): _apply_sort(sort_data.key))
		sort_hbox.add_child(button)
		sort_buttons.append(button)
	
	_update_sort_button_states()

func _apply_filter(filter: String):
	current_filter = filter
	_update_filter_button_states()
	_populate_inventory()

func _apply_sort(sort: String):
	current_sort = sort
	_update_sort_button_states()
	_populate_inventory()

func _update_filter_button_states():
	var filters = ["all", "water", "fire", "earth", "radiant", "void"]
	for i in range(filter_buttons.size()):
		if i < filters.size():
			filter_buttons[i].disabled = (current_filter == filters[i])

func _update_sort_button_states():
	var sorts = ["power", "level", "rarity", "name"]
	for i in range(sort_buttons.size()):
		if i < sorts.size():
			sort_buttons[i].disabled = (current_sort == sorts[i])

# ==== POBLACIÓN DEL INVENTARIO ====
func _populate_inventory():
	if not game_manager:
		print("GameManager not found, cannot populate inventory")
		return
	
	if game_manager.player_inventory.is_empty():
		print("No characters in inventory")
		_show_no_characters_message()
		return
	
	print("Populating inventory with ", game_manager.player_inventory.size(), " characters")
	
	_update_stats_display()
	_create_character_list()

func _update_stats_display():
	if not stats_label or not game_manager:
		return
	
	var total_characters = game_manager.player_inventory.size()
	var total_power = 0
	
	for character in game_manager.player_inventory:
		total_power += _calculate_character_power(character)
	
	stats_label.text = "Characters from Data/Characters: " + str(total_characters) + " | Total Power: " + str(total_power)

func _create_character_list():
	if not character_list:
		_ensure_character_list()
	
	# Limpiar lista existente
	for child in character_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Obtener personajes filtrados y ordenados
	var filtered_characters = _get_filtered_characters()
	var sorted_characters = _sort_characters(filtered_characters)
	
	if sorted_characters.is_empty():
		var no_results_label = Label.new()
		no_results_label.text = "No characters match the current filter"
		no_results_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_results_label.add_theme_font_size_override("font_size", 16)
		character_list.add_child(no_results_label)
		return
	
	# Crear entradas para cada personaje
	for character in sorted_characters:
		var character_entry = _create_character_entry(character)
		character_list.add_child(character_entry)

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

func _create_character_entry(character: Character) -> Control:
	var entry = Button.new()
	entry.custom_minimum_size = Vector2(700, 80)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Crear texto detallado del personaje
	var entry_text = character.character_name + " Lv." + str(character.level) + "\n"
	entry_text += character.get_element_name() + " | " + Character.Rarity.keys()[character.rarity] + " | Power: " + str(_calculate_character_power(character)) + "\n"
	entry_text += "HP: " + str(character.max_hp) + " | ATK: " + str(character.attack) + " | DEF: " + str(character.defense) + " | SPD: " + str(character.speed)
	
	# Indicador si está en el equipo
	if game_manager and character in game_manager.player_team:
		entry_text += " ★ IN TEAM"
	
	entry.text = entry_text
	entry.modulate = character.get_rarity_color()
	
	# Conexión para selección
	entry.pressed.connect(func(): _on_character_selected(character))
	
	return entry

# ==== CÁLCULOS ====
func _calculate_character_power(character: Character) -> int:
	return character.max_hp + character.attack * 5 + character.defense * 3 + character.speed * 2

# ==== CONEXIONES Y EVENTOS ====
func _setup_connections():
	if back_button:
		if not back_button.pressed.is_connected(_on_back_pressed):
			back_button.pressed.connect(_on_back_pressed)

func _on_character_selected(character: Character):
	# Evitar múltiples clicks si ya estamos mostrando detalles
	if is_showing_details:
		print("Ya mostrando detalles, ignorando click")
		return
	
	print("Character selected: ", character.character_name)
	character_selected.emit(character)
	
	# Mostrar pantalla de detalles
	_show_character_details(character)

func _show_character_details(character: Character):
	"""Mostrar pantalla de detalles del personaje - MÉTODO MEJORADO"""
	
	# Marcar que estamos mostrando detalles
	is_showing_details = true
	
	# Crear escena de detalles programáticamente usando CharacterDetailSceneCreator
	current_detail_scene = _create_character_detail_scene()
	
	if not current_detail_scene:
		print("Error: No se pudo crear la escena de detalles")
		is_showing_details = false
		return
	
	# Agregar al árbol de escenas
	get_tree().current_scene.add_child(current_detail_scene)
	
	# Configurar personaje
	if current_detail_scene.has_method("show_character"):
		current_detail_scene.show_character(character)
	elif current_detail_scene.has_method("set_character_and_show"):
		current_detail_scene.set_character_and_show(character)
	
	# Ocultar inventario temporalmente
	visible = false
	
	# Conectar señal de back con cleanup
	if current_detail_scene.has_signal("back_pressed"):
		current_detail_scene.back_pressed.connect(_on_character_detail_back_safe)
	
	# Conectar señal de actualización
	if current_detail_scene.has_signal("character_updated"):
		current_detail_scene.character_updated.connect(_on_character_updated)

func _create_character_detail_scene() -> Control:
	"""Crear escena de detalles usando CharacterDetailSceneCreator"""
	var detail_scene = CharacterDetailSceneCreator.create_character_detail_scene()
	return detail_scene

func _on_character_detail_back_safe():
	"""Manejar regreso desde pantalla de detalles de forma segura"""
	print("Regresando desde detalles de personaje...")
	
	# Cleanup de la escena de detalles
	if current_detail_scene:
		# Desconectar señales para evitar llamadas múltiples
		if current_detail_scene.has_signal("back_pressed"):
			current_detail_scene.back_pressed.disconnect(_on_character_detail_back_safe)
		if current_detail_scene.has_signal("character_updated"):
			current_detail_scene.character_updated.disconnect(_on_character_updated)
		
		# Remover de la escena
		current_detail_scene.queue_free()
		current_detail_scene = null
	
	# Restaurar estado
	is_showing_details = false
	visible = true
	
	# Refrescar inventario por si el personaje cambió
	await get_tree().process_frame  # Esperar un frame antes de refrescar
	_populate_inventory()

func _on_character_updated(character: Character):
	"""Manejar actualización de personaje"""
	print("Character updated: ", character.character_name)
	# El personaje se actualizó, se refrescará cuando regresemos

func _on_back_pressed():
	# Solo procesar si no estamos mostrando detalles
	if not is_showing_details:
		back_pressed.emit()

# ==== FUNCIONES PÚBLICAS ====
func refresh_inventory():
	"""Función pública para refrescar el inventario desde otros sistemas"""
	if not is_showing_details:  # Solo refrescar si no estamos en detalles
		_load_characters_from_data()

func reload_from_data():
	"""Función pública para recargar desde Data/Characters"""
	if not is_showing_details:  # Solo recargar si no estamos en detalles
		_load_characters_from_data()

func set_filter(filter: String):
	"""Función pública para cambiar filtro desde fuera"""
	if not is_showing_details:
		_apply_filter(filter)

func set_sort(sort: String):
	"""Función pública para cambiar ordenamiento desde fuera"""
	if not is_showing_details:
		_apply_sort(sort)

# ==== FUNCIÓN UTILITARIA PARA CREAR CARPETAS ====
func ensure_data_characters_folder():
	"""Crear la carpeta Data/Characters si no existe"""
	var characters_path = "res://Data/Characters/"
	
	if not DirAccess.dir_exists_absolute(characters_path):
		var dir = DirAccess.open("res://")
		if dir:
			dir.make_dir_recursive("Data/Characters")
			print("Created Data/Characters folder")
		else:
			print("Error: Could not create Data/Characters folder")

# ==== CLEANUP AL SALIR ====
func _exit_tree():
	"""Cleanup al salir"""
	if current_detail_scene:
		current_detail_scene.queue_free()
	is_showing_details = false
