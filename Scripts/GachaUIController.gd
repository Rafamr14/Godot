# ==== GACHA UI CONTROLLER (GachaUIController.gd) ====
extends Control

# Referencias UI
@onready var banner_display = $VBoxContainer/BannerDisplay
@onready var banner_navigation = $VBoxContainer/BannerNavigation
@onready var banner_info = $VBoxContainer/BannerInfo
@onready var pull_buttons = $VBoxContainer/PullButtons
@onready var currency_display = $VBoxContainer/CurrencyDisplay
@onready var back_button = $VBoxContainer/BackButton

# Sistemas
var enhanced_gacha_system: EnhancedGachaSystem
var game_manager: GameManager
var current_banner_index: int = 0

# Señales
signal back_pressed()
signal pull_results_ready(result: GachaPullResult)

func _ready():
	print("GachaUIController: Inicializando...")
	await _find_systems()
	_setup_ui()
	_setup_connections()
	_update_display()

func _find_systems():
	# Buscar sistemas en el árbol
	await get_tree().process_frame
	
	# Buscar EnhancedGachaSystem
	enhanced_gacha_system = get_node_or_null("../EnhancedGachaSystem")
	if not enhanced_gacha_system:
		enhanced_gacha_system = get_tree().get_first_node_in_group("gacha_system")
	
	# Buscar GameManager
	game_manager = get_node_or_null("../GameManager")
	if not game_manager:
		game_manager = get_tree().get_first_node_in_group("game_manager")

func _setup_ui():
	# Crear estructura si no existe
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
	banner_display = Control.new()
	banner_display.name = "BannerDisplay"
	banner_display.custom_minimum_size = Vector2(400, 200)
	$VBoxContainer.add_child(banner_display)
	$VBoxContainer.move_child(banner_display, 0)
	
	var banner_image = ColorRect.new()
	banner_image.name = "BannerImage"
	banner_image.color = Color.BLUE
	banner_image.size = Vector2(400, 150)
	banner_display.add_child(banner_image)
	
	var banner_title = Label.new()
	banner_title.name = "BannerTitle"
	banner_title.text = "Banner Title"
	banner_title.position = Vector2(10, 160)
	banner_title.add_theme_font_size_override("font_size", 20)
	banner_display.add_child(banner_title)

func _create_banner_navigation():
	banner_navigation = HBoxContainer.new()
	banner_navigation.name = "BannerNavigation"
	$VBoxContainer.add_child(banner_navigation)
	
	var prev_button = Button.new()
	prev_button.name = "PrevButton"
	prev_button.text = "◀ Previous"
	prev_button.custom_minimum_size = Vector2(100, 40)
	banner_navigation.add_child(prev_button)
	
	var banner_counter = Label.new()
	banner_counter.name = "BannerCounter"
	banner_counter.text = "1 / 3"
	banner_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_counter.custom_minimum_size = Vector2(100, 40)
	banner_navigation.add_child(banner_counter)
	
	var next_button = Button.new()
	next_button.name = "NextButton"
	next_button.text = "Next ▶"
	next_button.custom_minimum_size = Vector2(100, 40)
	banner_navigation.add_child(next_button)

func _create_banner_info():
	banner_info = VBoxContainer.new()
	banner_info.name = "BannerInfo"
	$VBoxContainer.add_child(banner_info)
	
	var description = Label.new()
	description.name = "Description"
	description.text = "Banner description"
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(400, 60)
	banner_info.add_child(description)
	
	var pity_info = Label.new()
	pity_info.name = "PityInfo"
	pity_info.text = "Pity: 0 / 90"
	banner_info.add_child(pity_info)
	
	var featured_info = Label.new()
	featured_info.name = "FeaturedInfo"
	featured_info.text = "Featured: None"
	banner_info.add_child(featured_info)

func _create_pull_buttons():
	pull_buttons = HBoxContainer.new()
	pull_buttons.name = "PullButtons"
	pull_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	$VBoxContainer.add_child(pull_buttons)
	
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
	currency_display = Label.new()
	currency_display.name = "CurrencyDisplay"
	currency_display.text = "Gold: 2000"
	currency_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	currency_display.add_theme_font_size_override("font_size", 18)
	$VBoxContainer.add_child(currency_display)

