# ==== CHAPTER SELECTION UI REWORK (ChapterSelectionUI.gd) ====
extends Control

# Sistemas
var chapter_system: ChapterSystem
var game_manager: GameManager
var main_controller: Control

# Referencias UI
@onready var background = $Background
@onready var main_container = $MainContainer
@onready var chapters_panel = $MainContainer/ChaptersPanel
@onready var stages_panel = $MainContainer/StagesPanel
@onready var chapter_info_panel = $MainContainer/ChapterInfoPanel

# Estado
var selected_chapter: ChapterData
var selected_stage_id: int = 0
var viewing_mode: String = "chapters"  # "chapters" o "stages"

# Señales
signal chapter_selected(chapter_data: ChapterData)
signal stage_selected(chapter_id: int, stage_id: int)
signal back_pressed()

func _ready():
	print("ChapterSelectionUI: Inicializando sistema de capítulos...")
	await _initialize_systems()
	_create_ui_structure()
	_setup_connections()
	_show_chapters_view()
	print("ChapterSelectionUI: Sistema listo!")

func _initialize_systems():
	await get_tree().process_frame
	
	# Buscar sistemas
	main_controller = get_tree().get_first_node_in_group("main")
	if main_controller and main_controller.has_method("get_game_manager"):
		game_manager = main_controller.get_game_manager()
		chapter_system = main_controller.get_chapter_system()
	else:
		game_manager = get_tree().get_first_node_in_group("game_manager")
		chapter_system = get_tree().get_first_node_in_group("chapter_system")
	
	# Crear ChapterSystem si no existe
	if not chapter_system:
		print("Creando ChapterSystem...")
		chapter_system = ChapterSystem.new()
		chapter_system.name = "ChapterSystem"
		get_tree().current_scene.add_child(chapter_system)

func _create_ui_structure():
	# Ya existe la estructura básica en la escena .tscn
	# Solo configuramos referencias adicionales si es necesario
	pass

func _setup_connections():
	# Conectar señales del chapter system
	if chapter_system:
		if chapter_system.has_signal("chapter_completed"):
			chapter_system.chapter_completed.connect(_on_chapter_completed)
		if chapter_system.has_signal("stage_completed"):
			chapter_system.stage_completed.connect(_on_stage_completed)

# ==== VISTA DE CAPÍTULOS ====
func _show_chapters_view():
	viewing_mode = "chapters"
	
	# Mostrar panel de capítulos
	if chapters_panel:
		chapters_panel.visible = true
	if stages_panel:
		stages_panel.visible = false
	
	# Poblar lista de capítulos
	_populate_chapters()

func _populate_chapters():
	if not chapter_system:
		return
	
	# Limpiar contenedor
	var chapters_container = chapters_panel.get_node_or_null("ScrollContainer/ChaptersList")
	if not chapters_container:
		return
	
	for child in chapters_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Crear cards de capítulos
	for chapter in chapter_system.chapters:
		var chapter_card = _create_chapter_card(chapter)
		chapters_container.add_child(chapter_card)

