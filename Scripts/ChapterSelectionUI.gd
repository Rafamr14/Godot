# ==== CHAPTER SELECTION UI ARREGLADO ====
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
var selected_stage_id: int = 0
var current_mode: String = "chapters"  # "chapters" o "stages"

# Señales
signal chapter_selected(chapter_data: ChapterData)
signal stage_selected(chapter_id: int, stage_id: int)
signal back_pressed()

func _ready():
	print("ChapterSelectionUI: Inicializando sistema completo...")
	await _initialize_systems()
	await _ensure_characters_loaded()  # NUEVO: Cargar personajes siempre
	_create_ui_structure()
	_setup_connections()
	_populate_chapters()
	print("ChapterSelectionUI: Listo para usar!")

# ==== NUEVO: CARGAR PERSONAJES SIEMPRE ====
func _ensure_characters_loaded():
	"""Asegurar que los personajes estén cargados en el GameManager"""
	if not game_manager:
		return
	
	# Si el inventario está vacío, cargar desde Data/Characters
	if game_manager.player_inventory.is_empty():
		print("ChapterSelectionUI: Cargando personajes desde Data/Characters...")
		var characters = _load_characters_from_data()
		game_manager.player_inventory = characters
		print("ChapterSelectionUI: Cargados ", characters.size(), " personajes")

func _load_characters_from_data() -> Array[Character]:
	"""Cargar personajes desde Data/Characters"""
	var characters: Array[Character] = []
	var characters_path = "res://Data/Characters/"
	
	if not DirAccess.dir_exists_absolute(characters_path):
		print("Data/Characters no existe, creando personajes de ejemplo...")
		_create_example_characters()
		return game_manager.player_inventory if game_manager else []
	
	var dir = DirAccess.open(characters_path)
	if not dir:
		return characters
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(".tres") or file_name.ends_with(".res"):
			var full_path = characters_path + file_name
			var loaded_character = _load_character_file(full_path)
			
			if loaded_character:
				characters.append(loaded_character)
				print("✓ Cargado: ", loaded_character.character_name)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return characters

func _load_character_file(file_path: String) -> Character:
	"""Cargar un archivo de personaje específico"""
	var resource = load(file_path)
	
	if not resource:
		return null
	
	if resource is Character:
		return resource
	
	if resource is CharacterTemplate:
		var level = randi_range(1, 5)
		return resource.create_character_instance(level)
	
	return null

func _create_example_characters():
	"""Crear personajes de ejemplo si no hay ninguno"""
	if not game_manager:
		return
	
	var characters_path = "res://Data/Characters/"
	
	# Crear carpeta si no existe
	if not DirAccess.dir_exists_absolute(characters_path):
		var dir = DirAccess.open("res://")
		if dir:
			dir.make_dir_recursive("Data/Characters")
	
	var character_data = [
		{"name": "Forest Warrior", "element": Character.Element.EARTH, "rarity": Character.Rarity.COMMON, "hp": 120, "attack": 22, "defense": 18, "speed": 70},
		{"name": "Fire Mage", "element": Character.Element.FIRE, "rarity": Character.Rarity.RARE, "hp": 90, "attack": 35, "defense": 12, "speed": 85},
		{"name": "Water Healer", "element": Character.Element.WATER, "rarity": Character.Rarity.RARE, "hp": 110, "attack": 18, "defense": 20, "speed": 80},
		{"name": "Radiant Knight", "element": Character.Element.RADIANT, "rarity": Character.Rarity.EPIC, "hp": 150, "attack": 28, "defense": 25, "speed": 65}
	]
	
	for data in character_data:
		var character = Character.new()
		var level = randi_range(1, 3)
		
		character.setup(
			data.name,
			level,
			data.rarity,
			data.element,
			data.hp + (level - 1) * 8,
			data.attack + (level - 1) * 3,
			data.defense + (level - 1) * 2,
			data.speed + (level - 1) * 1,
			0.15,
			1.5
		)
		
		game_manager.player_inventory.append(character)
		
		# Guardar en archivo también
		var filename = data.name.to_snake_case() + "_lv" + str(level) + ".tres"
		ResourceSaver.save(character, characters_path + filename)

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
	var existing_vbox = get_node_or_null("VBoxContainer")
	if existing_vbox:
		_setup_existing_structure(existing_vbox)
		return
	
	var main_vbox = VBoxContainer.new()
	main_vbox.name = "VBoxContainer"
	main_vbox.position = Vector2(50, 50)
	main_vbox.size = Vector2(700, 500)
	add_child(main_vbox)
	
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Adventure - Select Chapter"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	main_vbox.add_child(title_label)
	
	var scroll_container = ScrollContainer.new()
	scroll_container.name = "ScrollContainer"
	scroll_container.custom_minimum_size = Vector2(650, 350)
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll_container)
	
	chapter_list = VBoxContainer.new()
	chapter_list.name = "ChapterList"
	scroll_container.add_child(chapter_list)
	
	chapter_info = Label.new()
	chapter_info.name = "ChapterInfo"
	chapter_info.text = "Select a chapter to view details"
	chapter_info.custom_minimum_size = Vector2(650, 80)
	chapter_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chapter_info.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	main_vbox.add_child(chapter_info)
	
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Back to Main Menu"
	back_button.custom_minimum_size = Vector2(200, 50)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_vbox.add_child(back_button)

