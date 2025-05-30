# ==== ENHANCED BATTLE UI CORREGIDO (EnhancedBattleUI.gd) ====
extends Control

@onready var turn_info = $VBoxContainer/TopPanel/TurnInfo
@onready var player_team_display = $VBoxContainer/MiddlePanel/PlayerTeam
@onready var enemy_team_display = $VBoxContainer/MiddlePanel/EnemyTeam
@onready var skill_buttons = $VBoxContainer/BottomPanel/SkillButtons
@onready var target_selection = $VBoxContainer/BottomPanel/TargetSelection
@onready var combat_log = $VBoxContainer/BottomPanel/CombatLog
@onready var speed_bar = $VBoxContainer/TopPanel/SpeedBar

var battle_system: BattleSystem
var game_manager: GameManager
var current_character: Character
var selected_skill: Skill
var available_targets: Array[Character] = []

signal skill_selected(skill, targets)
signal battle_exit()

func _ready():
	# Esperar varios frames para que Main.gd termine de crear los sistemas
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Buscar los sistemas desde el nodo padre correcto
	battle_system = get_node_or_null("../BattleSystem")
	game_manager = get_node_or_null("../GameManager")
	
	if battle_system == null:
		print("Warning: BattleSystem not found, waiting...")
		await get_tree().create_timer(0.5).timeout
		battle_system = get_node_or_null("../BattleSystem")
		
		if battle_system == null:
			print("Error: BattleSystem not found!")
			return
	
	if game_manager == null:
		print("Warning: GameManager not found, waiting...")
		await get_tree().create_timer(0.5).timeout
		game_manager = get_node_or_null("../GameManager")
		
		if game_manager == null:
			print("Error: GameManager not found!")
			return
	
	_setup_connections()

func _setup_connections():
	if battle_system:
		battle_system.turn_started.connect(_on_turn_started)
		battle_system.skill_used.connect(_on_skill_used)
		battle_system.battle_phase_changed.connect(_on_battle_phase_changed)

func _on_turn_started(character: Character):
	current_character = character
	_update_turn_display()
	_update_team_displays()
	_update_speed_bar()
	
	if character.character_type == Character.CharacterType.PLAYER:
		_show_skill_selection()
	else:
		_hide_skill_selection()

func _update_turn_display():
	if not turn_info:
		return
		
	var current_turn_label = turn_info.get_node_or_null("CurrentTurn")
	var turn_counter_label = turn_info.get_node_or_null("TurnCounter")
	
	if current_turn_label:
		current_turn_label.text = current_character.character_name + "'s Turn"
	
	if turn_counter_label and battle_system:
		turn_counter_label.text = "Turn: " + str(battle_system.turn_counter)

func _update_team_displays():
	if game_manager:
		_update_team_display(player_team_display, game_manager.player_team)
		_update_team_display(enemy_team_display, game_manager.enemy_team)

func _update_team_display(container: Control, team: Array[Character]):
	if not container:
		return
		
	# Clear existing displays
	for child in container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Create character displays
	for character in team:
		var char_display = _create_character_display(character)
		container.add_child(char_display)

func _create_character_display(character: Character) -> Control:
	# Crear display simple por ahora
	var display = Control.new()
	display.custom_minimum_size = Vector2(120, 100)
	
	# Basic info
	var name_label = Label.new()
	name_label.text = character.character_name
	name_label.position = Vector2(5, 5)
	display.add_child(name_label)
	
	var level_label = Label.new()
	level_label.text = "Lv." + str(character.level)
	level_label.position = Vector2(5, 25)
	display.add_child(level_label)
	
	# HP Bar simple
	var hp_bar = ProgressBar.new()
	hp_bar.size = Vector2(100, 20)
	hp_bar.position = Vector2(10, 45)
	hp_bar.max_value = character.max_hp
	hp_bar.value = character.current_hp
	display.add_child(hp_bar)
	
	var hp_text = Label.new()
	hp_text.text = str(character.current_hp) + "/" + str(character.max_hp)
	hp_text.position = Vector2(10, 70)
	hp_text.size = Vector2(100, 20)
	display.add_child(hp_text)
	
	# Dim if dead
	if not character.is_alive():
		display.modulate = Color.GRAY
	
	# Click for targeting
	if current_character and character.character_type != current_character.character_type:
		display.gui_input.connect(func(event): _on_character_clicked(event, character))
	
	return display

func _update_speed_bar():
	if not speed_bar:
		return
		
	var speed_display = speed_bar.get_node_or_null("TurnOrder")
	if not speed_display:
		# Crear contenedor si no existe
		speed_display = HBoxContainer.new()
		speed_display.name = "TurnOrder"
		speed_bar.add_child(speed_display)
	
	# Clear existing
	for child in speed_display.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	if not game_manager:
		return
	
	# Get all characters sorted by CR
	var all_chars: Array[Character] = []
	all_chars.append_array(game_manager.player_team)
	all_chars.append_array(game_manager.enemy_team)
	
	all_chars = all_chars.filter(func(char): return char.is_alive())
	all_chars.sort_custom(func(a, b): return a.combat_readiness > b.combat_readiness)
	
	# Display first 8 characters in turn order
	for i in range(min(8, all_chars.size())):
		var character = all_chars[i]
		var turn_icon = _create_turn_icon(character)
		speed_display.add_child(turn_icon)

