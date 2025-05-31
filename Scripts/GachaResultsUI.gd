# ==== GACHA RESULTS UI (GachaResultsUI.gd) ====
extends Control

# Referencias UI
@onready var background = $Background
@onready var results_container = $VBoxContainer
@onready var title_label = $VBoxContainer/TitleLabel
@onready var characters_grid = $VBoxContainer/ScrollContainer/CharactersGrid
@onready var summary_label = $VBoxContainer/SummaryLabel
@onready var continue_button = $VBoxContainer/ContinueButton

# Variables
var pull_result: GachaPullResult
var character_cards: Array[Control] = []
var animation_index: int = 0

# Señales
signal results_closed()

func _ready():
	_setup_ui()
	_setup_connections()

func _setup_ui():
	# Crear estructura si no existe
	if not background:
		_create_background()
	if not results_container:
		_create_results_container()

func _create_background():
	background = ColorRect.new()
	background.name = "Background"
	background.color = Color(0, 0, 0, 0.8)  # Fondo semi-transparente
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

func _create_results_container():
	results_container = VBoxContainer.new()
	results_container.name = "VBoxContainer"
	results_container.set_anchors_preset(Control.PRESET_CENTER)
	results_container.position = Vector2(200, 100)
	results_container.custom_minimum_size = Vector2(600, 500)
	add_child(results_container)
	
	# Título
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "Summon Results!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 28)
	results_container.add_child(title_label)
	
	# Scroll container para personajes
	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.custom_minimum_size = Vector2(600, 350)
	results_container.add_child(scroll)
	
	characters_grid = GridContainer.new()
	characters_grid.name = "CharactersGrid"
	characters_grid.columns = 5
	scroll.add_child(characters_grid)
	
	# Resumen
	summary_label = Label.new()
	summary_label.name = "SummaryLabel"
	summary_label.text = "Summary will appear here"
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.custom_minimum_size = Vector2(600, 60)
	results_container.add_child(summary_label)
	
	# Botón continuar
	continue_button = Button.new()
	continue_button.name = "ContinueButton"
	continue_button.text = "Continue"
	continue_button.custom_minimum_size = Vector2(200, 50)
	continue_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	results_container.add_child(continue_button)

func _setup_connections():
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)

func show_results(result: GachaPullResult):
	pull_result = result
	
	if not pull_result or pull_result.characters_obtained.is_empty():
		_show_empty_results()
		return
	
	_create_character_cards()
	_update_summary()
	_start_reveal_animation()

func _show_empty_results():
	title_label.text = "No Results"
	summary_label.text = "Something went wrong with the summon."

func _create_character_cards():
	# Limpiar grid existente
	for child in characters_grid.get_children():
		child.queue_free()
	
	character_cards.clear()
	
	# Crear card para cada personaje
	for character in pull_result.characters_obtained:
		var card = _create_character_card(character)
		characters_grid.add_child(card)
		character_cards.append(card)
		
		# Inicialmente oculto para animación
		card.modulate.a = 0.0

func _create_character_card(character: Character) -> Control:
	var card = Control.new()
	card.custom_minimum_size = Vector2(100, 120)
	
	# Background basado en rareza
	var bg = ColorRect.new()
	bg.size = Vector2(100, 120)
	bg.color = character.get_rarity_color()
	card.add_child(bg)
	
	# Marco decorativo
	var frame = ColorRect.new()
	frame.size = Vector2(96, 116)
	frame.position = Vector2(2, 2)
	frame.color = Color.BLACK
	card.add_child(frame)
	
	# Fondo interno
	var inner_bg = ColorRect.new()
	inner_bg.size = Vector2(92, 112)
	inner_bg.position = Vector2(4, 4)
	inner_bg.color = character.get_rarity_color() * 0.7
	card.add_child(inner_bg)
	
	# Nombre del personaje
	var name_label = Label.new()
	name_label.text = character.character_name
	name_label.position = Vector2(5, 5)
	name_label.size = Vector2(90, 40)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	card.add_child(name_label)
	
	# Nivel
	var level_label = Label.new()
	level_label.text = "Lv." + str(character.level)
	level_label.position = Vector2(5, 45)
	level_label.size = Vector2(90, 20)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 12)
	card.add_child(level_label)
	
	# Elemento
	var element_label = Label.new()
	element_label.text = character.get_element_name()
	element_label.position = Vector2(5, 65)
	element_label.size = Vector2(90, 20)
	element_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	element_label.modulate = character.get_element_color()
	element_label.add_theme_font_size_override("font_size", 10)
	card.add_child(element_label)
	
	# Rareza
	var rarity_label = Label.new()
	rarity_label.text = Character.Rarity.keys()[character.rarity]
	rarity_label.position = Vector2(5, 85)
	rarity_label.size = Vector2(90, 30)
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.add_theme_color_override("font_color", Color.WHITE)
	card.add_child(rarity_label)
	
	# Efecto especial para legendarios
	if character.rarity == Character.Rarity.LEGENDARY:
		_add_legendary_effect(card)
	elif character.rarity == Character.Rarity.EPIC:
		_add_epic_effect(card)
	
	return card

