# ==== CHARACTER DETAIL CONTROLLER ====
extends Control

# Referencias UI - Left Panel
@onready var character_splash = $MainContainer/LeftPanel/CharacterSplash
@onready var character_image = $MainContainer/LeftPanel/CharacterSplash/CharacterImage
@onready var element_icon = $MainContainer/LeftPanel/CharacterSplash/ElementIcon
@onready var level_text = $MainContainer/LeftPanel/CharacterSplash/LevelBadge/LevelText
@onready var splash_border = $MainContainer/LeftPanel/CharacterSplash/SplashBorder
@onready var power_display = $MainContainer/LeftPanel/PowerDisplay

# Referencias UI - Right Panel Header
@onready var name_label = $MainContainer/RightPanel/Header/NameLabel
@onready var element_label = $MainContainer/RightPanel/Header/InfoRow/ElementLabel
@onready var rarity_label = $MainContainer/RightPanel/Header/InfoRow/RarityLabel
@onready var class_label = $MainContainer/RightPanel/Header/InfoRow/ClassLabel

# Referencias UI - Stats
@onready var hp_value = $MainContainer/RightPanel/StatsSection/StatsGrid/HPValue
@onready var attack_value = $MainContainer/RightPanel/StatsSection/StatsGrid/AttackValue
@onready var defense_value = $MainContainer/RightPanel/StatsSection/StatsGrid/DefenseValue
@onready var speed_value = $MainContainer/RightPanel/StatsSection/StatsGrid/SpeedValue
@onready var crit_chance_value = $MainContainer/RightPanel/StatsSection/StatsGrid/CritChanceValue
@onready var crit_damage_value = $MainContainer/RightPanel/StatsSection/StatsGrid/CritDamageValue

# Referencias UI - Skills y Actions
@onready var skills_list = $MainContainer/RightPanel/SkillsSection/SkillsList
@onready var level_up_button = $MainContainer/RightPanel/ActionsSection/LevelUpContainer/LevelUpButton
@onready var level_up_info = $MainContainer/RightPanel/ActionsSection/LevelUpContainer/LevelUpInfo
@onready var equipment_button = $MainContainer/RightPanel/ActionsSection/ButtonsRow/EquipmentButton
@onready var skills_button = $MainContainer/RightPanel/ActionsSection/ButtonsRow/SkillsButton
@onready var back_button = $MainContainer/RightPanel/ActionsSection/BackButton

# Sistemas
var game_manager: GameManager
var character_menu_system: CharacterMenuSystem
var main_controller: Control

# Estado
var current_character: Character

# Señales
signal back_pressed()
signal character_updated(character: Character)

func _ready():
	print("CharacterDetailController: Inicializando...")
	await _initialize_systems()
	_setup_connections()
	_setup_animations()
	print("CharacterDetailController: Listo!")

# ==== INICIALIZACIÓN ====
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
	
	# Obtener sistemas
	if main_controller and main_controller.has_method("get_game_manager"):
		game_manager = main_controller.get_game_manager()
		character_menu_system = main_controller.get_character_menu_system()
	else:
		# Buscar directamente
		game_manager = get_tree().get_first_node_in_group("game_manager")
		character_menu_system = get_tree().get_first_node_in_group("character_menu")
	
	print("✓ CharacterDetail systems initialized")

func _setup_connections():
	# Conectar botones
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	if level_up_button:
		level_up_button.pressed.connect(_on_level_up_pressed)
	
	if equipment_button:
		equipment_button.pressed.connect(_on_equipment_pressed)
	
	if skills_button:
		skills_button.pressed.connect(_on_skills_pressed)

func _setup_animations():
	# Configurar animaciones de entrada
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

# ==== FUNCIONES PRINCIPALES ====
func show_character(character: Character):
	"""Mostrar los detalles de un personaje"""
	if not character:
		print("Error: Character is null")
		return
	
	current_character = character
	print("Showing details for: ", character.character_name)
	
	_update_character_display()
	_animate_character_entrance()

func _update_character_display():
	"""Actualizar toda la información del personaje"""
	if not current_character:
		return
	
	_update_header_info()
	_update_character_splash()
	_update_stats_display()
	_update_skills_display()
	_update_level_up_info()

func _update_header_info():
	"""Actualizar información del header"""
	if name_label:
		name_label.text = current_character.character_name
	
	if element_label:
		element_label.text = current_character.get_element_name()
		element_label.modulate = current_character.get_element_color()
	
	if rarity_label:
		rarity_label.text = Character.Rarity.keys()[current_character.rarity]
		rarity_label.modulate = current_character.get_rarity_color()
	
	if class_label:
		var class_name = CharacterTemplate.CharacterClass.keys()[current_character.character_class]
		class_label.text = class_name.capitalize()

