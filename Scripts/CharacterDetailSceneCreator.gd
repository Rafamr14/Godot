# ==== CHARACTER DETAIL SCENE CREATOR ====
# Utilitario para crear la escena CharacterDetailUI.tscn programáticamente

@tool
class_name CharacterDetailSceneCreator

static func create_character_detail_scene() -> Control:
	"""Crear la escena de detalles de personaje programáticamente"""
	
	# Nodo raíz
	var root = Control.new()
	root.name = "CharacterDetailUI"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# Agregar script
	var script = load("res://Scripts/CharacterDetailController.gd")
	if script:
		root.set_script(script)
	
	# Background
	var background = ColorRect.new()
	background.name = "Background"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.1, 0.1, 0.1, 0.95)
	root.add_child(background)
	
	# Container principal
	var main_container = HBoxContainer.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.position = Vector2(-400, -300)
	main_container.size = Vector2(800, 600)
	root.add_child(main_container)
	
	# Panel izquierdo
	var left_panel = _create_left_panel()
	main_container.add_child(left_panel)
	
	# Panel derecho
	var right_panel = _create_right_panel()
	main_container.add_child(right_panel)
	
	return root

static func _create_left_panel() -> VBoxContainer:
	"""Crear panel izquierdo con splash del personaje"""
	var left_panel = VBoxContainer.new()
	left_panel.name = "LeftPanel"
	left_panel.custom_minimum_size = Vector2(350, 0)
	
	# Character Splash
	var character_splash = Control.new()
	character_splash.name = "CharacterSplash"
	character_splash.custom_minimum_size = Vector2(350, 400)
	left_panel.add_child(character_splash)
	
	# Background del splash
	var splash_bg = ColorRect.new()
	splash_bg.name = "SplashBackground"
	splash_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_bg.color = Color(0.2, 0.2, 0.3, 1)
	character_splash.add_child(splash_bg)
	
	# Borde del splash
	var splash_border = ColorRect.new()
	splash_border.name = "SplashBorder"
	splash_border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_border.color = Color(0.8, 0.8, 0.8, 1)
	character_splash.add_child(splash_border)
	
	# Interior del splash
	var splash_inner = ColorRect.new()
	splash_inner.name = "SplashInner"
	splash_inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	splash_inner.offset_left = 3
	splash_inner.offset_top = 3
	splash_inner.offset_right = -3
	splash_inner.offset_bottom = -3
	splash_inner.color = Color(0.15, 0.15, 0.2, 1)
	character_splash.add_child(splash_inner)
	
	# Imagen del personaje
	var character_image = Label.new()
	character_image.name = "CharacterImage"
	character_image.set_anchors_preset(Control.PRESET_CENTER)
	character_image.position = Vector2(-50, -50)
	character_image.size = Vector2(100, 100)
	character_image.add_theme_font_size_override("font_size", 72)
	character_image.text = "🛡️"
	character_image.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	character_image.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	character_splash.add_child(character_image)
	
	# Icono de elemento
	var element_icon = Label.new()
	element_icon.name = "ElementIcon"
	element_icon.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	element_icon.position = Vector2(-40, 10)
	element_icon.size = Vector2(30, 30)
	element_icon.add_theme_font_size_override("font_size", 24)
	element_icon.text = "🔥"
	element_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	character_splash.add_child(element_icon)
	
	# Badge de nivel
	var level_badge = _create_level_badge()
	character_splash.add_child(level_badge)
	
	# Display de poder
	var power_display = Label.new()
	power_display.name = "PowerDisplay"
	power_display.add_theme_font_size_override("font_size", 18)
	power_display.text = "Power: 0"
	power_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left_panel.add_child(power_display)
	
	return left_panel

static func _create_level_badge() -> Control:
	"""Crear badge de nivel"""
	var level_badge = Control.new()
	level_badge.name = "LevelBadge"
	level_badge.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	level_badge.position = Vector2(-80, -40)
	level_badge.size = Vector2(70, 30)
	
	var level_bg = ColorRect.new()
	level_bg.name = "LevelBackground"
	level_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_bg.color = Color(0.2, 0.2, 0.2, 0.9)
	level_badge.add_child(level_bg)
	
	var level_text = Label.new()
	level_text.name = "LevelText"
	level_text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	level_text.add_theme_font_size_override("font_size", 16)
	level_text.text = "LV 1"
	level_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_badge.add_child(level_text)
	
	return level_badge