func _add_legendary_effect(card: Control):
	# Efecto dorado brillante para legendarios
	var glow = ColorRect.new()
	glow.size = Vector2(100, 120)
	glow.color = Color.GOLD
	glow.modulate.a = 0.3
	card.add_child(glow)
	card.move_child(glow, 1)  # Después del background
	
	# Animación de brillo
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(glow, "modulate:a", 0.6, 1.0)
	tween.tween_property(glow, "modulate:a", 0.3, 1.0)

func _add_epic_effect(card: Control):
	# Efecto púrpura para épicos
	var glow = ColorRect.new()
	glow.size = Vector2(100, 120)
	glow.color = Color.PURPLE
	glow.modulate.a = 0.2
	card.add_child(glow)
	card.move_child(glow, 1)

func _update_summary():
	if not pull_result:
		return
	
	var summary_text = "You summoned " + str(pull_result.characters_obtained.size()) + " heroes!\n"
	
	# Contar por rareza
	var rarity_counts = {}
	for character in pull_result.characters_obtained:
		var rarity_name = Character.Rarity.keys()[character.rarity]
		if rarity_name in rarity_counts:
			rarity_counts[rarity_name] += 1
		else:
			rarity_counts[rarity_name] = 1
	
	# Mostrar conteo
	var rarity_text = ""
	for rarity in rarity_counts:
		if rarity_text != "":
			rarity_text += " | "
		rarity_text += rarity + ": " + str(rarity_counts[rarity])
	
	summary_text += rarity_text
	
	# Destacar si hay legendarios
	if rarity_counts.has("LEGENDARY"):
		summary_text += "\n🌟 LEGENDARY HERO OBTAINED! 🌟"
	elif rarity_counts.has("EPIC"):
		summary_text += "\n⭐ Epic Hero Obtained! ⭐"
	
	summary_label.text = summary_text

func _start_reveal_animation():
	animation_index = 0
	_reveal_next_card()

func _reveal_next_card():
	if animation_index >= character_cards.size():
		# Animación completada
		continue_button.disabled = false
		return
	
	var card = character_cards[animation_index]
	var character = pull_result.characters_obtained[animation_index]
	
	# Animación de aparición
	var tween = create_tween()
	tween.parallel().tween_property(card, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(card, "scale", Vector2(1.1, 1.1), 0.15)
	tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.15)
	
	# Efecto especial para rarezas altas
	if character.rarity >= Character.Rarity.EPIC:
		_play_special_effect(card, character.rarity)
	
	animation_index += 1
	
	# Continuar con el siguiente después de un delay
	await get_tree().create_timer(0.2).timeout
	_reveal_next_card()

func _play_special_effect(card: Control, rarity: Character.Rarity):
	# Efecto de partículas simulado con múltiples ColorRects
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color.GOLD if rarity == Character.Rarity.LEGENDARY else Color.PURPLE
		
		var angle = i * PI / 4
		var start_pos = Vector2(50, 60) + Vector2(cos(angle), sin(angle)) * 20
		var end_pos = start_pos + Vector2(cos(angle), sin(angle)) * 30
		
		particle.position = start_pos
		card.add_child(particle)
		
		# Animación de partícula
		var tween = create_tween()
		tween.parallel().tween_property(particle, "position", end_pos, 0.5)
		tween.parallel().tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(particle.queue_free)

func _on_continue_pressed():
	results_closed.emit()
	queue_free()

# Función para cerrar con tecla Escape
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_continue_pressed()