func _create_turn_icon(character: Character) -> Control:
	var icon = ColorRect.new()
	icon.size = Vector2(40, 40)
	icon.color = character.get_element_color()
	
	var name_label = Label.new()
	name_label.text = character.character_name.substr(0, 3)
	name_label.size = Vector2(40, 20)
	icon.add_child(name_label)
	
	var cr_label = Label.new()
	cr_label.text = str(int(character.combat_readiness))
	cr_label.position = Vector2(0, 20)
	cr_label.size = Vector2(40, 20)
	icon.add_child(cr_label)
	
	return icon

func _show_skill_selection():
	if not skill_buttons or not current_character:
		return
		
	# Clear existing buttons
	for child in skill_buttons.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Create skill buttons
	for i in range(current_character.skills.size()):
		var skill = current_character.skills[i]
		var button = _create_skill_button(skill, i)
		skill_buttons.add_child(button)

func _create_skill_button(skill: Skill, index: int) -> Button:
	var button = Button.new()
	button.text = skill.skill_name
	button.custom_minimum_size = Vector2(100, 40)
	
	# Disable if on cooldown
	if not skill.can_use():
		button.disabled = true
		button.text += " (" + str(skill.current_cooldown) + ")"
	
	button.pressed.connect(func(): _on_skill_selected(skill))
	
	# Add tooltip with skill info
	var tooltip = skill.description + "\n"
	tooltip += "Cooldown: " + str(skill.cooldown) + "\n"
	tooltip += "Element: " + Character.Element.keys()[skill.element]
	button.tooltip_text = tooltip
	
	return button

func _hide_skill_selection():
	if not skill_buttons:
		return
		
	for child in skill_buttons.get_children():
		child.visible = false

func _on_skill_selected(skill: Skill):
	selected_skill = skill
	available_targets = battle_system._get_ai_targets(current_character, skill)
	_show_target_selection()

func _show_target_selection():
	if not target_selection:
		return
		
	target_selection.visible = true
	
	if available_targets.size() == 1:
		# Auto-select single target
		_execute_skill_on_targets([available_targets[0]])
	else:
		# Let player choose target
		var instruction = target_selection.get_node_or_null("Instruction")
		if not instruction:
			instruction = Label.new()
			instruction.name = "Instruction"
			target_selection.add_child(instruction)
		
		instruction.text = "Select target for " + selected_skill.skill_name

func _on_character_clicked(event: InputEvent, character: Character):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if character in available_targets:
			_execute_skill_on_targets([character])

func _execute_skill_on_targets(targets: Array[Character]):
	if target_selection:
		target_selection.visible = false
	
	skill_selected.emit(selected_skill, targets)
	
	if battle_system:
		battle_system.execute_skill(current_character, selected_skill, targets)

func _on_skill_used(caster: Character, skill: Skill, targets: Array[Character], results: Array):
	# Add to combat log
	var log_entry = caster.character_name + " used " + skill.skill_name + "\n"
	
	for i in range(results.size()):
		var result = results[i]
		var target = targets[i]
		
		if result.damage_dealt > 0:
			log_entry += "  " + target.character_name + " takes " + str(result.damage_dealt) + " damage"
			if result.is_critical:
				log_entry += " (CRIT!)"
			if result.is_weakness:
				log_entry += " (WEAKNESS!)"
			log_entry += "\n"
		elif result.damage_dealt < 0:
			log_entry += "  " + target.character_name + " heals " + str(-result.damage_dealt) + " HP\n"
		
		for effect in result.effects_applied:
			log_entry += "  " + effect.effect_name + " applied to " + target.character_name + "\n"
	
	_add_to_combat_log(log_entry)

func _add_to_combat_log(text: String):
	if not combat_log:
		return
		
	var log_label = Label.new()
	log_label.text = text
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_log.add_child(log_label)
	
	# Scroll to bottom
	var scroll_container = combat_log.get_parent()
	if scroll_container is ScrollContainer:
		scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value

func _on_battle_phase_changed(phase):
	match phase:
		BattleSystem.BattlePhase.VICTORY:
			_show_victory_screen()
		BattleSystem.BattlePhase.DEFEAT:
			_show_defeat_screen()

func _show_victory_screen():
	print("Victory! Creating victory screen...")
	# Por ahora, mostrar mensaje simple
	var victory_label = Label.new()
	victory_label.text = "VICTORY!"
	victory_label.position = Vector2(400, 300)
	victory_label.add_theme_font_size_override("font_size", 48)
	add_child(victory_label)
	
	# Auto-close after 3 seconds
	await get_tree().create_timer(3.0).timeout
	victory_label.queue_free()

func _show_defeat_screen():
	print("Defeat! Creating defeat screen...")
	# Por ahora, mostrar mensaje simple
	var defeat_label = Label.new()
	defeat_label.text = "DEFEAT"
	defeat_label.position = Vector2(400, 300)
	defeat_label.add_theme_font_size_override("font_size", 48)
	defeat_label.modulate = Color.RED
	add_child(defeat_label)
	
	# Auto-close after 3 seconds
	await get_tree().create_timer(3.0).timeout
	defeat_label.queue_free()

func _calculate_battle_rewards() -> Dictionary:
	return {
		"experience": 100,
		"gold": 150,
		"items": []
	}