func _setup_existing_structure(vbox: VBoxContainer):
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
	
	if title_label:
		title_label.text = "Adventure - Select Chapter"

# ==== POBLACIÓN DE CAPÍTULOS ====
func _populate_chapters():
	if not chapter_list or not chapter_system:
		print("Cannot populate chapters - missing components")
		return
	
	print("Populating chapters...")
	current_mode = "chapters"
	
	for child in chapter_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	for chapter in chapter_system.chapters:
		var chapter_card = _create_chapter_card(chapter)
		chapter_list.add_child(chapter_card)
	
	if title_label:
		title_label.text = "Adventure - Select Chapter"
	
	if chapter_info:
		chapter_info.text = "Select a chapter to view its stages"

func _create_chapter_card(chapter: ChapterData) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(620, 100)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var is_unlocked = chapter_system.is_stage_unlocked(chapter.chapter_id, 1)
	
	var card_text = chapter.chapter_name + "\n"
	card_text += chapter.description + "\n"
	
	var completed_stages = _get_completed_stages(chapter)
	card_text += "Progress: " + str(completed_stages) + "/" + str(chapter.max_stages) + " stages"
	
	if not is_unlocked:
		card_text += " (LOCKED)"
	
	card.text = card_text
	
	if is_unlocked:
		if completed_stages == chapter.max_stages:
			card.modulate = Color.GOLD
		elif completed_stages > 0:
			card.modulate = Color.CYAN
		else:
			card.modulate = Color.WHITE
		
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
	
	for child in chapter_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	var back_to_chapters_btn = Button.new()
	back_to_chapters_btn.text = "← Back to Chapters"
	back_to_chapters_btn.custom_minimum_size = Vector2(200, 40)
	back_to_chapters_btn.pressed.connect(_back_to_chapters)
	chapter_list.add_child(back_to_chapters_btn)
	
	var separator = HSeparator.new()
	chapter_list.add_child(separator)
	
	for stage in chapter.stages:
		var stage_card = _create_stage_card(chapter.chapter_id, stage)
		chapter_list.add_child(stage_card)
	
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
	
	var is_unlocked = chapter_system.is_stage_unlocked(chapter_id, stage.stage_id)
	
	var card_text = stage.stage_name + "\n"
	card_text += "Enemies: " + str(stage.enemies.size()) + " | "
	card_text += "Rewards: " + str(stage.rewards.gold) + " gold, " + str(stage.rewards.experience) + " exp"
	
	if stage.completed:
		card_text += " ✓ COMPLETED"
	elif not is_unlocked:
		card_text += " (LOCKED)"
	
	card.text = card_text
	
	if is_unlocked:
		if stage.completed:
			card.modulate = Color.GOLD
		else:
			card.modulate = Color.WHITE
		
		# MODIFICADO: Siempre verificar equipo antes de empezar stage
		card.pressed.connect(func(): _on_stage_selected_with_team_check(chapter_id, stage.stage_id))
	else:
		card.modulate = Color.GRAY
		card.disabled = true
	
	return card

# ==== NUEVO: VERIFICACIÓN DE EQUIPO ANTES DE STAGE ====
func _on_stage_selected_with_team_check(chapter_id: int, stage_id: int):
	"""Verificar equipo antes de empezar stage y redirigir a team formation si es necesario"""
	print("Stage selected: Chapter ", chapter_id, " Stage ", stage_id)
	
	# Guardar datos del stage seleccionado
	selected_stage_id = stage_id
	
	# Verificar si hay equipo configurado
	if not game_manager or game_manager.player_team.is_empty():
		print("No team configured, redirecting to team formation...")
		_show_team_formation_for_stage(chapter_id, stage_id)
	else:
		print("Team already configured, starting stage...")
		stage_selected.emit(chapter_id, stage_id)

