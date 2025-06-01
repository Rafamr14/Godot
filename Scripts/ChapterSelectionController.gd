# ==== CHAPTER SELECTION CONTROLLER REWORKED - PATHS CORREGIDOS ====
extends Control

# Referencias UI principales - CORREGIDAS para coincidir con ChapterSelectionUI.tscn
@onready var background = $Background
@onready var main_container = $MainContainer

# Left Panel - Chapter List - PATHS CORREGIDOS
@onready var chapters_panel = $MainContainer/ContentArea/LeftPanel
@onready var chapters_title = $MainContainer/ContentArea/LeftPanel/HeaderLeft/ChaptersTitle
@onready var progress_indicator = $MainContainer/ContentArea/LeftPanel/HeaderLeft/ProgressIndicator
@onready var chapters_scroll = $MainContainer/ContentArea/LeftPanel/ScrollContainer
@onready var chapters_list = $MainContainer/ContentArea/LeftPanel/ScrollContainer/ChaptersList

# Right Panel - Stage Details - PATHS CORREGIDOS
@onready var stages_panel = $MainContainer/ContentArea/RightPanel
@onready var chapter_detail_title = $MainContainer/ContentArea/RightPanel/HeaderRight/ChapterDetailTitle
@onready var chapter_description = $MainContainer/ContentArea/RightPanel/HeaderRight/ChapterDescription
@onready var stages_scroll = $MainContainer/ContentArea/RightPanel/StagesContainer/StagesScrollContainer
@onready var stages_list = $MainContainer/ContentArea/RightPanel/StagesContainer/StagesScrollContainer/StagesList

# Bottom Panel - PATHS CORREGIDOS
@onready var back_button = $MainContainer/BottomPanel/BackButton
@onready var team_power_label = $MainContainer/BottomPanel/PlayerStatusContainer/TeamPowerLabel
@onready var energy_label = $MainContainer/BottomPanel/PlayerStatusContainer/EnergyLabel

# Sistemas
var chapter_system # Puede ser ChapterSystem o EnhancedChapterSystem
var game_manager: GameManager
var main_controller: Control

# Estado
var selected_chapter: ChapterData
var current_mode: String = "chapters"  # "chapters" | "stages"

# Señales
signal back_pressed()
signal stage_selected(chapter_id: int, stage_id: int)

func _ready():
	print("ChapterSelectionController: Inicializando...")
	await _initialize_systems()
	_setup_connections()
	_populate_chapters()
	_update_bottom_panel()
	print("ChapterSelectionController: Listo!")

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
		chapter_system = main_controller.get_chapter_system()  # Será EnhancedChapterSystem
	else:
		game_manager = get_tree().get_first_node_in_group("game_manager")
		chapter_system = get_tree().get_first_node_in_group("chapter_system")  # Puede ser cualquiera
	
	print("✓ Chapter Selection systems initialized")

func _setup_connections():
	if back_button:
		back_button.pressed.connect(_on_back_pressed)
	
	if chapter_system:
		if chapter_system.has_signal("chapter_completed"):
			chapter_system.chapter_completed.connect(_on_chapter_completed)
		if chapter_system.has_signal("stage_completed"):
			chapter_system.stage_completed.connect(_on_stage_completed)

func _populate_chapters():
	"""Poblar la lista de capítulos"""
	if not chapters_list or not chapter_system:
		print("Error: chapters_list o chapter_system no disponible")
		return
	
	current_mode = "chapters"
	_clear_list(chapters_list)
	
	# Actualizar títulos
	if chapters_title:
		chapters_title.text = "📚 Adventure Chapters"
	
	# Crear cards de capítulos
	for i in range(chapter_system.chapters.size()):
		var chapter = chapter_system.chapters[i]
		var chapter_card = _create_chapter_card(chapter, i)
		chapters_list.add_child(chapter_card)
	
	# Actualizar progreso
	_update_progress_indicator()
	
	# Limpiar panel de stages
	_clear_stages_panel()

