# ==== GACHA UI CONTROLLER COMPLETO Y AUTO-SUFICIENTE ====
extends Control

# Referencias UI
@onready var banner_display = $VBoxContainer/BannerDisplay
@onready var banner_navigation = $VBoxContainer/BannerNavigation  
@onready var banner_info = $VBoxContainer/BannerInfo
@onready var pull_buttons = $VBoxContainer/PullButtons
@onready var currency_display = $VBoxContainer/CurrencyDisplay
@onready var back_button = $VBoxContainer/BackButton

# Sistemas (se buscan automáticamente)
var enhanced_gacha_system: EnhancedGachaSystem
var game_manager: GameManager
var main_controller: Control

# Estado interno
var current_banner_index: int = 0
var is_pulling: bool = false

# Señales
signal back_pressed()

func _ready():
	print("GachaUIController: Inicializando sistema completo...")
	await _initialize_systems()
	await _setup_ui_if_needed()
	_setup_connections()
	_update_all_displays()
	print("GachaUIController: Listo para usar!")

# ==== INICIALIZACIÓN DE SISTEMAS ====
func _initialize_systems():
	# Buscar sistemas en el árbol de nodos
	await get_tree().process_frame
	
	# Buscar Main controller
	main_controller = get_tree().get_first_node_in_group("main")
	if not main_controller:
		# Buscar por jerarquía
		var current = get_parent()
		while current and not main_controller:
			if current.has_method("get_game_manager"):
				main_controller = current
				break
			current = current.get_parent()
	
	# Obtener sistemas desde Main o buscar directamente
	if main_controller and main_controller.has_method("get_game_manager"):
		game_manager = main_controller.get_game_manager()
		enhanced_gacha_system = main_controller.get_gacha_system()
	else:
		# Buscar directamente en el árbol
		game_manager = get_tree().get_first_node_in_group("game_manager")
		if not game_manager:
			game_manager = _find_node_by_script("GameManager")
		
		enhanced_gacha_system = get_tree().get_first_node_in_group("gacha_system")
		if not enhanced_gacha_system:
			enhanced_gacha_system = _find_node_by_script("EnhancedGachaSystem")
	
	# Crear EnhancedGachaSystem si no existe
	if not enhanced_gacha_system:
		print("Creating EnhancedGachaSystem...")
		enhanced_gacha_system = EnhancedGachaSystem.new()
		enhanced_gacha_system.name = "EnhancedGachaSystem"
		get_tree().current_scene.add_child(enhanced_gacha_system)
	
	print("✓ Gacha systems initialized")

func _find_node_by_script(script_name: String) -> Node:
	var all_nodes = get_tree().get_nodes_in_group("all")
	for node in get_tree().current_scene.get_children():
		if node.get_script() and node.get_script().get_global_name() == script_name:
			return node
	return null

# ==== SETUP DE UI ====
func _setup_ui_if_needed():
	# Verificar y crear elementos de UI que puedan faltar
	if not banner_display:
		_create_banner_display()
	if not banner_navigation:
		_create_banner_navigation()
	if not banner_info:
		_create_banner_info()
	if not pull_buttons:
		_create_pull_buttons()
	if not currency_display:
		_create_currency_display()
	if not back_button:
		_create_back_button()

func _create_banner_display():
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		return
	
	banner_display = vbox.get_node_or_null("BannerDisplay")
	if banner_display:
		return  # Ya existe
	
	banner_display = Control.new()
	banner_display.name = "BannerDisplay"
	banner_display.custom_minimum_size = Vector2(400, 200)
	vbox.add_child(banner_display)
	vbox.move_child(banner_display, 1)  # Después del título
	
	# Imagen del banner
	var banner_image = vbox.get_node_or_null("BannerDisplay/BannerImage")
	if not banner_image:
		banner_image = ColorRect.new()
		banner_image.name = "BannerImage"
		banner_image.color = Color.BLUE
		banner_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		banner_image.offset_bottom = -50
		banner_display.add_child(banner_image)
	
	# Título del banner
	var banner_title = vbox.get_node_or_null("BannerDisplay/BannerTitle")
	if not banner_title:
		banner_title = Label.new()
		banner_title.name = "BannerTitle"
		banner_title.text = "Standard Banner"
		banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		banner_title.add_theme_font_size_override("font_size", 20)
		banner_title.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		banner_title.offset_top = -40
		banner_display.add_child(banner_title)