func _create_back_button():
	back_button = Button.new()
	back_button.name = "BackButton"
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(100, 40)
	$VBoxContainer.add_child(back_button)

func _setup_connections():
	# Navegación de banners
	if banner_navigation:
		var prev_btn = banner_navigation.get_node_or_null("PrevButton")
		var next_btn = banner_navigation.get_node_or_null("NextButton")
		
		if prev_btn:
			prev_btn.pressed.connect(_on_previous_banner)
		if next_btn:
			next_btn.pressed.connect(_on_next_banner)
	
	# Botones de tirada
	if pull_buttons:
		var single_btn = pull_buttons.get_node_or_null("SinglePullButton")
		var ten_btn = pull_buttons.get_node_or_null("TenPullButton")
		
		if single_btn:
			single_btn.pressed.connect(_on_single_pull)
		if ten_btn:
			ten_btn.pressed.connect(_on_ten_pull)
	
	# Botón de back
	if back_button:
		back_button.pressed.connect(func(): back_pressed.emit())
	
	# Conectar con sistema gacha
	if enhanced_gacha_system:
		enhanced_gacha_system.banner_changed.connect(_on_banner_changed)
		enhanced_gacha_system.pull_completed.connect(_on_pull_completed)

func _update_display():
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
			featured_info.text = "Featured: " + str(featured)
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
		single_btn.disabled = not enhanced_gacha_system.can_afford_single_pull()
	
	if ten_btn:
		var cost = banner_info_data.get("ten_cost", 900)
		ten_btn.text = "10x Pull\n(" + str(cost) + " Gold)"
		ten_btn.disabled = not enhanced_gacha_system.can_afford_ten_pull()

func _on_previous_banner():
	if not enhanced_gacha_system:
		return
	
	var available_banners = enhanced_gacha_system.get_available_banners()
	current_banner_index = (current_banner_index - 1) % available_banners.size()
	if current_banner_index < 0:
		current_banner_index = available_banners.size() - 1
	
	enhanced_gacha_system.set_current_banner_by_index(current_banner_index)

func _on_next_banner():
	if not enhanced_gacha_system:
		return
	
	var available_banners = enhanced_gacha_system.get_available_banners()
	current_banner_index = (current_banner_index + 1) % available_banners.size()
	enhanced_gacha_system.set_current_banner_by_index(current_banner_index)

func _on_single_pull():
	if not enhanced_gacha_system:
		return
	
	print("Performing single pull...")
	var result = enhanced_gacha_system.perform_single_pull()
	_show_pull_results(result)

func _on_ten_pull():
	if not enhanced_gacha_system:
		return
	
	print("Performing ten pull...")
	var result = enhanced_gacha_system.perform_ten_pull()
	_show_pull_results(result)

func _show_pull_results(result: GachaPullResult):
	print("Showing pull results...")
	pull_results_ready.emit(result)
	
	# Cargar escena de resultados
	var results_scene = load("res://scenes/GachaResultsUI.tscn")
	if results_scene:
		var results_ui = results_scene.instantiate()
		get_tree().current_scene.add_child(results_ui)
		
		# Configurar resultados
		if results_ui.has_method("show_results"):
			results_ui.show_results(result)
		
		# Ocultar gacha UI temporalmente
		visible = false
		
		# Conectar para volver
		if results_ui.has_signal("results_closed"):
			results_ui.results_closed.connect(_on_results_closed)
	else:
		print("Could not load GachaResultsUI.tscn")

func _on_results_closed():
	# Volver a mostrar gacha UI y actualizar displays
	visible = true
	_update_display()

func _on_banner_changed(banner: GachaBanner):
	print("Banner changed to: ", banner.banner_name)
	_update_display()

func _on_pull_completed(result: GachaPullResult):
	print("Pull completed! Got ", result.characters_obtained.size(), " characters")
	_update_display()

# Función pública para actualizar desde Main.gd
func refresh_display():
	_update_display()
