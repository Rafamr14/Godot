# ==== INVENTORY UI CONTROLLER COMPLETO (InventoryUIController.gd) ====
extends Control

# Referencias UI
@onready var title_label = $VBoxContainer/TitleLabel
@onready var stats_label = $VBoxContainer/StatsLabel
@onready var filter_container = $VBoxContainer/FilterContainer
@onready var character_grid = $VBoxContainer/ScrollContainer/CharacterGrid
@onready var back_button = $VBoxContainer/BackButton

# Sistemas
var game_manager: GameManager
var character_database: CharacterDatabase

# Filtros y ordenamiento
var current_filter: String = "all"
var current_sort: String = "power"
var all_characters: Array[Character] = []

# Señales
signal back_pressed()
signal character_selected(character: Character)

func _ready():
	print("InventoryUI: Inicializando...")
	
	# Buscar sistemas
	await _find_systems()
	
	# Configurar UI
	_setup_ui_structure()
	_setup_connections()
	
	# Cargar personajes
	_load_all_characters()
	_update_display()

func _find_systems():
	# Esperar que los sistemas estén listos
	await get_tree().process_frame
	await get_tree().process_frame
	
	game_manager = get_node_or_null("../GameManager")
	if game_manager == null:
		print("GameManager no encontrado, buscando...")
		await get_tree().create_timer(0.5).timeout
		game_manager = get_node_or_null("../GameManager")
	
	# Cargar base de datos de personajes
	character_database = CharacterDatabase.get_instance()
	print("CharacterDatabase cargada con ", character_database.character_templates.size(), " personajes")

func _setup_ui_structure():
	# Verificar que la estructura existe, si no, crearla
	if not filter_container:
		_create_filter_container()
	
	if not character_grid:
		_create_character_grid()
	
	# Configurar filtros
	_setup_filter_buttons()

func _create_filter_container():
	filter_container = HBoxContainer.new()
	filter_container.name = "FilterContainer"
	# Insertar después del stats_label
	var vbox = $VBoxContainer
	vbox.add_child(filter_container)
	vbox.move_child(filter_container, 2)

func _create_character_grid():
	var scroll_container = $VBoxContainer/ScrollContainer
	if not scroll_container:
		scroll_container = ScrollContainer.new()
		scroll_container.name = "ScrollContainer"
		scroll_container.custom_minimum_size = Vector2(400, 350)
		$VBoxContainer.add_child(scroll_container)
		$VBoxContainer.move_child(scroll_container, -2)  # Antes del back button
	
	character_grid = GridContainer.new()
	character_grid.name = "CharacterGrid"
	character_grid.columns = 2
	scroll_container.add_child(character_grid)

func _setup_filter_buttons():
	if not filter_container:
		return
	
	# Limpiar filtros existentes
	for child in filter_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Crear botones de filtro
	var filters = [
		{"id": "all", "text": "All"},
		{"id": "water", "text": "Water"},
		{"id": "fire", "text": "Fire"},
		{"id": "earth", "text": "Earth"},
		{"id": "radiant", "text": "Radiant"},
		{"id": "void", "text": "Void"}
	]
	
	for filter_data in filters:
		var button = Button.new()
		button.text = filter_data.text
		button.custom_minimum_size = Vector2(60, 30)
		button.pressed.connect(func(): _apply_filter(filter_data.id))
		filter_container.add_child(button)
	
	# Separador
	var separator = VSeparator.new()
	filter_container.add_child(separator)
	
	# Botones de ordenamiento
	var sort_buttons = [
		{"id": "power", "text": "Power"},
		{"id": "level", "text": "Level"},
		{"id": "name", "text": "Name"},
		{"id": "rarity", "text": "Rarity"}
	]
	
	for sort_data in sort_buttons:
		var button = Button.new()
		button.text = sort_data.text
		button.custom_minimum_size = Vector2(60, 30)
		button.pressed.connect(func(): _apply_sort(sort_data.id))
		filter_container.add_child(button)

func _setup_connections():
	if back_button:
		back_button.pressed.connect(func(): back_pressed.emit())

func _load_all_characters():
	all_characters.clear()
	
	# Cargar personajes del inventario del jugador
	if game_manager:
		all_characters.append_array(game_manager.player_inventory)
	
	# Si no hay personajes en el inventario, crear algunos de prueba
	if all_characters.is_empty():
		_create_test_characters()
	
	print("Cargados ", all_characters.size(), " personajes en el inventario")

func _create_test_characters():
	if not character_database:
		print("CharacterDatabase no disponible")
		return
	
	# Crear personajes de ejemplo basados en los templates
	for template in character_database.character_templates:
		var character = template.create_character_instance(randi_range(1, 5))
		all_characters.append(character)
	
	# Agregar al inventario del jugador
	if game_manager:
		game_manager.player_inventory = all_characters.duplicate()