func _show_team_formation_for_stage(chapter_id: int, stage_id: int):
	"""Mostrar team formation específicamente para un stage"""
	
	# Obtener el controlador principal
	if not main_controller:
		print("Error: No main controller found")
		return
	
	# Crear mensaje explicativo
	var popup = AcceptDialog.new()
	popup.dialog_text = "You need to configure a team before starting this stage.\n\nYou'll be taken to Team Formation first."
	popup.title = "Team Required"
	add_child(popup)
	popup.popup_centered()
	
	# Cuando confirme, ir a team formation
	popup.confirmed.connect(func(): 
		popup.queue_free()
		_navigate_to_team_formation_with_return(chapter_id, stage_id)
	)

func _navigate_to_team_formation_with_return(chapter_id: int, stage_id: int):
	"""Navegar a team formation y configurar return para volver al stage"""
	
	if main_controller and main_controller.has_method("_navigate_to_screen"):
		# Ocultar esta pantalla
		visible = false
		
		# Ir a team formation
		main_controller._navigate_to_screen("team_formation")
		
		# Esperar un momento y configurar el callback
		await get_tree().process_frame
		
		# Buscar la escena de team formation y configurar callback
		var team_formation_scene = get_tree().get_first_node_in_group("team_formation")
		if not team_formation_scene:
			# Buscar por nombre o script
			for child in get_tree().current_scene.get_children():
				if child.name.to_lower().contains("team") or child.name.to_lower().contains("formation"):
					team_formation_scene = child
					break
		
		if team_formation_scene:
			# Conectar señal de back para volver al stage
			if team_formation_scene.has_signal("back_pressed"):
				team_formation_scene.back_pressed.connect(func(): 
					_return_from_team_formation(chapter_id, stage_id), 
					CONNECT_ONE_SHOT
				)
			
			# También conectar team_updated para detectar cuando configuren equipo
			if team_formation_scene.has_signal("team_updated"):
				team_formation_scene.team_updated.connect(func(): 
					_check_team_and_return_to_stage(chapter_id, stage_id),
					CONNECT_ONE_SHOT
				)

func _return_from_team_formation(chapter_id: int, stage_id: int):
	"""Volver desde team formation y verificar si se configuró equipo"""
	print("Returning from team formation...")
	
	# Mostrar esta pantalla de nuevo
	visible = true
	
	# Verificar si ahora hay equipo configurado
	if game_manager and not game_manager.player_team.is_empty():
		print("Team now configured! Starting stage...")
		stage_selected.emit(chapter_id, stage_id)
	else:
		print("Still no team configured")
		var popup = AcceptDialog.new()
		popup.dialog_text = "You still need to configure a team to play this stage."
		popup.title = "Team Required"
		add_child(popup)
		popup.popup_centered()
		popup.confirmed.connect(func(): popup.queue_free())

func _check_team_and_return_to_stage(chapter_id: int, stage_id: int):
	"""Verificar si el equipo está configurado y volver al stage"""
	if game_manager and not game_manager.player_team.is_empty():
		# Esperar un poco para que la UI se actualice
		await get_tree().create_timer(0.5).timeout
		
		# Volver a chapters y empezar stage
		main_controller._navigate_to_screen("chapters")
		await get_tree().process_frame
		
		# Emitir señal de stage seleccionado
		stage_selected.emit(chapter_id, stage_id)

func _back_to_chapters():
	print("Returning to chapters view")
	_populate_chapters()

# ==== CONEXIONES ====
func _setup_connections():
	if back_button:
		if not back_button.pressed.is_connected(_on_back_pressed):
			back_button.pressed.connect(_on_back_pressed)
	
	if chapter_system:
		if chapter_system.has_signal("chapter_completed"):
			if not chapter_system.chapter_completed.is_connected(_on_chapter_completed):
				chapter_system.chapter_completed.connect(_on_chapter_completed)
		
		if chapter_system.has_signal("stage_completed"):
			if not chapter_system.stage_completed.is_connected(_on_stage_completed):
				chapter_system.stage_completed.connect(_on_stage_completed)

func _on_chapter_completed(chapter_data: ChapterData):
	print("Chapter completed: ", chapter_data.chapter_name)
	if current_mode == "chapters":
		_populate_chapters()
	elif current_mode == "stages" and selected_chapter == chapter_data:
		_show_stage_selection(chapter_data)

func _on_stage_completed(stage_data: StageData, rewards):
	print("Stage completed: ", stage_data.stage_name)
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
