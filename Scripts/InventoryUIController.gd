# ==== INVENTORY UI CONTROLLER SIN DUPLICACIÓN (InventoryUIController.gd) ====
extends Control

# Referencias UI
@onready var title_label = $VBoxContainer/TitleLabel
@onready var stats_label = $VBoxContainer/StatsLabel
@onready var scroll_container = $VBoxContainer/ScrollContainer
@onready var back_button = $VBoxContainer/BackButton

# Variables de control
var game_manager: GameManager
var is_populated: bool = false  # Bandera para evitar duplicación

# Señales
signal back_pressed()
signal character_selected(character: Character)

func _ready():
	print("InventoryUIController: Inicializando...")
	
	# IMPORTANTE: NO llenar automáticamente para evitar duplicación
	# El Main.gd se encargará de llamar populate_inventory()
	
	# Solo configurar conexiones básicas
	if back_button:
		back_button.pressed.connect(func(): back_pressed.emit())
	
	# Buscar game manager
	await _find_game_manager()

func _find_game_manager():
	# Buscar game manager en el árbol
	var main_node = get_tree().get_first_node_in_group("main")
	if main_node and main_node.has_method("get") and main_node.game_manager:
		game_manager = main_node.game_manager
	else:
		# Buscar de manera alternativa
		game_manager = get_node_or_null("../GameManager")
		if not game_manager:
			game_manager = get_node_or_null("../../GameManager")
			if not game_manager:
				# Buscar en el árbol completo
				var nodes = get_tree().get_nodes_in_group("game_manager")
				if nodes.size() > 0:
					game_manager = nodes[0]

# Función pública para ser llamada desde Main.gd
func populate_inventory():
	if is_populated:
		print("Inventory already populated, skipping...")
		return
		
	print("Populating inventory from InventoryUIController...")
	
	if not game_manager:
		print("GameManager not found, cannot populate inventory")
		return
	
	_update_stats_display()
	_create_character_list()
	is_populated = true

func _update_stats_display():
	if not stats_label or not game_manager:
		return
	
	var total_power = 0
	for character in game_manager.player_inventory:
		total_power += _calculate_character_power(character)
	
	stats_label.text = "Total Heroes: " + str(game_manager.player_inventory.size()) + " | Total Power: " + str(total_power)

func _create_character_list():
	if not scroll_container:
		return
	
	# Limpiar todo el contenido del scroll container
	for child in scroll_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Crear nuevo contenedor
	var character_list = VBoxContainer.new()
	character_list.name = "CharacterList"
	scroll_container.add_child(character_list)
	
	# Ordenar personajes por poder
	var sorted_characters = game_manager.player_inventory.duplicate()
	sorted_characters.sort_custom(func(a, b): return _calculate_character_power(a) > _calculate_character_power(b))
	
	# Crear entradas para cada personaje
	for character in sorted_characters:
		var character_entry = _create_character_entry(character)
		character_list.add_child(character_entry)

func _create_character_entry(character: Character) -> Control:
	var entry = Button.new()
	entry.custom_minimum_size = Vector2(400, 80)
	entry.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Crear texto detallado
	var entry_text = character.character_name + " Lv." + str(character.level) + "\n"
	entry_text += character.get_element_name() + " | " + Character.Rarity.keys()[character.rarity] + " | Power: " + str(_calculate_character_power(character)) + "\n"
	entry_text += "HP: " + str(character.max_hp) + " | ATK: " + str(character.attack) + " | DEF: " + str(character.defense) + " | SPD: " + str(character.speed)
	
	entry.text = entry_text
	entry.modulate = character.get_rarity_color()
	
	# Indicador de equipo
	if game_manager and character in game_manager.player_team:
		entry.text += " ★"
	
	# Conexión para selección
	entry.pressed.connect(func(): _on_character_selected(character))
	
	return entry

func _on_character_selected(character: Character):
	print("Character selected: ", character.character_name)
	character_selected.emit(character)

func _calculate_character_power(character: Character) -> int:
	return character.max_hp + character.attack * 5 + character.defense * 3 + character.speed * 2

# Función para refrescar el inventario
func refresh_inventory():
	is_populated = false
	populate_inventory()
