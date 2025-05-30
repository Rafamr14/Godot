# ==== CHARACTER DETAIL VIEW CORREGIDO (CharacterDetailView.gd) ====
extends Control

var character_info: Control
var stats_panel: Control
var skills_panel: Control
var equipment_panel: Control
var level_up_button: Button
var back_button: Button

var current_character: Character
var character_menu_system: CharacterMenuSystem

signal back_pressed()
signal character_updated()

func _ready():
	# Esperar varios frames para que Main.gd termine de crear los sistemas
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Buscar CharacterMenuSystem
	character_menu_system = get_node_or_null("../CharacterMenuSystem")
	
	if character_menu_system == null:
		print("Warning: CharacterMenuSystem not found, waiting...")
		await get_tree().create_timer(0.5).timeout
		character_menu_system = get_node_or_null("../CharacterMenuSystem")
		
		if character_menu_system == null:
			print("Warning: CharacterMenuSystem not found, creating...")
			character_menu_system = CharacterMenuSystem.new()
			get_parent().add_child(character_menu_system)
	
	_create_ui_structure()
	_setup_connections()

func _create_ui_structure():
	# Crear estructura básica
	var main_vbox = VBoxContainer.new()
	add_child(main_vbox)
	
	# Character Info Panel
	character_info = Control.new()
	character_info.custom_minimum_size = Vector2(400, 100)
	main_vbox.add_child(character_info)
	
	var name_label = Label.new()
	name_label.name = "Name"
	name_label.position = Vector2(10, 10)
	name_label.add_theme_font_size_override("font_size", 24)
	character_info.add_child(name_label)
	
	var level_label = Label.new()
	level_label.name = "Level"
	level_label.position = Vector2(10, 40)
	character_info.add_child(level_label)
	
	var element_label = Label.new()
	element_label.name = "Element"
	element_label.position = Vector2(150, 40)
	character_info.add_child(element_label)
	
	var rarity_label = Label.new()
	rarity_label.name = "Rarity"
	rarity_label.position = Vector2(250, 40)
	character_info.add_child(rarity_label)
	
	var power_label = Label.new()
	power_label.name = "Power"
	power_label.position = Vector2(350, 40)
	character_info.add_child(power_label)
	
	# Stats Panel
	stats_panel = Control.new()
	stats_panel.custom_minimum_size = Vector2(400, 200)
	main_vbox.add_child(stats_panel)
	
	var stats_title = Label.new()
	stats_title.text = "Stats:"
	stats_title.position = Vector2(10, 10)
	stats_title.add_theme_font_size_override("font_size", 18)
	stats_panel.add_child(stats_title)
	
	var stats_text = Label.new()
	stats_text.name = "StatsText"
	stats_text.position = Vector2(10, 40)
	stats_text.size = Vector2(380, 150)
	stats_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_panel.add_child(stats_text)
	
	# Skills Panel
	skills_panel = Control.new()
	skills_panel.custom_minimum_size = Vector2(400, 150)
	main_vbox.add_child(skills_panel)
	
	var skills_title = Label.new()
	skills_title.text = "Skills:"
	skills_title.position = Vector2(10, 10)
	skills_title.add_theme_font_size_override("font_size", 18)
	skills_panel.add_child(skills_title)
	
	var skills_scroll = ScrollContainer.new()
	skills_scroll.position = Vector2(10, 40)
	skills_scroll.size = Vector2(380, 100)
	skills_panel.add_child(skills_scroll)
	
	var skills_list = VBoxContainer.new()
	skills_list.name = "SkillsList"
	skills_scroll.add_child(skills_list)
	
	# Equipment Panel
	equipment_panel = Control.new()
	equipment_panel.custom_minimum_size = Vector2(400, 100)
	main_vbox.add_child(equipment_panel)
	
	var equipment_title = Label.new()
	equipment_title.text = "Equipment:"
	equipment_title.position = Vector2(10, 10)
	equipment_title.add_theme_font_size_override("font_size", 18)
	equipment_panel.add_child(equipment_title)
	
	var equipment_text = Label.new()
	equipment_text.name = "EquipmentText"
	equipment_text.position = Vector2(10, 40)
	equipment_text.size = Vector2(380, 50)
	equipment_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	equipment_panel.add_child(equipment_text)
	
	# Buttons
	var button_hbox = HBoxContainer.new()
	main_vbox.add_child(button_hbox)
	
	level_up_button = Button.new()
	level_up_button.text = "Level Up"
	level_up_button.custom_minimum_size = Vector2(100, 40)
	button_hbox.add_child(level_up_button)
	
	back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(100, 40)
	button_hbox.add_child(back_button)

func _setup_connections():
	if level_up_button:
		level_up_button.pressed.connect(_on_level_up_pressed)
	
	if back_button:
		back_button.pressed.connect(func(): back_pressed.emit())

