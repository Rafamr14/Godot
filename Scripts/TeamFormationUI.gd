# ==== TEAM FORMATION UI COMPLETO Y AUTO-SUFICIENTE ====
extends Control

# Sistemas (se buscan automáticamente)
var character_menu_system: CharacterMenuSystem
var game_manager: GameManager
var main_controller: Control

# Referencias UI (se crean dinámicamente)
var character_list: Control
var team_slots: Control
var team_analysis: Label
var filter_buttons: Control
var back_button: Button

# Estado interno
var current_filter: String = "all"
var max_team_size: int = 4

# Señales
signal back_pressed()
signal team_updated()

func _ready():
	print("TeamFormationUI: Inicializando sistema completo...")
	await _initialize_systems()
	_create_ui_structure()
	_setup_connections()
	_setup_filter_buttons()
	_setup_team_slots()
	_update_character_list()
	_update_team_display()
	print("TeamFormationUI: Listo para usar!")

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
		print("Creating CharacterMenuSystem...")
		character_menu_system = CharacterMenuSystem.new()
		character_menu_system.name = "CharacterMenuSystem"
		get_tree().current_scene.add_child(character_menu_system)
		
		# Configurar equipo actual si existe
		if game_manager and not game_manager.player_team.is_empty():
			character_menu_system.set_team_formation(game_manager.player_team)
	
	print("✓ Team Formation systems initialized")

func _find_node_by_script(script_name: String) -> Node:
	for node in get_tree().current_scene.get_children():
		if node.get_script() and node.get_script().get_global_name() == script_name:
			return node
	return null

# ==== CREACIÓN DE UI ====
func _create_ui_structure():
	# Crear estructura principal
	var main_hbox = HBoxContainer.new()
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(main_hbox)
	
	# Panel izquierdo (lista de personajes)
	var left_panel = VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(400, 500)
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(left_panel)
	
	# Título del panel izquierdo
	var left_title = Label.new()
	left_title.text = "Available Heroes"
	left_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_title.add_theme_font_size_override("font_size", 20)
	left_panel.add_child(left_title)
	
	# Filtros
	filter_buttons = HBoxContainer.new()
	filter_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	left_panel.add_child(filter_buttons)
	
	# Scroll container para personajes
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 350)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(scroll)
	
	character_list = VBoxContainer.new()
	character_list.name = "CharacterList"
	scroll.add_child(character_list)
	
	# Panel derecho (equipo y análisis)
	var right_panel = VBoxContainer.new()
	right_panel.custom_minimum_size = Vector2(400, 500)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(right_panel)
	
	# Título del panel derecho
	var right_title = Label.new()
	right_title.text = "Current Team"
	right_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right_title.add_theme_font_size_override("font_size", 20)
	right_panel.add_child(right_title)
	
	# Slots del equipo
	team_slots = VBoxContainer.new()
	team_slots.name = "TeamSlots"
	right_panel.add_child(team_slots)
	
	# Análisis del equipo
	var analysis_label = Label.new()
	analysis_label.text = "Team Analysis:"
	analysis_label.add_theme_font_size_override("font_size", 16)
	right_panel.add_child(analysis_label)
	
	team_analysis = Label.new()
	team_analysis.custom_minimum_size = Vector2(380, 200)
	team_analysis.text = "Select heroes to analyze team composition"
	team_analysis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	team_analysis.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	right_panel.add_child(team_analysis)
	
	# Botón de back
	back_button = Button.new()
	back_button.text = "Back to Main Menu"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_panel.add_child(back_button)

# ==== SETUP DE FILTROS ====
func _setup_filter_buttons():
	if not filter_buttons:
		return
	
	var filters = ["All", "Water", "Fire", "Earth", "Radiant", "Void"]
	
	for filter_name in filters:
		var button = Button.new()
		button.text = filter_name
		button.custom_minimum_size = Vector2(60, 30)
		button.pressed.connect(func(): _apply_filter(filter_name.to_lower()))
		filter_buttons.add_child(button)
	
	_update_filter_button_states()

func _apply_filter(filter: String):
	current_filter = filter
	_update_filter_button_states()
	_update_character_list()

func _update_filter_button_states():
	if not filter_buttons:
		return
		
	var filters = ["all", "water", "fire", "earth", "radiant", "void"]
	var buttons = filter_buttons.get_children()
	
	for i in range(buttons.size()):
		if i < filters.size():
			buttons[i].disabled = (current_filter == filters[i])