func _create_chapter_card(chapter: ChapterData) -> Control:
	# Crear contenedor principal
	var card = Control.new()
	card.custom_minimum_size = Vector2(700, 140)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Background
	var bg = Button.new()
	bg.flat = true
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(bg)
	
	# Verificar si está desbloqueado
	var is_unlocked = chapter_system.is_stage_unlocked(chapter.chapter_id, 1)
	
	# Container para contenido
	var content = HBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 20)
	card.add_child(content)
	
	# Icono del capítulo
	var icon_container = Control.new()
	icon_container.custom_minimum_size = Vector2(120, 120)
	content.add_child(icon_container)
	
	var icon_bg = ColorRect.new()
	icon_bg.color = Color(0.2, 0.2, 0.3, 1) if is_unlocked else Color(0.1, 0.1, 0.1, 1)
	icon_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_container.add_child(icon_bg)
	
	var icon = Label.new()
	icon.add_theme_font_size_override("font_size", 64)
	icon.text = _get_chapter_icon(chapter.chapter_id)
	icon.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	icon_container.add_child(icon)
	
	# Info del capítulo
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(info_container)
	
	# Título
	var title = Label.new()
	title.add_theme_font_size_override("font_size", 24)
	title.text = chapter.chapter_name
	if not is_unlocked:
		title.modulate = Color(0.6, 0.6, 0.6, 1)
	info_container.add_child(title)
	
	# Descripción
	var desc = Label.new()
	desc.text = chapter.description
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.modulate = Color(0.8, 0.8, 0.9, 1)
	info_container.add_child(desc)
	
	# Progreso
	var progress_container = HBoxContainer.new()
	info_container.add_child(progress_container)
	
	var completed_stages = _get_completed_stages(chapter)
	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(200, 20)
	progress_bar.max_value = chapter.max_stages
	progress_bar.value = completed_stages
	progress_container.add_child(progress_bar)
	
	var progress_label = Label.new()
	progress_label.text = " " + str(completed_stages) + "/" + str(chapter.max_stages) + " stages"
	progress_container.add_child(progress_label)
	
	# Panel derecho con estado
	var status_container = VBoxContainer.new()
	status_container.custom_minimum_size = Vector2(150, 0)
	content.add_child(status_container)
	
	if not is_unlocked:
		var lock_icon = Label.new()
		lock_icon.add_theme_font_size_override("font_size", 48)
		lock_icon.text = "🔒"
		lock_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status_container.add_child(lock_icon)
		
		bg.disabled = true
		card.modulate = Color(0.7, 0.7, 0.7, 1)
	else:
		# Botón de jugar
		var play_button = Button.new()
		play_button.text = "ENTER"
		play_button.custom_minimum_size = Vector2(120, 40)
		play_button.pressed.connect(func(): _on_chapter_selected(chapter))
		status_container.add_child(play_button)
		
		# Estrellas
		var stars_container = HBoxContainer.new()
		stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
		status_container.add_child(stars_container)
		
		var total_stars = _calculate_chapter_stars(chapter)
		var max_stars = chapter.max_stages * 3
		
		for i in range(3):
			var star = Label.new()
			star.add_theme_font_size_override("font_size", 24)
			if total_stars >= (max_stars / 3) * (i + 1):
				star.text = "⭐"
			else:
				star.text = "☆"
			stars_container.add_child(star)
		
		# Recompensas del capítulo
		if completed_stages == chapter.max_stages:
			var complete_label = Label.new()
			complete_label.text = "✅ COMPLETE"
			complete_label.modulate = Color.GREEN
			complete_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			status_container.add_child(complete_label)
	
	# Efecto hover si está desbloqueado
	if is_unlocked:
		bg.mouse_entered.connect(func(): 
			var tween = create_tween()
			tween.tween_property(card, "modulate", Color(1.1, 1.1, 1.1, 1), 0.1)
		)
		bg.mouse_exited.connect(func():
			var tween = create_tween()
			tween.tween_property(card, "modulate", Color.WHITE, 0.1)
		)
	
	return card

# ==== VISTA DE STAGES ====
func _on_chapter_selected(chapter: ChapterData):
	selected_chapter = chapter
	chapter_selected.emit(chapter)
	_show_stages_view(chapter)

func _show_stages_view(chapter: ChapterData):
	viewing_mode = "stages"
	
	# Cambiar paneles visibles
	if chapters_panel:
		chapters_panel.visible = false
	if stages_panel:
		stages_panel.visible = true
	
	# Actualizar info del capítulo
	_update_chapter_info(chapter)
	
	# Poblar stages
	_populate_stages(chapter)

func _populate_stages(chapter: ChapterData):
	var stages_container = stages_panel.get_node_or_null("ScrollContainer/StagesList")
	if not stages_container:
		return
	
	# Limpiar contenedor
	for child in stages_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Crear cards de stages
	for stage in chapter.stages:
		var stage_card = _create_stage_card(chapter.chapter_id, stage)
		stages_container.add_child(stage_card)

