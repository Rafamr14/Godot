# ==== CHAPTER SELECTION UI COMPLETO Y AUTO-SUFICIENTE ====
extends Control

# Sistemas (se buscan automáticamente)
var chapter_system: ChapterSystem
var game_manager: GameManager
var main_controller: Control

# Referencias UI (se crean dinámicamente)
var chapter_list: Control
var chapter_info: Label
var back_button: Button
var title_label: Label

# Estado interno
var selected_chapter: ChapterData
var current_mode: String = "chapters"  # "chapters" o "stages"

# Señales
signal chapter_selected(chapter_data: ChapterData)
signal stage_selected(chapter_id: int, stage_id: int)
signal back_pressed()

func _ready():
	print("ChapterSelectionUI: Inicializando sistema completo...")
	await _initialize_systems()
	_create_ui_structure()
	_setup_connections()
	_populate_chapters()
	print("ChapterSelectionUI: Listo para usar!")

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
		chapter_system = main_controller.get_chapter_system()
	else:
		# Buscar directamente en el árbol
		game_manager = get_tree().get_first_node_in_group("game_manager")
		if not game_manager:
			game_manager = _find_node_by_script("GameManager")
		
		chapter_system = get_tree().get_first_node_in_group("chapter_system")
		if not chapter_system:
			chapter_system = _find_node_by_script("ChapterSystem")
	
	# Crear ChapterSystem si no existe
	if not chapter_system:
		print("Creating ChapterSystem...")
		chapter_system = ChapterSystem.new()
		chapter_system.name = "ChapterSystem"
		get_tree().current_scene.add_child(chapter_system)
	
	print("✓ Chapter systems initialized")

func _find_node_by_script(script_name: String) -> Node:
	for node in get_tree().current_scene.get_children():
		if node.get_script() and node.get_script().get_global_name() == script_name:
			return node
	return null

# ==== CREACIÓN DE UI ====
func _create_ui_structure():
	# Verificar si ya existe la estructura básica
	var existing_vbox = get_node_or_null("VBoxContainer")
	if existing_vbox:
		_setup_existing_structure(existing_vbox)
		return
	
	# Crear estructura desde cero
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "VBoxContainer"
	main_vbox.position = Vector2(50, 50)
	main_vbox.size = Vector2(700, 500)
	add_child(main_vbox)
	
	# Título
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Adventure - Select Chapter"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	main_vbox.add_child(title_label)
	
	# Scroll container para la lista
	var scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.custom_minimum_size = Vector2(650, 350)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll_container)
	
	chapter_list = VBoxContainer.new()
	chapter_list.name = "ChapterList"
	scroll_container.add_child(chapter_list)
	
	# Información del capítulo/stage
	chapter_info = Label.new()
	chapter_info.name = "ChapterInfo"
	chapter_info.text = "Select a chapter to view details"
	chapter_info.custom_minimum_size = Vector2(650, 80)
	chapter_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chapter_info.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	main_vbox.add_child(chapter_info)
	
	# Botón de back
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Back to Main Menu"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(back_button)

func _setup_existing_structure(vbox: VBoxContainer):
	# Usar estructura existente de la escena
	title_label = vbox.get_node_or_null("TitleLabel")
	chapter_info = vbox.get_node_or_null("ChapterInfo")
	back_button = vbox.get_node_or_null("BackButton")
	
	var scroll_container = vbox.get_node_or_null("ScrollContainer")
	if scroll_container:
		chapter_list = scroll_container.get_node_or_null("ChapterList")
		if not chapter_list:
			chapter_list = VBoxContainer.new()
			chapter_list.name = "ChapterList"
			scroll_container.add_child(chapter_list)
	
	# Actualizar título si existe
	if title_label:
		title_label.text = "Adventure - Select Chapter"

# ==== POBLACIÓN DE CAPÍTULOS ====
func _populate_chapters():
	if not chapter_list or not chapter_system:
		print("Cannot populate chapters - missing components")
		return
	
	print("Populating chapters...")
	current_mode = "chapters"
	
	# Limpiar lista existente
	for child in chapter_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Agregar cards de capítulos
	for chapter in chapter_system.chapters:
		var chapter_card = _create_chapter_card(chapter)
		chapter_list.add_child(chapter_card)
	
	# Actualizar título
	if title_label:
		title_label.text = "Adventure - Select Chapter"
	
	# Actualizar info
	if chapter_info:
		chapter_info.text = "Select a chapter to view its stages"

func _create_chapter_card(chapter: ChapterData) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(620, 100)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Verificar si está desbloqueado
	var is_unlocked = chapter_system.is_stage_unlocked(chapter.chapter_id, 1)
	
	# Crear texto del capítulo
	var card_text = chapter.chapter_name + "\n"
	card_text += chapter.description + "\n"
	
	# Calcular progreso
	var completed_stages = _get_completed_stages(chapter)
	card_text += "Progress: " + str(completed_stages) + "/" + str(chapter.max_stages) + " stages"
	
	if not is_unlocked:
		card_text += " (LOCKED)"
	
	card.text = card_text
	
	# Configurar apariencia
	if is_unlocked:
		if completed_stages == chapter.max_stages:
			card.modulate = Color.GOLD  # Completado
		elif completed_stages > 0:
			card.modulate = Color.CYAN  # En progreso
		else:
			card.modulate = Color.WHITE  # Disponible
		
		# Conectar señal
		card.pressed.connect(func(): _on_chapter_selected(chapter))
	else:
		card.modulate = Color.GRAY
		card.disabled = true
	
	return card

