# ==== ENHANCED BATTLE CONTROLLER ====
extends Control

# Referencias UI principales
@onready var background = $Background
@onready var main_container = $MainContainer

# Top Panel
@onready var battle_header = $MainContainer/TopPanel/BattleHeader
@onready var turn_indicator = $MainContainer/TopPanel/TurnInfo/CurrentTurnLabel
@onready var turn_counter = $MainContainer/TopPanel/TurnInfo/TurnCounterLabel
@onready var speed_bar_container = $MainContainer/TopPanel/SpeedBarContainer

# Middle Panel - Teams
@onready var player_team_container = $MainContainer/MiddlePanel/PlayerTeamContainer/PlayerTeamDisplay
@onready var vs_label = $MainContainer/MiddlePanel/VSLabel
@onready var enemy_team_container = $MainContainer/MiddlePanel/EnemyTeamContainer/EnemyTeamDisplay

# Bottom Panel - Actions
@onready var skills_container = $MainContainer/BottomPanel/SkillsPanel/SkillsContainer
@onready var target_panel = $MainContainer/BottomPanel/TargetPanel
@onready var combat_log_scroll = $MainContainer/BottomPanel/CombatLogPanel/CombatLogScroll
@onready var combat_log = $MainContainer/BottomPanel/CombatLogPanel/CombatLogScroll/CombatLog

# Sistemas
var battle_system: BattleSystem
var enhanced_chapter_system: EnhancedChapterSystem
var game_manager: GameManager
var main_controller: Control

# Estado de batalla
var current_chapter_id: int = 0
var current_stage_id: int = 0
var current_character: Character
var selected_skill: Skill
var available_targets: Array[Character] = []
var battle_active: bool = false

# Señales
signal battle_finished(victory: bool)
signal back_to_chapters()

func _ready():
	print("EnhancedBattleController: Inicializando batalla épica...")
	await _initialize_systems()
	_setup_ui()
	print("EnhancedBattleController: Listo para la batalla!")

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
		battle_system = main_controller.get_battle_system()
		enhanced_chapter_system = main_controller.get_chapter_system()
	else:
		game_manager = get_tree().get_first_node_in_group("game_manager")
		battle_system = get_tree().get_first_node_in_group("battle_system")
		enhanced_chapter_system = get_tree().get_first_node_in_group("chapter_system")
	
	print("✓ Enhanced Battle systems initialized")

func _setup_ui():
	"""Configurar interfaz de batalla"""
	if combat_log:
		_add_log_entry("⚔️ Battle system ready!")
	
	# Conectar señales del battle system
	if battle_system:
		if battle_system.has_signal("turn_started"):
			battle_system.turn_started.connect(_on_turn_started)
		if battle_system.has_signal("skill_used"):
			battle_system.skill_used.connect(_on_skill_used)
		if battle_system.has_signal("battle_phase_changed"):
			battle_system.battle_phase_changed.connect(_on_battle_phase_changed)

func start_battle(chapter_id: int, stage_id: int):
	"""Iniciar batalla específica"""
	print("Starting battle: Chapter ", chapter_id, " Stage ", stage_id)
	
	current_chapter_id = chapter_id
	current_stage_id = stage_id
	battle_active = true
	
	# Obtener datos del stage
	var stage_data = enhanced_chapter_system.get_stage_data(chapter_id, stage_id)
	if not stage_data:
		_show_error("Stage data not found!")
		return
	
	# Configurar header de batalla
	if battle_header:
		battle_header.text = "⚔️ " + stage_data.stage_name
	
	# Iniciar el battle system
	if battle_system and game_manager:
		battle_system.start_battle(game_manager.player_team, stage_data.enemies)
		_add_log_entry("🌟 Battle begins: " + stage_data.stage_name)
		_update_team_displays()

func _on_turn_started(character: Character):
	"""Manejar inicio de turno"""
	current_character = character
	
	# Actualizar indicador de turno
	if turn_indicator:
		turn_indicator.text = character.character_name + "'s Turn"
		turn_indicator.modulate = character.get_element_color()
	
	if turn_counter and battle_system:
		turn_counter.text = "Turn: " + str(battle_system.turn_counter)
	
	# Actualizar displays
	_update_team_displays()
	_update_speed_bar()
	
	# Procesar turno según tipo de personaje
	if character.character_type == Character.CharacterType.PLAYER:
		_show_player_skills()
		_add_log_entry("🎯 " + character.character_name + " - Choose your action!")
	else:
		_hide_player_skills()
		_add_log_entry("👹 " + character.character_name + " is planning their move...")

func _show_player_skills():
	"""Mostrar skills del jugador"""
	if not skills_container or not current_character:
		return
	
	# Limpiar skills anteriores
	for child in skills_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Crear botones de skills
	for i in range(current_character.skills.size()):
		var skill = current_character.skills[i]
		var skill_button = _create_skill_button(skill, i)
		skills_container.add_child(skill_button)