func _apply_filter(filter_id: String):
	current_filter = filter_id
	_update_display()

func _apply_sort(sort_id: String):
	current_sort = sort_id
	_update_display()

func _update_display():
	_update_stats_label()
	_update_character_grid()

func _update_stats_label():
	if not stats_label:
		return
	
	var filtered_characters = _get_filtered_characters()
	var total_power = 0
	
	for character in filtered_characters:
		total_power += _calculate_character_power(character)
	
	var stats_text = "Total Heroes: " + str(filtered_characters.size())
	stats_text += " | Total Power: " + str(total_power)
	
	# Contar por rareza
	var rarity_counts = {}
	for character in filtered_characters:
		var rarity_name = Character.Rarity.keys()[character.rarity]
		if rarity_name in rarity_counts:
			rarity_counts[rarity_name] += 1
		else:
			rarity_counts[rarity_name] = 1
	
	stats_text += "\n"
	for rarity in rarity_counts:
		stats_text += rarity + ": " + str(rarity_counts[rarity]) + " "
	
	stats_label.text = stats_text

func _update_character_grid():
	if not character_grid:
		return
	
	# Limpiar grid existente
	for child in character_grid.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Obtener personajes filtrados y ordenados
	var characters = _get_filtered_and_sorted_characters()
	
	# Crear cards para cada personaje
	for character in characters:
		var character_card = _create_character_card(character)
		character_grid.add_child(character_card)

func _get_filtered_characters() -> Array[Character]:
	match current_filter:
		"water":
			return all_characters.filter(func(char): return char.element == Character.Element.WATER)
		"fire":
			return all_characters.filter(func(char): return char.element == Character.Element.FIRE)
		"earth":
			return all_characters.filter(func(char): return char.element == Character.Element.EARTH)
		"radiant":
			return all_characters.filter(func(char): return char.element == Character.Element.RADIANT)
		"void":
			return all_characters.filter(func(char): return char.element == Character.Element.VOID)
		_:
			return all_characters

func _get_filtered_and_sorted_characters() -> Array[Character]:
	var characters = _get_filtered_characters()
	
	match current_sort:
		"power":
			characters.sort_custom(func(a, b): return _calculate_character_power(a) > _calculate_character_power(b))
		"level":
			characters.sort_custom(func(a, b): return a.level > b.level)
		"name":
			characters.sort_custom(func(a, b): return a.character_name < b.character_name)
		"rarity":
			characters.sort_custom(func(a, b): return a.rarity > b.rarity)
	
	return characters

func _create_character_card(character: Character) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(180, 120)
	
	# Crear layout vertical para la card
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)
	
	# Nombre del personaje
	var name_label = Label.new()
	name_label.text = character.character_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)
	
	# Nivel y rareza
	var level_rarity = Label.new()
	level_rarity.text = "Lv." + str(character.level) + " | " + Character.Rarity.keys()[character.rarity]
	level_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_rarity.add_theme_font_size_override("font_size", 11)
	vbox.add_child(level_rarity)
	
	# Elemento
	var element_label = Label.new()
	element_label.text = character.get_element_name()
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_label.modulate = character.get_element_color()
	element_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(element_label)
	
	# Stats principales
	var stats_container = HBoxContainer.new()
	vbox.add_child(stats_container)
	
	var hp_label = Label.new()
	hp_label.text = "HP:" + str(character.max_hp)
	hp_label.add_theme_font_size_override("font_size", 10)
	stats_container.add_child(hp_label)
	
	var atk_label = Label.new()
	atk_label.text = "ATK:" + str(character.attack)
	atk_label.add_theme_font_size_override("font_size", 10)
	stats_container.add_child(atk_label)
	
	# Power rating
	var power_label = Label.new()
	power_label.text = "Power: " + str(_calculate_character_power(character))
	power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	power_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(power_label)
	
	# Indicador de equipo
	if game_manager and character in game_manager.player_team:
		var team_indicator = Label.new()
		team_indicator.text = "★ IN TEAM"
		team_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		team_indicator.modulate = Color.GOLD
		team_indicator.add_theme_font_size_override("font_size", 10)
		vbox.add_child(team_indicator)
	
	# Color de borde según rareza
	card.modulate = character.get_rarity_color()
	
	# Conexión para mostrar detalles
	card.pressed.connect(func(): _on_character_selected(character))
	
	return card

func _calculate_character_power(character: Character) -> int:
	return character.max_hp + character.attack * 5 + character.defense * 3 + character.speed * 2

func _on_character_selected(character: Character):
	print("Personaje seleccionado: ", character.character_name)
	character_selected.emit(character)

# Función para refrescar el inventario (útil después de gacha)
func refresh_inventory():
	_load_all_characters()
	_update_display()