func _create_stage_card(chapter_id: int, stage: StageData) -> Control:
	var card = Control.new()
	card.custom_minimum_size = Vector2(650, 100)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Background button
	var bg = Button.new()
	bg.flat = true
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(bg)
	
	var is_unlocked = chapter_system.is_stage_unlocked(chapter_id, stage.stage_id)
	
	# Container principal
	var content = HBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.add_theme_constant_override("separation", 15)
	card.add_child(content)
	
	# Número del stage
	var stage_number = Control.new()
	stage_number.custom_minimum_size = Vector2(80, 80)
	content.add_child(stage_number)
	
	var number_bg = ColorRect.new()
	number_bg.color = Color(0.2, 0.2, 0.3, 1) if is_unlocked else Color(0.1, 0.1, 0.1, 1)
	number_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage_number.add_child(number_bg)
	
	var number_label = Label.new()
	number_label.add_theme_font_size_override("font_size", 32)
	number_label.text = str(stage.stage_id)
	number_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	stage_number.add_child(number_label)
	
	# Info del stage
	var info_container = VBoxContainer.new()
	info_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(info_container)
	
	# Nombre
	var name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.text = stage.stage_name
	if not is_unlocked:
		name_label.modulate = Color(0.6, 0.6, 0.6, 1)
	info_container.add_child(name_label)
	
	# Enemigos
	var enemies_label = Label.new()
	enemies_label.text = "Enemies: " + str(stage.enemies.size()) + " | "
	enemies_label.text += "Boss: " + ("Yes" if stage.stage_id % 5 == 0 else "No")
	enemies_label.modulate = Color(0.8, 0.8, 0.9, 1)
	info_container.add_child(enemies_label)
	
	# Recompensas
	var rewards_label = Label.new()
	rewards_label.text = "Rewards: " + str(stage.rewards.gold) + " gold, "
	rewards_label.text += str(stage.rewards.experience) + " exp"
	rewards_label.modulate = Color(1, 0.9, 0.5, 1)
	info_container.add_child(rewards_label)
	
	# Panel derecho
	var right_panel = VBoxContainer.new()
	right_panel.custom_minimum_size = Vector2(120, 0)
	content.add_child(right_panel)
	
	if not is_unlocked:
		var lock_label = Label.new()
		lock_label.text = "🔒 LOCKED"
		lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		right_panel.add_child(lock_label)
		bg.disabled = true
		card.modulate = Color(0.7, 0.7, 0.7, 1)
	else:
		# Botón de batalla
		var battle_button = Button.new()
		battle_button.text = "BATTLE"
		battle_button.custom_minimum_size = Vector2(100, 35)
		battle_button.modulate = Color(0.3, 1, 0.3, 1) if not stage.completed else Color.WHITE
		battle_button.pressed.connect(func(): _on_stage_selected(chapter_id, stage.stage_id))
		right_panel.add_child(battle_button)
		
		# Estrellas
		if stage.completed:
			var stars_container = HBoxContainer.new()
			stars_container.alignment = BoxContainer.ALIGNMENT_CENTER
			right_panel.add_child(stars_container)
			
			for i in range(3):
				var star = Label.new()
				star.add_theme_font_size_override("font_size", 20)
				star.text = "⭐" if i < stage.stars else "☆"
				stars_container.add_child(star)
	
	return card

func _on_stage_selected(chapter_id: int, stage_id: int):
	print("Stage selected: Chapter ", chapter_id, " Stage ", stage_id)
	
	# Verificar equipo antes de empezar
	if not game_manager or game_manager.player_team.is_empty():
		_show_team_required_message()
		return
	
	# Verificar que el equipo tiene personajes vivos
	var alive_members = game_manager.player_team.filter(func(char): return char.is_alive())
	if alive_members.is_empty():
		_show_message("All team members are defeated! Heal them first.")
		return
	
	# Emitir señal para iniciar batalla
	stage_selected.emit(chapter_id, stage_id)

# ==== FUNCIONES AUXILIARES ====
func _get_chapter_icon(chapter_id: int) -> String:
	match chapter_id:
		1: return "🌲"  # Forest
		2: return "🔥"  # Desert
		3: return "💎"  # Crystal Caves
		4: return "🏔️"  # Mountains
		5: return "🌙"  # Dark Realm
		_: return "⚔️"

func _get_completed_stages(chapter: ChapterData) -> int:
	var completed = 0
	for stage in chapter.stages:
		if stage.completed:
			completed += 1
	return completed

func _calculate_chapter_stars(chapter: ChapterData) -> int:
	var total_stars = 0
	for stage in chapter.stages:
		total_stars += stage.stars
	return total_stars

func _update_chapter_info(chapter: ChapterData):
	if not chapter_info_panel:
		return
	
	var title = chapter_info_panel.get_node_or_null("ChapterTitle")
	if title:
		title.text = chapter.chapter_name
	
	var desc = chapter_info_panel.get_node_or_null("ChapterDescription")
	if desc:
		desc.text = chapter.description
	
	var progress = chapter_info_panel.get_node_or_null("ChapterProgress")
	if progress:
		var completed = _get_completed_stages(chapter)
		progress.text = "Progress: " + str(completed) + "/" + str(chapter.max_stages) + " stages completed"

func _show_team_required_message():
	var popup = AcceptDialog.new()
	popup.dialog_text = "You need to configure a team before starting battles!"
	popup.title = "Team Required"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

func _show_message(text: String):
	var popup = AcceptDialog.new()
	popup.dialog_text = text
	popup.title = "Notice"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

# ==== NAVEGACIÓN ====
func _on_back_button_pressed():
	if viewing_mode == "stages":
		_show_chapters_view()
	else:
		back_pressed.emit()

func _on_chapter_completed(chapter_data: ChapterData):
	if viewing_mode == "chapters":
		_populate_chapters()

func _on_stage_completed(stage_data: StageData, rewards):
	if viewing_mode == "stages" and selected_chapter:
		_populate_stages(selected_chapter)