func _create_skill_button(skill: Skill, index: int) -> Button:
	"""Crear botón de skill"""
	var button = Button.new()
	button.custom_minimum_size = Vector2(120, 60)
	
	# Texto del botón
	var button_text = skill.skill_name
	if skill.current_cooldown > 0:
		button_text += "\nCD: " + str(skill.current_cooldown)
		button.disabled = true
		button.modulate = Color(0.6, 0.6, 0.6, 1)
	else:
		button_text += "\nReady!"
		button.modulate = Color.WHITE
	
	button.text = button_text
	
	# Conexión
	if skill.can_use():
		button.pressed.connect(func(): _on_skill_selected(skill))
	
	# Tooltip con información del skill
	var tooltip = skill.description + "\n"
	tooltip += "Element: " + Character.Element.keys()[skill.element] + "\n"
	tooltip += "Cooldown: " + str(skill.cooldown) + " turns"
	button.tooltip_text = tooltip
	
	return button

func _hide_player_skills():
	"""Ocultar skills del jugador"""
	if not skills_container:
		return
	
	for child in skills_container.get_children():
		child.visible = false

func _on_skill_selected(skill: Skill):
	"""Manejar selección de skill"""
	selected_skill = skill
	print("Skill selected: ", skill.skill_name)
	
	# Obtener targets disponibles
	available_targets = _get_valid_targets(skill)
	
	if available_targets.size() == 1:
		# Auto-ejecutar si solo hay un target
		_execute_skill([available_targets[0]])
	else:
		# Mostrar selección de targets
		_show_target_selection()

func _get_valid_targets(skill: Skill) -> Array[Character]:
	"""Obtener targets válidos para un skill"""
	var targets: Array[Character] = []
	
	if not game_manager:
		return targets
	
	match skill.target_type:
		Skill.TargetType.SINGLE_ENEMY:
			targets = game_manager.enemy_team.filter(func(char): return char.is_alive())
		Skill.TargetType.ALL_ENEMIES:
			targets = game_manager.enemy_team.filter(func(char): return char.is_alive())
		Skill.TargetType.SINGLE_ALLY:
			targets = game_manager.player_team.filter(func(char): return char.is_alive())
		Skill.TargetType.ALL_ALLIES:
			targets = game_manager.player_team.filter(func(char): return char.is_alive())
		Skill.TargetType.SELF:
			targets = [current_character]
	
	return targets

func _show_target_selection():
	"""Mostrar selección de targets"""
	if not target_panel:
		return
	
	target_panel.visible = true
	
	# Limpiar targets anteriores
	for child in target_panel.get_children():
		if child.name.begins_with("TargetButton"):
			child.queue_free()
	
	await get_tree().process_frame
	
	# Crear botones de target
	for i in range(available_targets.size()):
		var target = available_targets[i]
		var target_button = _create_target_button(target, i)
		target_panel.add_child(target_button)

func _create_target_button(target: Character, index: int) -> Button:
	"""Crear botón de target"""
	var button = Button.new()
	button.name = "TargetButton" + str(index)
	button.custom_minimum_size = Vector2(100, 40)
	
	var button_text = target.character_name
	button_text += "\nHP: " + str(target.current_hp) + "/" + str(target.max_hp)
	button.text = button_text
	
	# Color según tipo
	if target.character_type == Character.CharacterType.ENEMY:
		button.modulate = Color(1, 0.7, 0.7, 1)  # Rojizo para enemigos
	else:
		button.modulate = Color(0.7, 1, 0.7, 1)  # Verdoso para aliados
	
	button.pressed.connect(func(): _execute_skill([target]))
	
	return button

func _execute_skill(targets: Array[Character]):
	"""Ejecutar skill seleccionado"""
	if not battle_system or not selected_skill or not current_character:
		return
	
	# Ocultar panel de targets
	if target_panel:
		target_panel.visible = false
	
	print("Executing skill: ", selected_skill.skill_name, " on ", targets.size(), " targets")
	
	# Ejecutar a través del battle system
	battle_system.execute_skill(current_character, selected_skill, targets)