static func _create_right_panel() -> VBoxContainer:
	"""Crear panel derecho con información y controles"""
	var right_panel = VBoxContainer.new()
	right_panel.name = "RightPanel"
	right_panel.custom_minimum_size = Vector2(400, 0)
	
	# Header
	var header = _create_header()
	right_panel.add_child(header)
	
	# Separador
	var separator1 = HSeparator.new()
	separator1.name = "Separator"
	right_panel.add_child(separator1)
	
	# Sección de stats
	var stats_section = _create_stats_section()
	right_panel.add_child(stats_section)
	
	# Separador
	var separator2 = HSeparator.new()
	separator2.name = "Separator2"
	right_panel.add_child(separator2)
	
	# Sección de skills
	var skills_section = _create_skills_section()
	right_panel.add_child(skills_section)
	
	# Separador
	var separator3 = HSeparator.new()
	separator3.name = "Separator3"
	right_panel.add_child(separator3)
	
	# Sección de acciones
	var actions_section = _create_actions_section()
	right_panel.add_child(actions_section)
	
	return right_panel

static func _create_header() -> VBoxContainer:
	"""Crear header con nombre y info básica"""
	var header = VBoxContainer.new()
	header.name = "Header"
	
	# Nombre
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.text = "Character Name"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_child(name_label)
	
	# Row de información
	var info_row = HBoxContainer.new()
	info_row.name = "InfoRow"
	info_row.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_child(info_row)
	
	var element_label = Label.new()
	element_label.name = "ElementLabel"
	element_label.text = "Element"
	info_row.add_child(element_label)
	
	var sep1 = Label.new()
	sep1.text = " | "
	info_row.add_child(sep1)
	
	var rarity_label = Label.new()
	rarity_label.name = "RarityLabel"
	rarity_label.text = "Rarity"
	info_row.add_child(rarity_label)
	
	var sep2 = Label.new()
	sep2.text = " | "
	info_row.add_child(sep2)
	
	var class_label = Label.new()
	class_label.name = "ClassLabel"
	class_label.text = "Class"
	info_row.add_child(class_label)
	
	return header

static func _create_stats_section() -> VBoxContainer:
	"""Crear sección de estadísticas"""
	var stats_section = VBoxContainer.new()
	stats_section.name = "StatsSection"
	
	var title = Label.new()
	title.name = "StatsTitle"
	title.add_theme_font_size_override("font_size", 20)
	title.text = "Stats"
	stats_section.add_child(title)
	
	var stats_grid = GridContainer.new()
	stats_grid.name = "StatsGrid"
	stats_grid.columns = 2
	stats_section.add_child(stats_grid)
	
	# Crear labels de stats
	var stats = ["HP", "Attack", "Defense", "Speed", "Crit Rate", "Crit DMG"]
	for stat_name in stats:
		var label = Label.new()
		label.name = stat_name.replace(" ", "") + "Label"
		label.text = stat_name + ":"
		stats_grid.add_child(label)
		
		var value = Label.new()
		value.name = stat_name.replace(" ", "") + "Value"
		value.text = "0"
		stats_grid.add_child(value)
	
	return stats_section

static func _create_skills_section() -> VBoxContainer:
	"""Crear sección de habilidades"""
	var skills_section = VBoxContainer.new()
	skills_section.name = "SkillsSection"
	
	var title = Label.new()
	title.name = "SkillsTitle"
	title.add_theme_font_size_override("font_size", 20)
	title.text = "Skills"
	skills_section.add_child(title)
	
	var skills_list = VBoxContainer.new()
	skills_list.name = "SkillsList"
	skills_section.add_child(skills_list)
	
	return skills_section

static func _create_actions_section() -> VBoxContainer:
	"""Crear sección de acciones"""
	var actions_section = VBoxContainer.new()
	actions_section.name = "ActionsSection"
	
	# Level up
	var level_up_container = HBoxContainer.new()
	level_up_container.name = "LevelUpContainer"
	actions_section.add_child(level_up_container)
	
	var level_up_btn = Button.new()
	level_up_btn.name = "LevelUpButton"
	level_up_btn.custom_minimum_size = Vector2(150, 50)
	level_up_btn.text = "Level Up"
	level_up_container.add_child(level_up_btn)
	
	var level_up_info = Label.new()
	level_up_info.name = "LevelUpInfo"
	level_up_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_up_info.text = "Cost: 100 Gold"
	level_up_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_up_container.add_child(level_up_info)
	
	# Botones adicionales
	var buttons_row = HBoxContainer.new()
	buttons_row.name = "ButtonsRow"
	buttons_row.alignment = BoxContainer.ALIGNMENT_CENTER
	actions_section.add_child(buttons_row)
	
	var equipment_btn = Button.new()
	equipment_btn.name = "EquipmentButton"
	equipment_btn.custom_minimum_size = Vector2(120, 40)
	equipment_btn.text = "Equipment"
	buttons_row.add_child(equipment_btn)
	
	var skills_btn = Button.new()
	skills_btn.name = "SkillsButton"
	skills_btn.custom_minimum_size = Vector2(120, 40)
	skills_btn.text = "Enhance"
	buttons_row.add_child(skills_btn)
	
	# Back button
	var back_btn = Button.new()
	back_btn.name = "BackButton"
	back_btn.custom_minimum_size = Vector2(200, 50)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.text = "Back to Inventory"
	actions_section.add_child(back_btn)
	
	return actions_section