func _create_banner_navigation():
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		return
	
	banner_navigation = vbox.get_node_or_null("BannerNavigation")
	if banner_navigation:
		return
	
	banner_navigation = HBoxContainer.new()
	banner_navigation.name = "BannerNavigation"
	banner_navigation.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(banner_navigation)
	
	var prev_button = Button.new()
	prev_button.name = "PrevButton"
	prev_button.text = "◀ Previous"
	prev_button.custom_minimum_size = Vector2(100, 40)
	banner_navigation.add_child(prev_button)
	
	var counter = Label.new()
	counter.name = "BannerCounter"
	counter.text = "1 / 3"
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter.custom_minimum_size = Vector2(100, 40)
	banner_navigation.add_child(counter)
	
	var next_button = Button.new()
	next_button.name = "NextButton"
	next_button.text = "Next ▶"
	next_button.custom_minimum_size = Vector2(100, 40)
	banner_navigation.add_child(next_button)

func _create_banner_info():
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		return
	
	banner_info = vbox.get_node_or_null("BannerInfo")
	if banner_info:
		return
	
	banner_info = VBoxContainer.new()
	banner_info.name = "BannerInfo"
	vbox.add_child(banner_info)
	
	var description = Label.new()
	description.name = "Description"
	description.text = "Standard banner with all available heroes"
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(0, 60)
	banner_info.add_child(description)
	
	var pity_info = Label.new()
	pity_info.name = "PityInfo"
	pity_info.text = "Pity: 0 / 90"
	pity_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_info.add_child(pity_info)
	
	var featured_info = Label.new()
	featured_info.name = "FeaturedInfo"
	featured_info.text = "Featured: None"
	featured_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_info.add_child(featured_info)

func _create_pull_buttons():
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		return
	
	pull_buttons = vbox.get_node_or_null("PullButtons")
	if pull_buttons:
		return
	
	pull_buttons = HBoxContainer.new()
	pull_buttons.name = "PullButtons"
	pull_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(pull_buttons)
	
	var single_button = Button.new()
	single_button.name = "SinglePullButton"
	single_button.text = "Single Pull\n(100 Gold)"
	single_button.custom_minimum_size = Vector2(150, 60)
	pull_buttons.add_child(single_button)
	
	var ten_button = Button.new()
	ten_button.name = "TenPullButton"
	ten_button.text = "10x Pull\n(900 Gold)"
	ten_button.custom_minimum_size = Vector2(150, 60)
	pull_buttons.add_child(ten_button)

func _create_currency_display():
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		return
	
	currency_display = vbox.get_node_or_null("CurrencyDisplay")
	if currency_display:
		return
	
	currency_display = Label.new()
	currency_display.name = "CurrencyDisplay"
	currency_display.text = "Gold: 2000"
	currency_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	currency_display.add_theme_font_size_override("font_size", 18)
	vbox.add_child(currency_display)

func _create_back_button():
	var vbox = get_node_or_null("VBoxContainer")
	if not vbox:
		return
	
	back_button = vbox.get_node_or_null("BackButton")
	if back_button:
		return
	
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(100, 40)
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(back_button)

# ==== CONEXIONES ====
func _setup_connections():
	# Navegación de banners
	if banner_navigation:
		var prev_btn = banner_navigation.get_node_or_null("PrevButton")
		var next_btn = banner_navigation.get_node_or_null("NextButton")
		
		if prev_btn:
			if not prev_btn.pressed.is_connected(_on_previous_banner):
				prev_btn.pressed.connect(_on_previous_banner)
		if next_btn:
			if not next_btn.pressed.is_connected(_on_next_banner):
				next_btn.pressed.connect(_on_next_banner)
	
	# Botones de tirada
	if pull_buttons:
		var single_btn = pull_buttons.get_node_or_null("SinglePullButton")
		var ten_btn = pull_buttons.get_node_or_null("TenPullButton")
		
		if single_btn:
			if not single_btn.pressed.is_connected(_on_single_pull):
				single_btn.pressed.connect(_on_single_pull)
		if ten_btn:
			if not ten_btn.pressed.is_connected(_on_ten_pull):
				ten_btn.pressed.connect(_on_ten_pull)
	
	# Botón de back
	if back_button:
		if not back_button.pressed.is_connected(_on_back_pressed):
			back_button.pressed.connect(_on_back_pressed)
	
	# Conectar con sistema gacha
	if enhanced_gacha_system:
		if enhanced_gacha_system.has_signal("banner_changed"):
			if not enhanced_gacha_system.banner_changed.is_connected(_on_banner_changed):
				enhanced_gacha_system.banner_changed.connect(_on_banner_changed)
		if enhanced_gacha_system.has_signal("pull_completed"):
			if not enhanced_gacha_system.pull_completed.is_connected(_on_pull_completed):
				enhanced_gacha_system.pull_completed.connect(_on_pull_completed)