func _on_skill_used(caster: Character, skill: Skill, targets: Array[Character], results: Array):
	"""Manejar uso de skill"""
	print("Skill used: ", caster.character_name, " -> ", skill.skill_name)
	
	# Agregar al log de combate
	var log_entry = "⚡ " + caster.character_name + " uses " + skill.skill_name
	_add_log_entry(log_entry)
	
	# Procesar resultados
	for i in range(results.size()):
		if i >= targets.size():
			break
			
		var result = results[i]
		var target = targets[i]
		
		var result_text = ""
		
		if result.damage_dealt > 0:
			result_text = "💥 " + target.character_name + " takes " + str(result.damage_dealt) + " damage"
			if result.is_critical:
				result_text += " (CRITICAL!)"
			if result.is_weakness:
				result_text += " (WEAKNESS!)"
		elif result.damage_dealt < 0:
			result_text = "💚 " + target.character_name + " heals " + str(-result.damage_dealt) + " HP"
		
		if not result_text.is_empty():
			_add_log_entry(result_text)
		
		# Efectos aplicados
		for effect in result.effects_applied:
			_add_log_entry("✨ " + effect.effect_name + " applied to " + target.character_name)
	
	# Actualizar displays
	_update_team_displays()

func _on_battle_phase_changed(phase):
	"""Manejar cambio de fase de batalla"""
	match phase:
		BattleSystem.BattlePhase.VICTORY:
			_handle_victory()
		BattleSystem.BattlePhase.DEFEAT:
			_handle_defeat()

func _handle_victory():
	"""Manejar victoria"""
	battle_active = false
	_add_log_entry("🎉 VICTORY! Stage completed!")
	
	# Completar stage en el chapter system
	if enhanced_chapter_system:
		var rewards = enhanced_chapter_system.complete_stage(current_chapter_id, current_stage_id, true)
		if rewards:
			_show_victory_screen(rewards)
	
	battle_finished.emit(true)

func _handle_defeat():
	"""Manejar derrota"""
	battle_active = false
	_add_log_entry("💀 DEFEAT! Your heroes have fallen...")
	
	# Notificar derrota al chapter system
	if enhanced_chapter_system:
		enhanced_chapter_system.complete_stage(current_chapter_id, current_stage_id, false)
	
	_show_defeat_screen()
	battle_finished.emit(false)

func _show_victory_screen(rewards: StageRewards):
	"""Mostrar pantalla de victoria"""
	var victory_popup = AcceptDialog.new()
	victory_popup.title = "🎉 VICTORY!"
	
	var reward_text = "Stage completed successfully!\n\n"
	reward_text += "Rewards:\n"
	reward_text += "💰 Gold: " + str(rewards.gold) + "\n"
	reward_text += "⭐ Experience: " + str(rewards.experience) + "\n"
	
	if rewards.summon_tickets > 0:
		reward_text += "🎫 Summon Tickets: " + str(rewards.summon_tickets) + "\n"
	
	if rewards.guaranteed_character:
		reward_text += "🌟 Hero Obtained: " + rewards.guaranteed_character.character_name + "\n"
	
	victory_popup.dialog_text = reward_text
	add_child(victory_popup)
	victory_popup.popup_centered()
	
	victory_popup.confirmed.connect(func(): 
		victory_popup.queue_free()
		back_to_chapters.emit()
	)

func _show_defeat_screen():
	"""Mostrar pantalla de derrota"""
	var defeat_popup = AcceptDialog.new()
	defeat_popup.title = "💀 DEFEAT"
	defeat_popup.dialog_text = "Your heroes have been defeated!\n\nTrain harder and try again.\n\nTip: Level up your heroes or adjust your team composition."
	add_child(defeat_popup)
	defeat_popup.popup_centered()
	
	defeat_popup.confirmed.connect(func(): 
		defeat_popup.queue_free()
		back_to_chapters.emit()
	)

func _update_team_displays():
	"""Actualizar displays de equipos"""
	if game_manager:
		_update_team_container(player_team_container, game_manager.player_team, true)
		_update_team_container(enemy_team_container, game_manager.enemy_team, false)

func _update_team_container(container: Control, team: Array[Character], is_player_team: bool):
	"""Actualizar contenedor de equipo"""
	if not container:
		return
	
	# Limpiar container
	for child in container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Crear displays para cada personaje
	for character in team:
		var char_display = _create_character_display(character, is_player_team)
		container.add_child(char_display)