# ==== SETUP DE TEAM SLOTS ====
func _setup_team_slots():
	if not team_slots:
		return
	
	# Limpiar slots existentes
	for child in team_slots.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Crear slots del equipo
	for i in range(max_team_size):
		var slot = _create_team_slot(i)
		team_slots.add_child(slot)

func _create_team_slot(index: int) -> Control:
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(380, 70)
	slot.name = "Slot" + str(index)
	
	# Background del slot
	var bg = ColorRect.new()
	bg.size = Vector2(380, 70)
	bg.color = Color(0.2, 0.2, 0.2, 0.8)
	slot.add_child(bg)
	
	# Borde
	var border = ColorRect.new()
	border.size = Vector2(376, 66)
	border.position = Vector2(2, 2)
	border.color = Color(0.5, 0.5, 0.5, 1.0)
	slot.add_child(border)
	
	# Fondo interno
	var inner_bg = ColorRect.new()
	inner_bg.size = Vector2(372, 62)
	inner_bg.position = Vector2(4, 4)
	inner_bg.color = Color(0.1, 0.1, 0.1, 1.0)
	slot.add_child(inner_bg)
	
	# Label del slot cuando está vacío
	var slot_label = Label.new()
	slot_label.text = "Slot " + str(index + 1) + " - Empty"
	slot_label.position = Vector2(10, 25)
	slot_label.add_theme_font_size_override("font_size", 14)
	slot.add_child(slot_label)
	
	# Información del personaje (inicialmente oculta)
	var character_info = Control.new()
	character_info.name = "CharacterInfo"
	character_info.visible = false
	slot.add_child(character_info)
	
	var name_label = Label.new()
	name_label.name = "Name"
	name_label.position = Vector2(10, 10)
	name_label.add_theme_font_size_override("font_size", 16)
	character_info.add_child(name_label)
	
	var level_label = Label.new()
	level_label.name = "Level"
	level_label.position = Vector2(200, 10)
	level_label.add_theme_font_size_override("font_size", 14)
	character_info.add_child(level_label)
	
	var element_label = Label.new()
	element_label.name = "Element"
	element_label.position = Vector2(280, 10)
	element_label.add_theme_font_size_override("font_size", 14)
	character_info.add_child(element_label)
	
	var stats_label = Label.new()
	stats_label.name = "Stats"
	stats_label.position = Vector2(10, 35)
	stats_label.add_theme_font_size_override("font_size", 12)
	character_info.add_child(stats_label)
	
	var remove_label = Label.new()
	remove_label.text = "Right-click to remove"
	remove_label.position = Vector2(280, 35)
	remove_label.add_theme_font_size_override("font_size", 10)
	remove_label.modulate = Color.GRAY
	character_info.add_child(remove_label)
	
	# Input para remover personajes
	slot.gui_input.connect(func(event): _on_team_slot_input(event, index))
	
	return slot

# ==== ACTUALIZACIÓN DE LISTAS ====
func _update_character_list():
	if not character_list or not game_manager:
		return
		
	# Limpiar lista existente
	for child in character_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Obtener personajes filtrados
	var characters = _get_filtered_characters()
	
	# Crear cards para cada personaje
	for character in characters:
		var card = _create_character_card(character)
		character_list.add_child(card)

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

func _create_character_card(character: Character) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(360, 60)
	
	# Texto del personaje
	var card_text = character.character_name + " Lv." + str(character.level) + "\n"
	card_text += character.get_element_name() + " | " + Character.Rarity.keys()[character.rarity]
	card_text += " | Power: " + str(_calculate_character_power(character))
	
	# Indicar si ya está en el equipo
	if character_menu_system and character in character_menu_system.current_team:
		card_text += " ✓"
		card.disabled = true
		card.modulate = Color(0.7, 0.7, 0.7, 1.0)
	else:
		card.modulate = character.get_element_color()
	
	card.text = card_text
	
	# Conectar para agregar al equipo
	if not card.disabled:
		card.pressed.connect(func(): _add_character_to_team(character))
	
	return card

# ==== LÓGICA DEL EQUIPO ====
func _add_character_to_team(character: Character):
	if not character_menu_system:
		return
	
	if character_menu_system.add_to_team(character):
		print("Added ", character.character_name, " to team")
		_update_character_list()  # Refrescar para mostrar que está en equipo
		_update_team_display()
		_update_team_analysis()
		team_updated.emit()
	else:
		_show_message("Cannot add character to team (team full or already in team)")