func _get_completed_stages(chapter: ChapterData) -> int:
	var completed = 0
	for stage in chapter.stages:
		if stage.completed:
			completed += 1
	return completed

# ==== SELECCIÓN DE CAPÍTULOS Y STAGES ====
func _on_chapter_selected(chapter: ChapterData):
	print("Chapter selected: ", chapter.chapter_name)
	selected_chapter = chapter
	chapter_selected.emit(chapter)
	_show_stage_selection(chapter)

func _show_stage_selection(chapter: ChapterData):
	print("Showing stages for chapter: ", chapter.chapter_name)
	current_mode = "stages"
	
	# Limpiar lista y mostrar stages
	for child in chapter_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Agregar botón de back a capítulos
	var back_to_chapters_btn = Button.new()
	back_to_chapters_btn.text = "← Back to Chapters"
	back_to_chapters_btn.custom_minimum_size = Vector2(200, 40)
	back_to_chapters_btn.pressed.connect(_back_to_chapters)
	chapter_list.add_child(back_to_chapters_btn)
	
	# Agregar separador
	var separator = HSeparator.new()
	chapter_list.add_child(separator)
	
	# Agregar cards de stages
	for stage in chapter.stages:
		var stage_card = _create_stage_card(chapter.chapter_id, stage)
		chapter_list.add_child(stage_card)
	
	# Actualizar título e info
	if title_label:
		title_label.text = "Adventure - " + chapter.chapter_name
	
	if chapter_info:
		var info_text = chapter.description + "\n"
		info_text += "Chapter Progress: " + str(_get_completed_stages(chapter)) + "/" + str(chapter.max_stages) + " completed"
		chapter_info.text = info_text

func _create_stage_card(chapter_id: int, stage: StageData) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(600, 80)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Verificar si está desbloqueado
	var is_unlocked = chapter_system.is_stage_unlocked(chapter_id, stage.stage_id)
	
	# Crear texto del stage
	var card_text = stage.stage_name + "\n"
	card_text += "Enemies: " + str(stage.enemies.size()) + " | "
	card_text += "Rewards: " + str(stage.rewards.gold) + " gold, " + str(stage.rewards.experience) + " exp"
	
	if stage.completed:
		card_text += " ✓ COMPLETED"
	elif not is_unlocked:
		card_text += " (LOCKED)"
	
	card.text = card_text
	
	# Configurar apariencia
	if is_unlocked:
		if stage.completed:
			card.modulate = Color.GOLD
		else:
			card.modulate = Color.WHITE
		
		# Conectar señal
		card.pressed.connect(func(): _on_stage_selected(chapter_id, stage.stage_id))
	else:
		card.modulate = Color.GRAY
		card.disabled = true
	
	return card

func _on_stage_selected(chapter_id: int, stage_id: int):
	print("Stage selected: Chapter ", chapter_id, " Stage ", stage_id)
	stage_selected.emit(chapter_id, stage_id)

func _back_to_chapters():
	print("Returning to chapters view")
	_populate_chapters()

# ==== CONEXIONES ====
func _setup_connections():
	if back_button:
		if not back_button.pressed.is_connected(_on_back_pressed):
			back_button.pressed.connect(_on_back_pressed)
	
	# Conectar con chapter_system si tiene señales
	if chapter_system:
		if chapter_system.has_signal("chapter_completed"):
			if not chapter_system.chapter_completed.is_connected(_on_chapter_completed):
				chapter_system.chapter_completed.connect(_on_chapter_completed)
		
		if chapter_system.has_signal("stage_completed"):
			if not chapter_system.stage_completed.is_connected(_on_stage_completed):
				chapter_system.stage_completed.connect(_on_stage_completed)

func _on_chapter_completed(chapter_data: ChapterData):
	print("Chapter completed: ", chapter_data.chapter_name)
	# Refrescar display
	if current_mode == "chapters":
		_populate_chapters()
	elif current_mode == "stages" and selected_chapter == chapter_data:
		_show_stage_selection(chapter_data)

func _on_stage_completed(stage_data: StageData, rewards):
	print("Stage completed: ", stage_data.stage_name)
	# Refrescar display
	if current_mode == "stages" and selected_chapter:
		_show_stage_selection(selected_chapter)

func _on_back_pressed():
	back_pressed.emit()

# ==== FUNCIONES PÚBLICAS ====
func refresh_display():
	"""Función pública para refrescar desde otros sistemas"""
	if current_mode == "chapters":
		_populate_chapters()
	elif current_mode == "stages" and selected_chapter:
		_show_stage_selection(selected_chapter)

func show_chapter(chapter_id: int):
	"""Función pública para mostrar un capítulo específico"""
	if chapter_system:
		var chapter_data = chapter_system.get_chapter_data(chapter_id)
		if chapter_data:
			_on_chapter_selected(chapter_data)
