# ==== TEAM FORMATION UI CORREGIDO (TeamFormationUI.gd) ====
extends Control

var character_list: Control
var team_slots: Control
var team_analysis: Label
var filter_buttons: Control
var back_button: Button

var character_menu_system: CharacterMenuSystem
var game_manager: GameManager
var current_filter: String = "all"

signal back_pressed()
signal team_updated()

func _ready():
	# Esperar varios frames para que Main.gd termine de crear los sistemas
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Buscar sistemas
	character_menu_system = get_node_or_null("../CharacterMenuSystem")
	game_manager = get_node_or_null("../GameManager")
	
	if character_menu_system == null:
		print("Warning: CharacterMenuSystem not found, waiting...")
		await get_tree().create_timer(0.5).timeout
		character_menu_system = get_node_or_null("../CharacterMenuSystem")
		
		if character_menu_system == null:
			print("Creating CharacterMenuSystem...")
			character_menu_system = CharacterMenuSystem.new()
			get_parent().add_child(character_menu_system)
	
	if game_manager == null:
		print("Warning: GameManager not found, waiting...")
		await get_tree().create_timer(0.5).timeout
		game_manager = get_node_or_null("../GameManager")
		
		if game_manager == null:
			print("Warning: GameManager still not found")
			return
	
	_create_ui_structure()
	_setup_filter_buttons()
	_setup_team_slots()
	_update_character_list()

func _create_ui_structure():
	# Crear estructura básica si no existe
	var hbox = HBoxContainer.new()
	add_child(hbox)
	
	# Left Panel
	var left_panel = VBoxContainer.new()
	left_panel.custom_minimum_size = Vector2(300, 400)
	hbox.add_child(left_panel)
	
	filter_buttons = HBoxContainer.new()
	left_panel.add_child(filter_buttons)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(280, 350)
	left_panel.add_child(scroll)
	
	character_list = VBoxContainer.new()
	scroll.add_child(character_list)
	
	# Right Panel
	var right_panel = VBoxContainer.new()
	right_panel.custom_minimum_size = Vector2(300, 400)
	hbox.add_child(right_panel)
	
	team_slots = VBoxContainer.new()
	right_panel.add_child(team_slots)
	
	team_analysis = Label.new()
	team_analysis.custom_minimum_size = Vector2(280, 150)
	team_analysis.text = "Team Analysis"
	team_analysis.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right_panel.add_child(team_analysis)
	
	back_button = Button.new()
	back_button.text = "Back"
	back_button.pressed.connect(func(): back_pressed.emit())
	right_panel.add_child(back_button)

func _setup_filter_buttons():
	var filters = ["All", "Water", "Fire", "Earth", "Radiant", "Void"]
	
	for filter_name in filters:
		var button = Button.new()
		button.text = filter_name
		button.custom_minimum_size = Vector2(60, 30)
		button.pressed.connect(func(): _apply_filter(filter_name.to_lower()))
		filter_buttons.add_child(button)

func _setup_team_slots():
	for i in range(4):  # Max team size
		var slot = _create_team_slot(i)
		team_slots.add_child(slot)

func _create_team_slot(index: int) -> Control:
	var slot = Control.new()
	slot.custom_minimum_size = Vector2(280, 60)
	
	var bg = ColorRect.new()
	bg.size = Vector2(280, 60)
	bg.color = Color.DARK_GRAY
	slot.add_child(bg)
	
	var slot_label = Label.new()
	slot_label.text = "Slot " + str(index + 1)
	slot_label.position = Vector2(10, 10)
	slot.add_child(slot_label)
	
	var character_info = Control.new()
	character_info.name = "CharacterInfo"
	character_info.visible = false
	slot.add_child(character_info)
	
	var name_label = Label.new()
	name_label.name = "Name"
	name_label.position = Vector2(10, 25)
	character_info.add_child(name_label)
	
	var level_label = Label.new()
	level_label.name = "Level"
	level_label.position = Vector2(150, 25)
	character_info.add_child(level_label)
	
	var element_label = Label.new()
	element_label.name = "Element"
	element_label.position = Vector2(200, 25)
	character_info.add_child(element_label)
	
	# Allow removing characters
	slot.gui_input.connect(func(event): _on_team_slot_input(event, index))
	
	return slot

func _apply_filter(filter: String):
	current_filter = filter
	_update_character_list()

func _update_character_list():
	if not character_list or not game_manager:
		return
		
	# Clear existing list
	for child in character_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Get filtered characters
	var characters = _get_filtered_characters()
	
	# Create character cards
	for character in characters:
		var card = _create_character_card(character)
		character_list.add_child(card)

func _get_filtered_characters() -> Array[Character]:
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
	card.custom_minimum_size = Vector2(260, 50)
	
	var card_text = character.character_name + " Lv." + str(character.level) + "\n"
	card_text += character.get_element_name() + " | Power: " + str(_calculate_character_power(character))
	
	card.text = card_text
	card.modulate = character.get_element_color()
	
	# Enable adding to team
	card.pressed.connect(func(): _add_character_to_team(character))
	
	return card

func _calculate_character_power(character: Character) -> int:
	return character.max_hp + character.attack * 5 + character.defense * 3

func _add_character_to_team(character: Character):
	if character_menu_system.add_to_team(character):
		_update_team_display()
		_update_team_analysis()
		team_updated.emit()

func _on_team_slot_input(event: InputEvent, slot_index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		# Right click to remove character
		var current_team = character_menu_system.current_team
		if slot_index < current_team.size():
			var character = current_team[slot_index]
			character_menu_system.remove_from_team(character)
			_update_team_display()
			_update_team_analysis()
			team_updated.emit()

func _update_team_display():
	if not team_slots or not character_menu_system:
		return
		
	var current_team = character_menu_system.current_team
	
	for i in range(4):
		var slot = team_slots.get_child(i)
		var character_info = slot.get_node("CharacterInfo")
		
		if i < current_team.size():
			var character = current_team[i]
			character_info.get_node("Name").text = character.character_name
			character_info.get_node("Level").text = "Lv." + str(character.level)
			character_info.get_node("Element").text = character.get_element_name()
			character_info.get_node("Element").modulate = character.get_element_color()
			character_info.visible = true
		else:
			character_info.visible = false

func _update_team_analysis():
	if not team_analysis or not character_menu_system:
		return
		
	var current_team = character_menu_system.current_team
	var analysis = character_menu_system.analyze_team_composition(current_team)
	
	var analysis_text = "Team Power: " + str(analysis.total_power) + "\n\n"
	
	# Elements
	analysis_text += "Elements:\n"
	for element in analysis.elements:
		analysis_text += "  " + element + ": " + str(analysis.elements[element]) + "\n"
	
	# Roles
	analysis_text += "\nRoles:\n"
	analysis_text += "  DPS: " + str(analysis.roles.dps) + "\n"
	analysis_text += "  Tank: " + str(analysis.roles.tank) + "\n"
	analysis_text += "  Support: " + str(analysis.roles.support) + "\n"
	
	# Synergies
	if not analysis.synergies.is_empty():
		analysis_text += "\nSynergies:\n"
		for synergy in analysis.synergies:
			analysis_text += "  + " + synergy + "\n"
	
	# Weaknesses
	if not analysis.weaknesses.is_empty():
		analysis_text += "\nWeaknesses:\n"
		for weakness in analysis.weaknesses:
			analysis_text += "  - " + weakness + "\n"
	
	team_analysis.text = analysis_text