func _create_chapter_card(chapter_data: ChapterData, index: int) -> Control:
	"""Crear card de capítulo mejorada"""
	var card = Button.new()
	card.custom_minimum_size = Vector2(380, 100)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Verificar si está desbloqueado
	var is_unlocked = chapter_system.is_stage_unlocked(chapter_data.chapter_id, 1)
	var completed_stages = _get_completed_stages_count(chapter_data)
	var total_stages = chapter_data.max_stages
	
	# Container principal
	var main_hbox = HBoxContainer.new()
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_hbox.offset_left = 15
	main_hbox.offset_right = -15
	main_hbox.offset_top = 10
	main_hbox.offset_bottom = -10
	card.add_child(main_hbox)
	
	# Icono del capítulo
	var icon_container = VBoxContainer.new()
	icon_container.custom_minimum_size = Vector2(60, 0)
	main_hbox.add_child(icon_container)
	
	var chapter_icon = Label.new()
	chapter_icon.text = _get_chapter_icon(chapter_data.chapter_id)
	chapter_icon.add_theme_font_size_override("font_size", 32)
	chapter_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_container.add_child(chapter_icon)
	
	var chapter_number = Label.new()
	chapter_number.text = "Ch. " + str(chapter_data.chapter_id)
	chapter_number.add_theme_font_size_override("font_size", 12)
	chapter_number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter_number.modulate = Color(0.8, 0.8, 0.9, 1)
	icon_container.add_child(chapter_number)
	
	# Información del capítulo
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(info_container)
	
	var chapter_name = Label.new()
	chapter_name.text = chapter_data.chapter_name
	chapter_name.add_theme_font_size_override("font_size", 18)
	info_container.add_child(chapter_name)
	
	var description = Label.new()
	description.text = chapter_data.description
	description.add_theme_font_size_override("font_size", 12)
	description.modulate = Color(0.8, 0.8, 0.9, 1)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_container.add_child(description)
	
	var progress_label = Label.new()
	progress_label.text = "Progress: " + str(completed_stages) + "/" + str(total_stages) + " stages"
	progress_label.add_theme_font_size_override("font_size", 11)
	progress_label.modulate = _get_progress_color(completed_stages, total_stages)
	info_container.add_child(progress_label)
	
	# Status del capítulo
	var status_container = VBoxContainer.new()
	status_container.custom_minimum_size = Vector2(80, 0)
	main_hbox.add_child(status_container)
	
	if not is_unlocked:
		var lock_icon = Label.new()
		lock_icon.text = "🔒"
		lock_icon.add_theme_font_size_override("font_size", 24)
		lock_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_container.add_child(lock_icon)
		
		var locked_label = Label.new()
		locked_label.text = "LOCKED"
		locked_label.add_theme_font_size_override("font_size", 10)
		locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		locked_label.modulate = Color(0.6, 0.6, 0.6, 1)
		status_container.add_child(locked_label)
		
		card.disabled = true
		card.modulate = Color(0.6, 0.6, 0.6, 1)
	else:
		# Estrellas o estado
		if completed_stages == total_stages:
			var complete_icon = Label.new()
			complete_icon.text = "✅"
			complete_icon.add_theme_font_size_override("font_size", 24)
			complete_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			status_container.add_child(complete_icon)
			
			var complete_label = Label.new()
			complete_label.text = "COMPLETE"
			complete_label.add_theme_font_size_override("font_size", 10)
			complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			complete_label.modulate = Color(0.3, 1, 0.3, 1)
			status_container.add_child(complete_label)
			
			card.modulate = Color(1, 1, 0.8, 1)  # Dorado
		else:
			var power_req = _get_chapter_recommended_power(chapter_data.chapter_id)
			var power_label = Label.new()
			power_label.text = "Power: " + str(power_req) + "+"
			power_label.add_theme_font_size_override("font_size", 11)
			power_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			power_label.modulate = Color(1, 0.8, 0.4, 1)
			status_container.add_child(power_label)
		
		# Conectar señal
		card.pressed.connect(func(): _on_chapter_selected(chapter_data))
	
	return card

func _populate_stages(chapter_data: ChapterData):
	"""Poblar la lista de stages del capítulo seleccionado"""
	if not stages_list or not chapter_data:
		return
	
	current_mode = "stages"
	selected_chapter = chapter_data
	
	_clear_list(stages_list)
	
	# Actualizar títulos
	if chapter_detail_title:
		chapter_detail_title.text = "⚔️ " + chapter_data.chapter_name
	
	if chapter_description:
		chapter_description.text = chapter_data.description + "\n\nSelect a stage to begin your adventure!"
	
	# Botón para volver a capítulos
	var back_to_chapters = Button.new()
	back_to_chapters.text = "← Back to Chapters"
	back_to_chapters.custom_minimum_size = Vector2(200, 40)
	back_to_chapters.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_to_chapters.pressed.connect(_on_back_to_chapters)
	stages_list.add_child(back_to_chapters)
	
	var separator = HSeparator.new()
	stages_list.add_child(separator)
	
	# Crear cards de stages
	for i in range(chapter_data.stages.size()):
		var stage_data = chapter_data.stages[i]
		var stage_card = _create_stage_card(chapter_data.chapter_id, stage_data)
		stages_list.add_child(stage_card)