# ==== LÓGICA DE GACHA ====
func _on_previous_banner():
	if not enhanced_gacha_system:
		return
	
	var available_banners = enhanced_gacha_system.get_available_banners()
	if available_banners.is_empty():
		return
		
	current_banner_index = (current_banner_index - 1) % available_banners.size()
	if current_banner_index < 0:
		current_banner_index = available_banners.size() - 1
	
	enhanced_gacha_system.set_current_banner_by_index(current_banner_index)

func _on_next_banner():
	if not enhanced_gacha_system:
		return
	
	var available_banners = enhanced_gacha_system.get_available_banners()
	if available_banners.is_empty():
		return
		
	current_banner_index = (current_banner_index + 1) % available_banners.size()
	enhanced_gacha_system.set_current_banner_by_index(current_banner_index)

func _on_single_pull():
	if is_pulling or not enhanced_gacha_system:
		return
	
	if not enhanced_gacha_system.can_afford_single_pull():
		_show_insufficient_currency_message()
		return
	
	is_pulling = true
	_update_pull_buttons()
	
	print("Performing single pull...")
	var result = enhanced_gacha_system.perform_single_pull()
	_show_pull_results(result)

func _on_ten_pull():
	if is_pulling or not enhanced_gacha_system:
		return
	
	if not enhanced_gacha_system.can_afford_ten_pull():
		_show_insufficient_currency_message()
		return
	
	is_pulling = true
	_update_pull_buttons()
	
	print("Performing ten pull...")
	var result = enhanced_gacha_system.perform_ten_pull()
	_show_pull_results(result)

func _show_pull_results(result: GachaPullResult):
	if not result or result.characters_obtained.is_empty():
		print("No results to show")
		is_pulling = false
		_update_pull_buttons()
		return
	
	print("Showing results for ", result.characters_obtained.size(), " characters")
	
	# Crear o cargar escena de resultados
	var results_scene_path = "res://scenes/GachaResultsUI.tscn"
	var results_scene = load(results_scene_path)
	
	if results_scene:
		var results_ui = results_scene.instantiate()
		get_tree().current_scene.add_child(results_ui)
		
		# Mostrar resultados
		if results_ui.has_method("show_results"):
			results_ui.show_results(result)
		
		# Ocultar gacha UI temporalmente
		visible = false
		
		# Conectar para volver
		if results_ui.has_signal("results_closed"):
			results_ui.results_closed.connect(_on_results_closed)
	else:
		# Fallback: mostrar mensaje simple
		_show_simple_results(result)

func _show_simple_results(result: GachaPullResult):
	var message = "You got:\n"
	for character in result.characters_obtained:
		message += "• " + character.character_name + " (" + Character.Rarity.keys()[character.rarity] + ")\n"
	
	var popup = AcceptDialog.new()
	popup.dialog_text = message
	popup.title = "Summon Results!"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): 
		popup.queue_free()
		_on_results_closed()
	)

func _on_results_closed():
	# Volver a mostrar gacha UI y actualizar displays
	visible = true
	is_pulling = false
	_update_all_displays()

func _show_insufficient_currency_message():
	var popup = AcceptDialog.new()
	popup.dialog_text = "Insufficient gold for this summon!"
	popup.title = "Not Enough Currency"
	add_child(popup)
	popup.popup_centered()
	popup.confirmed.connect(func(): popup.queue_free())