func _remove_character_from_team(character: Character):
	if not character_menu_system:
		return
	
	if character_menu_system.remove_from_team(character):
		print("Removed ", character.character_name, " from team")
		_update_character_list()  # Refrescar para mostrar disponible
		_update_team_display()
		_update_team_analysis()
		team_updated.emit()

func _on_team_slot_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# Click derecho para remover personaje
		if not character_menu_system:
			return
			
		var current_team = character_menu_system.current_team
		if slot_index < current_team.size():
			var character = current_team[slot_index]
			_remove_character_from_team(character)

# ==== ACTUALIZACIÓN DE DISPLAYS ====
func _update_team_display():
	if not team_slots or not character_menu_system:
		return
		
	var current_team = character_menu_system.current_team
	var slots = team_slots.get_children()
	
	for i in range(max_team_size):
		if i >= slots.size():
			continue
			
		var slot = slots[i]
		var character_info = slot.get_node_or_null("CharacterInfo")
		var slot_label = slot.get_children().filter(func(child): return child is Label and child.name != "CharacterInfo")[0]
		
		if i < current_team.size():
			# Slot ocupado
			var character = current_team[i]
			
			if character_info:
				character_info.visible = true
				character_info.get_node("Name").text = character.character_name
				character_info.get_node("Level").text = "Lv." + str(character.level)
				character_info.get_node("Element").text = character.get_element_name()
				character_info.get_node("Element").modulate = character.get_element_color()
				
				var stats_text = "HP:" + str(character.max_hp) + " ATK:" + str(character.attack) + " DEF:" + str(character.defense) + " SPD:" + str(character.speed)
				character_info.get_node("Stats").text = stats_text
			
			if slot_label:
				slot_label.visible = false
		else:
			# Slot vacío
			if character_info:
				character_info.visible = false
			if slot_label:
				slot_label.visible = true
				slot_label.text = "Slot " + str(i + 1) + " - Empty"

func _update_team_analysis():
	if not team_analysis or not character_menu_system:
		return
		
	var current_team = character_menu_system.current_team
	
	if current_team.is_empty():
		team_analysis.text = "Select heroes to analyze team composition"
		return
	
	var analysis = character_menu_system.analyze_team_composition(current_team)
	
	var analysis_text = "Team Power: " + str(analysis.total_power) + "\n"
	analysis_text += "Team Size: " + str(current_team.size()) + "/" + str(max_team_size) + "\n\n"
	
	# Elementos
	analysis_text += "Elements:\n"
	for element in analysis.elements:
		analysis_text += "  • " + element + ": " + str(analysis.elements[element]) + "\n"
	
	# Roles
	analysis_text += "\nRoles:\n"
	analysis_text += "  • DPS: " + str(analysis.roles.dps) + "\n"
	analysis_text += "  • Tank: " + str(analysis.roles.tank) + "\n"
	analysis_text += "  • Support: " + str(analysis.roles.support) + "\n"
	
	# Sinergias
	if not analysis.synergies.is_empty():
		analysis_text += "\nSynergies:\n"
		for synergy in analysis.synergies:
			analysis_text += "  ✓ " + synergy + "\n"
	
	# Debilidades
	if not analysis.weaknesses.is_empty():
		analysis_text += "\nWeaknesses:\n"
		for weakness in analysis.weaknesses:
			analysis_text += "  ⚠ " + weakness + "\n"
	
	team_analysis.text = analysis_text

# ==== CONEXIONES ====
func _setup_connections():
	if back_button:
		if not back_button.pressed.is_connected(_on_back_pressed):
			back_button.pressed.connect(_on_back_pressed)
	
	# Conectar con character_menu_system si tiene señales
	if character_menu_system and character_menu_system.has_signal("team_formation_changed"):
		if not character_menu_system.team_formation_changed.is_connected(_on_team_formation_changed):
			character_menu_system.team_formation_changed.connect(_on_team_formation_changed)

func _on_team_formation_changed(new_team: Array[Character]):
	_update_team_display()
	_update_team_analysis()
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
	_update_team_analysis()

func get_current_team() -> Array[Character]:
	"""Función pública para obtener el equipo actual"""
	if character_menu_system:
		return character_menu_system.current_team
	return []