func _create_character_display(character: Character, is_player: bool) -> Control:
	"""Crear display de personaje"""
	var display = VBoxContainer.new()
	display.custom_minimum_size = Vector2(120, 140)
	
	# Background
	var bg = ColorRect.new()
	bg.color = character.get_rarity_color() * 0.3
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.add_child(bg)
	
	# Nombre
	var name_label = Label.new()
	name_label.text = character.character_name
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.modulate = character.get_rarity_color()
	display.add_child(name_label)
	
	# Nivel y elemento
	var level_element = Label.new()
	level_element.text = "Lv." + str(character.level) + " " + character.get_element_name()
	level_element.add_theme_font_size_override("font_size", 10)
	level_element.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_element.modulate = character.get_element_color()
	display.add_child(level_element)
	
	# Barra de HP
	var hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(100, 20)
	hp_bar.max_value = character.max_hp
	hp_bar.value = character.current_hp
	hp_bar.show_percentage = false
	display.add_child(hp_bar)
	
	# Texto de HP
	var hp_text = Label.new()
	hp_text.text = str(character.current_hp) + "/" + str(character.max_hp)
	hp_text.add_theme_font_size_override("font_size", 10)
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display.add_child(hp_text)
	
	# Combat Readiness
	var cr_bar = ProgressBar.new()
	cr_bar.custom_minimum_size = Vector2(100, 15)
	cr_bar.max_value = 100
	cr_bar.value = character.combat_readiness
	cr_bar.show_percentage = false
	cr_bar.modulate = Color.CYAN
	display.add_child(cr_bar)
	
	var cr_text = Label.new()
	cr_text.text = "CR: " + str(int(character.combat_readiness))
	cr_text.add_theme_font_size_override("font_size", 8)
	cr_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	display.add_child(cr_text)
	
	# Efectos de estado
	var effects_container = HBoxContainer.new()
	effects_container.alignment = BoxContainer.ALIGNMENT_CENTER
	display.add_child(effects_container)
	
	# Mostrar buffs/debuffs
	for buff in character.buffs:
		var buff_icon = Label.new()
		buff_icon.text = "+"
		buff_icon.modulate = Color.GREEN
		buff_icon.add_theme_font_size_override("font_size", 12)
		effects_container.add_child(buff_icon)
	
	for debuff in character.debuffs:
		var debuff_icon = Label.new()
		debuff_icon.text = "-"
		debuff_icon.modulate = Color.RED
		debuff_icon.add_theme_font_size_override("font_size", 12)
		effects_container.add_child(debuff_icon)
	
	# Dim si está muerto
	if not character.is_alive():
		display.modulate = Color(0.5, 0.5, 0.5, 1)
	
	# Highlight si es el turno actual
	if character == current_character:
		var highlight = ColorRect.new()
		highlight.color = Color.YELLOW * 0.5
		highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		display.add_child(highlight)
		display.move_child(highlight, 0)  # Al fondo
	
	return display

func _update_speed_bar():
	"""Actualizar barra de velocidad"""
	if not speed_bar_container or not game_manager:
		return
	
	# Limpiar barra anterior
	for child in speed_bar_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Obtener todos los personajes vivos ordenados por CR
	var all_chars: Array[Character] = []
	all_chars.append_array(game_manager.player_team.filter(func(char): return char.is_alive()))
	all_chars.append_array(game_manager.enemy_team.filter(func(char): return char.is_alive()))
	
	all_chars.sort_custom(func(a, b): return a.combat_readiness > b.combat_readiness)
	
	# Crear iconos de velocidad
	var speed_bar = HBoxContainer.new()
	speed_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	speed_bar_container.add_child(speed_bar)
	
	for i in range(min(8, all_chars.size())):
		var character = all_chars[i]
		var icon = _create_speed_icon(character)
		speed_bar.add_child(icon)

func _create_speed_icon(character: Character) -> Control:
	"""Crear icono de velocidad"""
	var icon = VBoxContainer.new()
	icon.custom_minimum_size = Vector2(40, 50)
	
	# Indicador de personaje
	var char_icon = Label.new()
	char_icon.text = character.character_name.substr(0, 2)
	char_icon.add_theme_font_size_override("font_size", 12)
	char_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	char_icon.modulate = character.get_element_color()
	icon.add_child(char_icon)
	
	# CR
	var cr_label = Label.new()
	cr_label.text = str(int(character.combat_readiness))
	cr_label.add_theme_font_size_override("font_size", 10)
	cr_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_child(cr_label)
	
	# Background según tipo
	var bg = ColorRect.new()
	if character.character_type == Character.CharacterType.PLAYER:
		bg.color = Color.BLUE * 0.3
	else:
		bg.color = Color.RED * 0.3
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.add_child(bg)
	icon.move_child(bg, 0)
	
	return icon

func _add_log_entry(text: String):
	"""Agregar entrada al log de combate"""
	if not combat_log:
		return
	
	var log_label = Label.new()
	log_label.text = text
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_font_size_override("font_size", 12)
	combat_log.add_child(log_label)
	
	# Scroll hacia abajo
	if combat_log_scroll:
		await get_tree().process_frame
		combat_log_scroll.scroll_vertical = combat_log_scroll.get_v_scroll_bar().max_value

func _show_error(message: String):
	"""Mostrar mensaje de error"""
	var popup = AcceptDialog.new()
	popup.dialog_text = message
	popup.title = "Error"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

# ==== FUNCIONES PÚBLICAS ====
func get_battle_active() -> bool:
	return battle_active

func force_end_battle():
	"""Forzar fin de batalla"""
	battle_active = false
	back_to_chapters.emit()