func _update_character_splash():
	"""Actualizar el splash del personaje"""
	
	# Actualizar imagen del personaje (emoji basado en clase)
	if character_image:
		character_image.text = _get_character_emoji()
	
	# Actualizar icono de elemento
	if element_icon:
		element_icon.text = _get_element_emoji()
		element_icon.modulate = current_character.get_element_color()
	
	# Actualizar nivel
	if level_text:
		level_text.text = "LV " + str(current_character.level)
	
	# Actualizar borde según rareza
	if splash_border:
		splash_border.color = current_character.get_rarity_color()
	
	# Actualizar poder
	if power_display:
		var power = _calculate_character_power(current_character)
		power_display.text = "Power: " + str(power)

func _get_character_emoji() -> String:
	"""Obtener emoji basado en la clase del personaje"""
	match current_character.character_class:
		CharacterTemplate.CharacterClass.WARRIOR:
			return "⚔️"
		CharacterTemplate.CharacterClass.MAGE:
			return "🔮"
		CharacterTemplate.CharacterClass.ARCHER:
			return "🏹"
		CharacterTemplate.CharacterClass.HEALER:
			return "✨"
		CharacterTemplate.CharacterClass.ASSASSIN:
			return "🗡️"
		CharacterTemplate.CharacterClass.TANK:
			return "🛡️"
		CharacterTemplate.CharacterClass.SUPPORT:
			return "💫"
		_:
			return "⭐"

func _get_element_emoji() -> String:
	"""Obtener emoji basado en el elemento"""
	match current_character.element:
		Character.Element.WATER:
			return "💧"
		Character.Element.FIRE:
			return "🔥"
		Character.Element.EARTH:
			return "🌍"
		Character.Element.RADIANT:
			return "☀️"
		Character.Element.VOID:
			return "🌙"
		_:
			return "⚡"

func _update_stats_display():
	"""Actualizar display de estadísticas"""
	if hp_value:
		hp_value.text = str(current_character.current_hp) + " / " + str(current_character.max_hp)
		hp_value.modulate = Color.GREEN if current_character.current_hp == current_character.max_hp else Color.YELLOW
	
	if attack_value:
		attack_value.text = str(current_character.attack)
	
	if defense_value:
		defense_value.text = str(current_character.defense)
	
	if speed_value:
		speed_value.text = str(current_character.speed)
	
	if crit_chance_value:
		crit_chance_value.text = str(int(current_character.crit_chance * 100)) + "%"
	
	if crit_damage_value:
		crit_damage_value.text = str(int(current_character.crit_damage * 100)) + "%"

func _update_skills_display():
	"""Actualizar display de habilidades"""
	if not skills_list:
		return
	
	# Limpiar skills existentes
	for child in skills_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Agregar skills del personaje
	for i in range(current_character.skills.size()):
		var skill = current_character.skills[i]
		var skill_item = _create_skill_item(skill, i)
		skills_list.add_child(skill_item)

func _create_skill_item(skill: Skill, index: int) -> Control:
	"""Crear item de skill"""
	var item = Control.new()
	item.custom_minimum_size = Vector2(380, 60)
	
	# Background
	var bg = ColorRect.new()
	bg.size = Vector2(380, 60)
	bg.color = Color(0.2, 0.2, 0.3, 0.5)
	item.add_child(bg)
	
	# Nombre del skill
	var name_label = Label.new()
	name_label.text = skill.skill_name
	name_label.position = Vector2(10, 5)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.modulate = Color.WHITE
	item.add_child(name_label)
	
	# Descripción
	var desc_label = Label.new()
	desc_label.text = skill.description
	desc_label.position = Vector2(10, 25)
	desc_label.size = Vector2(280, 20)
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.modulate = Color.LIGHT_GRAY
	item.add_child(desc_label)
	
	# Cooldown
	var cooldown_label = Label.new()
	cooldown_label.text = "CD: " + str(skill.cooldown)
	cooldown_label.position = Vector2(300, 5)
	cooldown_label.add_theme_font_size_override("font_size", 14)
	cooldown_label.modulate = Color.CYAN
	item.add_child(cooldown_label)
	
	# Elemento
	var element_label = Label.new()
	element_label.text = Character.Element.keys()[skill.element]
	element_label.position = Vector2(300, 25)
	element_label.add_theme_font_size_override("font_size", 12)
	element_label.modulate = _get_element_color(skill.element)
	item.add_child(element_label)
	
	# Número del skill
	var number_label = Label.new()
	number_label.text = str(index + 1)
	number_label.position = Vector2(350, 20)
	number_label.add_theme_font_size_override("font_size", 18)
	number_label.modulate = Color.GOLD
	item.add_child(number_label)
	
	return item