func _create_stage_card(chapter_id: int, stage_data) -> Control:
	"""Crear card de stage mejorada"""
	var card = Button.new()
	card.custom_minimum_size = Vector2(480, 80)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Verificar si está desbloqueado
	var stage_id = 1
	var is_unlocked = true
	var is_completed = false
	
	# Obtener datos del stage (manejar tanto objetos como diccionarios)
	if stage_data is StageData:
		stage_id = stage_data.stage_id
		is_unlocked = chapter_system.is_stage_unlocked(chapter_id, stage_id)
		is_completed = stage_data.completed
	elif stage_data is Dictionary:
		stage_id = stage_data.get("stage_id", 1)
		is_unlocked = chapter_system.is_stage_unlocked(chapter_id, stage_id)
		is_completed = stage_data.get("completed", false)
	
	# Container principal
	var main_hbox = HBoxContainer.new()
	main_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_hbox.offset_left = 15
	main_hbox.offset_right = -15
	main_hbox.offset_top = 10
	main_hbox.offset_bottom = -10
	card.add_child(main_hbox)
	
	# Número del stage
	var stage_number_container = VBoxContainer.new()
	stage_number_container.custom_minimum_size = Vector2(60, 0)
	main_hbox.add_child(stage_number_container)
	
	var stage_icon = Label.new()
	stage_icon.text = "⚔️"
	stage_icon.add_theme_font_size_override("font_size", 24)
	stage_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_number_container.add_child(stage_icon)
	
	var stage_num_label = Label.new()
	stage_num_label.text = str(stage_id)
	stage_num_label.add_theme_font_size_override("font_size", 16)
	stage_num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stage_number_container.add_child(stage_num_label)
	
	# Información del stage
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_child(info_container)
	
	var stage_name = Label.new()
	var enemy_count = 0
	var gold_reward = 0
	var exp_reward = 0
	
	if stage_data is StageData:
		stage_name.text = stage_data.stage_name
		enemy_count = stage_data.enemies.size()
		if stage_data.rewards:
			gold_reward = stage_data.rewards.gold
			exp_reward = stage_data.rewards.experience
	elif stage_data is Dictionary:
		stage_name.text = stage_data.get("stage_name", "Stage " + str(stage_id))
		enemy_count = stage_data.get("enemies", []).size()
		var rewards = stage_data.get("rewards", {})
		gold_reward = rewards.get("gold", 100)
		exp_reward = rewards.get("experience", 50)
	
	stage_name.add_theme_font_size_override("font_size", 16)
	info_container.add_child(stage_name)
	
	var enemies_label = Label.new()
	enemies_label.text = "👹 " + str(enemy_count) + " enemies | 💰 " + str(gold_reward) + " gold | ⭐ " + str(exp_reward) + " exp"
	enemies_label.add_theme_font_size_override("font_size", 12)
	enemies_label.modulate = Color(0.8, 0.8, 0.9, 1)
	info_container.add_child(enemies_label)
	
	var energy_label = Label.new()
	energy_label.text = "⚡ Energy: 5"
	energy_label.add_theme_font_size_override("font_size", 10)
	energy_label.modulate = Color(0.7, 0.8, 1, 1)
	info_container.add_child(energy_label)
	
	# Status del stage
	var status_container = VBoxContainer.new()
	status_container.custom_minimum_size = Vector2(80, 0)
	main_hbox.add_child(status_container)
	
	if not is_unlocked:
		var lock_icon = Label.new()
		lock_icon.text = "🔒"
		lock_icon.add_theme_font_size_override("font_size", 20)
		lock_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_container.add_child(lock_icon)
		
		card.disabled = true
		card.modulate = Color(0.6, 0.6, 0.6, 1)
	else:
		if is_completed:
			var complete_icon = Label.new()
			complete_icon.text = "✅"
			complete_icon.add_theme_font_size_override("font_size", 20)
			complete_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			status_container.add_child(complete_icon)
			
			card.modulate = Color(0.8, 1, 0.8, 1)
		else:
			var play_button = Button.new()
			play_button.text = "PLAY"
			play_button.custom_minimum_size = Vector2(60, 25)
			play_button.add_theme_font_size_override("font_size", 12)
			status_container.add_child(play_button)
		
		# Verificar equipo antes de empezar
		card.pressed.connect(func(): _on_stage_selected_with_verification(chapter_id, stage_id))
	
	return card

# ==== EVENT HANDLERS ====
func _on_chapter_selected(chapter_data: ChapterData):
	print("Chapter selected: ", chapter_data.chapter_name)
	_populate_stages(chapter_data)

func _on_back_to_chapters():
	print("Returning to chapters view")
	_populate_chapters()