# ==== ACTUALIZACIONES DE UI ====
func _update_all_displays():
	_update_banner_display()
	_update_currency_display()
	_update_pull_buttons()

func _update_banner_display():
	if not enhanced_gacha_system:
		return
	
	var current_banner = enhanced_gacha_system.get_current_banner()
	if not current_banner:
		return
	
	# Actualizar imagen y título del banner
	if banner_display:
		var banner_title = banner_display.get_node_or_null("BannerTitle")
		if banner_title:
			banner_title.text = current_banner.banner_name
		
		var banner_image = banner_display.get_node_or_null("BannerImage")
		if banner_image:
			# Cambiar color según tipo de banner
			if current_banner.is_limited:
				banner_image.color = Color.GOLD
			elif current_banner.featured_characters.size() > 0:
				banner_image.color = Color.PURPLE
			else:
				banner_image.color = Color.BLUE
	
	# Actualizar navegación
	if banner_navigation:
		var counter = banner_navigation.get_node_or_null("BannerCounter")
		if counter:
			var total_banners = enhanced_gacha_system.get_available_banners().size()
			counter.text = str(current_banner_index + 1) + " / " + str(total_banners)
	
	# Actualizar información del banner
	_update_banner_info()

func _update_banner_info():
	if not enhanced_gacha_system or not banner_info:
		return
	
	var banner_info_data = enhanced_gacha_system.get_banner_info()
	if banner_info_data.is_empty():
		return
	
	# Actualizar descripción
	var description = banner_info.get_node_or_null("Description")
	if description:
		description.text = banner_info_data.get("description", "No description")
	
	# Actualizar información de pity
	var pity_info = banner_info.get_node_or_null("PityInfo")
	if pity_info:
		var pity_text = "Pity: " + str(banner_info_data.get("pity", 0)) + " / " + str(banner_info_data.get("pity_threshold", 90))
		if banner_info_data.get("is_limited", false):
			pity_text += "\nLegendary Pity: " + str(banner_info_data.get("legendary_pity", 0)) + " / 180"
		pity_info.text = pity_text
	
	# Actualizar personajes destacados
	var featured_info = banner_info.get_node_or_null("FeaturedInfo")
	if featured_info:
		var featured = banner_info_data.get("featured_characters", [])
		if featured.size() > 0:
			featured_info.text = "Featured: " + str(featured[0])  # Mostrar solo el primero
		else:
			featured_info.text = "Featured: None"

func _update_currency_display():
	if not game_manager or not currency_display:
		return
	
	currency_display.text = "Gold: " + str(game_manager.game_currency)

func _update_pull_buttons():
	if not enhanced_gacha_system or not pull_buttons:
		return
	
	var single_btn = pull_buttons.get_node_or_null("SinglePullButton")
	var ten_btn = pull_buttons.get_node_or_null("TenPullButton")
	
	var banner_info_data = enhanced_gacha_system.get_banner_info()
	
	if single_btn:
		var cost = banner_info_data.get("single_cost", 100)
		single_btn.text = "Single Pull\n(" + str(cost) + " Gold)"
		single_btn.disabled = is_pulling or not enhanced_gacha_system.can_afford_single_pull()
	
	if ten_btn:
		var cost = banner_info_data.get("ten_cost", 900)
		ten_btn.text = "10x Pull\n(" + str(cost) + " Gold)"
		ten_btn.disabled = is_pulling or not enhanced_gacha_system.can_afford_ten_pull()

# ==== EVENT HANDLERS ====
func _on_banner_changed(banner: GachaBanner):
	print("Banner changed to: ", banner.banner_name)
	_update_all_displays()

func _on_pull_completed(result: GachaPullResult):
	print("Pull completed! Got ", result.characters_obtained.size(), " characters")
	is_pulling = false
	_update_all_displays()

func _on_back_pressed():
	back_pressed.emit()

# ==== FUNCIONES PÚBLICAS ====
func refresh_display():
	"""Función pública para refrescar desde otros sistemas"""
	_update_all_displays()

func set_banner_index(index: int):
	"""Función pública para cambiar banner desde fuera"""
	if enhanced_gacha_system:
		current_banner_index = index
		enhanced_gacha_system.set_current_banner_by_index(index)