func show_character(character: Character):
	current_character = character
	_update_display()

func _update_display():
	if current_character == null:
		return
	
	_update_character_info()
	_update_stats_panel()
	_update_skills_panel()
	_update_equipment_panel()

func _update_character_info():
	if not character_info:
		return
		
	var info = character_info
	info.get_node("Name").text = current_character.character_name
	info.get_node("Level").text = "Level " + str(current_character.level)
	info.get_node("Element").text = current_character.get_element_name()
	info.get_node("Element").modulate = current_character.get_element_color()
	info.get_node("Rarity").text = Character.Rarity.keys()[current_character.rarity]
	info.get_node("Rarity").modulate = current_character.get_rarity_color()
	
	var power = character_menu_system._calculate_power(current_character)
	info.get_node("Power").text = "Power: " + str(power)

func _update_stats_panel():
	if not stats_panel:
		return
		
	var details = character_menu_system.get_character_details(current_character)
	var stats_text = ""
	
	stats_text += "HP: " + details.hp + "\n"
	stats_text += "Attack: " + str(details.attack) + "\n"
	stats_text += "Defense: " + str(details.defense) + "\n"
	stats_text += "Speed: " + str(details.speed) + "\n"
	stats_text += "Crit Chance: " + details.crit_chance + "\n"
	stats_text += "Crit Damage: " + details.crit_damage + "\n"
	stats_text += "Effectiveness: " + details.effectiveness + "\n"
	stats_text += "Effect Resistance: " + details.effect_resistance + "\n"
	stats_text += "Elemental Mastery: " + str(details.elemental_mastery)
	
	stats_panel.get_node("StatsText").text = stats_text

func _update_skills_panel():
	if not skills_panel:
		return
		
	var skills_container = skills_panel.get_node("ScrollContainer/SkillsList")
	
	# Clear existing
	for child in skills_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Add skills
	for skill in current_character.skills:
		var skill_item = _create_skill_item(skill)
		skills_container.add_child(skill_item)

func _create_skill_item(skill: Skill) -> Control:
	var item = Control.new()
	item.custom_minimum_size = Vector2(360, 60)
	
	var name_label = Label.new()
	name_label.name = "SkillName"
	name_label.text = skill.skill_name
	name_label.position = Vector2(5, 5)
	name_label.add_theme_font_size_override("font_size", 16)
	item.add_child(name_label)
	
	var desc_label = Label.new()
	desc_label.name = "Description"
	desc_label.text = skill.description
	desc_label.position = Vector2(5, 25)
	desc_label.size = Vector2(350, 20)
	item.add_child(desc_label)
	
	var cooldown_label = Label.new()
	cooldown_label.name = "Cooldown"
	cooldown_label.text = "Cooldown: " + str(skill.cooldown)
	cooldown_label.position = Vector2(5, 45)
	item.add_child(cooldown_label)
	
	var element_label = Label.new()
	element_label.name = "Element"
	element_label.text = Character.Element.keys()[skill.element]
	element_label.position = Vector2(150, 45)
	element_label.modulate = _get_element_color(skill.element)
	item.add_child(element_label)
	
	return item

func _get_element_color(element: Character.Element) -> Color:
	match element:
		Character.Element.WATER: return Color.CYAN
		Character.Element.FIRE: return Color.RED
		Character.Element.EARTH: return Color.GREEN
		Character.Element.RADIANT: return Color.YELLOW
		Character.Element.VOID: return Color.DARK_VIOLET
		_: return Color.WHITE

func _update_equipment_panel():
	if not equipment_panel:
		return
		
	var equipment_text = "Equipment:\n"
	
	if current_character.weapon:
		equipment_text += "Weapon: " + current_character.weapon.equipment_name + "\n"
	else:
		equipment_text += "Weapon: None\n"
	
	if current_character.armor:
		equipment_text += "Armor: " + current_character.armor.equipment_name + "\n"
	else:
		equipment_text += "Armor: None\n"
	
	if current_character.accessory:
		equipment_text += "Accessory: " + current_character.accessory.equipment_name + "\n"
	else:
		equipment_text += "Accessory: None\n"
	
	equipment_panel.get_node("EquipmentText").text = equipment_text

func _on_level_up_pressed():
	if not current_character or not character_menu_system:
		return
		
	var cost = character_menu_system._calculate_level_up_cost(current_character, 1)
	
	if character_menu_system.level_up_character(current_character, 1):
		_update_display()
		character_updated.emit()
	else:
		# Show insufficient funds message
		var popup = AcceptDialog.new()
		popup.dialog_text = "Insufficient gold! Need " + str(cost) + " gold."
		add_child(popup)
		popup.popup_centered()
		popup.confirmed.connect(func(): popup.queue_free())