func _on_stage_selected_with_verification(chapter_id: int, stage_id: int):
	"""Verificar equipo antes de empezar stage"""
	print("Stage selected: Chapter ", chapter_id, " Stage ", stage_id)
	
	# Verificar que hay equipo configurado
	if not game_manager or game_manager.player_team.is_empty():
		_show_team_required_message(chapter_id, stage_id)
		return
	
	# Verificar que el equipo tiene personajes vivos
	var alive_members = game_manager.player_team.filter(func(char): return char.is_alive())
	if alive_members.is_empty():
		_show_team_heal_message()
		return
	
	# Todo OK - emitir señal para empezar batalla
	stage_selected.emit(chapter_id, stage_id)

func _show_team_required_message(chapter_id: int, stage_id: int):
	"""Mostrar mensaje de equipo requerido"""
	var popup = AcceptDialog.new()
	popup.dialog_text = "You need to configure a team before starting this stage.\n\nGo to Team Formation first."
	popup.title = "Team Required"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

func _show_team_heal_message():
	"""Mostrar mensaje de curación requerida"""
	var popup = AcceptDialog.new()
	popup.dialog_text = "All team members are defeated!\nPlease heal them before entering battle."
	popup.title = "Team Defeated"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

func _on_chapter_completed(chapter_data: ChapterData):
	print("Chapter completed: ", chapter_data.chapter_name)
	if current_mode == "chapters":
		_populate_chapters()
	elif current_mode == "stages" and selected_chapter == chapter_data:
		_populate_stages(chapter_data)

func _on_stage_completed(stage_data, rewards):
	print("Stage completed!")
	if current_mode == "stages" and selected_chapter:
		_populate_stages(selected_chapter)

func _on_back_pressed():
	back_pressed.emit()

# ==== UTILIDADES ====
func _clear_list(list_container: Control):
	"""Limpiar una lista de elementos"""
	if not list_container:
		return
	for child in list_container.get_children():
		child.queue_free()

func _clear_stages_panel():
	"""Limpiar panel de stages"""
	if chapter_detail_title:
		chapter_detail_title.text = "📖 Chapter Details"
	if chapter_description:
		chapter_description.text = "Select a chapter to view its stages and embark on your adventure!"

func _get_chapter_icon(chapter_id: int) -> String:
	"""Obtener icono del capítulo"""
	match chapter_id:
		1: return "🌲"  # Forest
		2: return "🔥"  # Desert/Fire
		3: return "💎"  # Crystal Caves
		4: return "🏔️"  # Mountains
		5: return "🌙"  # Dark Realm
		_: return "⚔️"

func _get_completed_stages_count(chapter_data: ChapterData) -> int:
	"""Contar stages completados"""
	var count = 0
	for stage in chapter_data.stages:
		if stage is StageData and stage.completed:
			count += 1
		elif stage is Dictionary and stage.get("completed", false):
			count += 1
	return count

func _get_progress_color(completed: int, total: int) -> Color:
	"""Obtener color del progreso"""
	if completed == 0:
		return Color(0.7, 0.7, 0.8, 1)  # Gris
	elif completed == total:
		return Color(0.3, 1, 0.3, 1)    # Verde
	else:
		return Color(0.7, 0.9, 1, 1)    # Azul

func _get_chapter_recommended_power(chapter_id: int) -> int:
	"""Calcular poder recomendado"""
	return chapter_id * 300 + 200

func _update_progress_indicator():
	"""Actualizar indicador de progreso general"""
	if not progress_indicator or not chapter_system:
		return
	
	var total_chapters = chapter_system.chapters.size()
	var completed_chapters = 0
	
	for chapter in chapter_system.chapters:
		var completed_stages = _get_completed_stages_count(chapter)
		if completed_stages == chapter.max_stages:
			completed_chapters += 1
	
	progress_indicator.text = "Progress: " + str(completed_chapters) + "/" + str(total_chapters) + " chapters"

func _update_bottom_panel():
	"""Actualizar panel inferior con info del jugador"""
	if not game_manager:
		return
	
	if team_power_label:
		var team_power = 0
		for character in game_manager.player_team:
			team_power += character.max_hp + character.attack * 5 + character.defense * 3
		team_power_label.text = "Team Power: " + str(team_power)
	
	if energy_label:
		energy_label.text = "Energy: " + str(game_manager.energy) + "/" + str(game_manager.max_energy)

# ==== FUNCIONES PÚBLICAS ====
func refresh_display():
	"""Refrescar display desde otros sistemas"""
	if current_mode == "chapters":
		_populate_chapters()
	elif current_mode == "stages" and selected_chapter:
		_populate_stages(selected_chapter)
	_update_bottom_panel()