func _get_element_color(element: Character.Element) -> Color:
	"""Obtener color del elemento"""
	match element:
		Character.Element.WATER: return Color.CYAN
		Character.Element.FIRE: return Color.RED
		Character.Element.EARTH: return Color.GREEN
		Character.Element.RADIANT: return Color.YELLOW
		Character.Element.VOID: return Color.PURPLE
		_: return Color.WHITE

func _update_level_up_info():
	"""Actualizar información de level up"""
	if not level_up_info or not level_up_button:
		return
	
	var cost = _calculate_level_up_cost()
	var can_afford = game_manager and game_manager.game_currency >= cost
	
	level_up_info.text = "Cost: " + str(cost) + " Gold"
	level_up_button.disabled = not can_afford
	
	if can_afford:
		level_up_info.modulate = Color.WHITE
		level_up_button.modulate = Color.WHITE
	else:
		level_up_info.modulate = Color.RED
		level_up_button.modulate = Color.GRAY

func _calculate_level_up_cost() -> int:
	"""Calcular costo de subir nivel"""
	if not current_character:
		return 0
	
	var base_cost = 100
	var level_multiplier = current_character.level
	return base_cost * level_multiplier

func _calculate_character_power(character: Character) -> int:
	"""Calcular poder del personaje"""
	return character.max_hp + character.attack * 5 + character.defense * 3 + character.speed * 2

# ==== ANIMACIONES ====
func _animate_character_entrance():
	"""Animar entrada del personaje"""
	if not character_splash:
		return
	
	# Animación de escala
	character_splash.scale = Vector2(0.8, 0.8)
	var tween = create_tween()
	tween.parallel().tween_property(character_splash, "scale", Vector2(1.0, 1.0), 0.5)
	tween.tween_property(character_splash, "scale", Vector2(1.02, 1.02), 0.1)
	tween.tween_property(character_splash, "scale", Vector2(1.0, 1.0), 0.1)

# ==== EVENT HANDLERS ====
func _on_back_pressed():
	"""Manejar botón de back"""
	print("Back button pressed")
	
	# Animación de salida
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	await tween.finished
	
	back_pressed.emit()

func _on_level_up_pressed():
	"""Manejar level up"""
	if not current_character or not game_manager:
		return
	
	var cost = _calculate_level_up_cost()
	
	if game_manager.game_currency < cost:
		_show_insufficient_funds_message()
		return
	
	# Realizar level up
	game_manager.spend_currency(cost)
	current_character.level += 1
	current_character._calculate_stats()
	current_character.current_hp = current_character.max_hp  # Curar completamente
	
	print("Level up! ", current_character.character_name, " is now level ", current_character.level)
	
	# Actualizar display
	_update_character_display()
	_animate_level_up()
	
	# Emitir señal
	character_updated.emit(current_character)

func _animate_level_up():
	"""Animar level up"""
	if not level_text:
		return
	
	# Efecto de level up
	var original_scale = level_text.scale
	var tween = create_tween()
	tween.tween_property(level_text, "scale", Vector2(1.5, 1.5), 0.2)
	tween.tween_property(level_text, "scale", original_scale, 0.2)
	
	# Cambiar color temporalmente
	var original_color = level_text.modulate
	level_text.modulate = Color.GOLD
	tween.tween_property(level_text, "modulate", original_color, 0.5)

func _on_equipment_pressed():
	"""Manejar botón de equipment (futuro)"""
	_show_coming_soon_message("Equipment System")

func _on_skills_pressed():
	"""Manejar botón de enhance skills (futuro)"""
	_show_coming_soon_message("Skill Enhancement")

# ==== UTILITY FUNCTIONS ====
func _show_insufficient_funds_message():
	"""Mostrar mensaje de fondos insuficientes"""
	var popup = AcceptDialog.new()
	popup.dialog_text = "Insufficient gold to level up!\nNeed: " + str(_calculate_level_up_cost()) + " gold"
	popup.title = "Not Enough Gold"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

# ==== FUNCIONES PÚBLICAS ====
func refresh_character_display():
	"""Refrescar display del personaje"""
	if current_character:
		_update_character_display()

func get_current_character() -> Character:
	"""Obtener personaje actual"""
	return current_character

func set_character_and_show(character: Character):
	"""Función pública para mostrar personaje"""
	show_character(character)_centered()
	popup.confirmed.connect(func(): popup.queue_free())

func _show_coming_soon_message(feature_name: String):
	"""Mostrar mensaje de próximamente"""
	var popup = AcceptDialog.new()
	popup.dialog_text = feature_name + " coming soon!\nThis feature will be available in a future update."
	popup.title = "Coming Soon"
	add_child(popup)
	popup.popup
