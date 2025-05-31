class_name CharacterMenuSystem
extends Node

signal character_selected(character)
signal team_formation_changed(new_team)

var game_manager: GameManager
var selected_character: Character
var current_team: Array[Character] = []
var max_team_size: int = 4

func _ready():
	# Esperar múltiples frames para asegurar inicialización
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	_find_game_manager()

func _find_game_manager():
	# Buscar GameManager de múltiples maneras
	game_manager = get_parent().get_node_or_null("GameManager")
	
	if not game_manager:
		# Buscar en el árbol principal
		game_manager = get_tree().get_first_node_in_group("game_manager")
	
	if not game_manager:
		# Buscar por script
		for node in get_tree().current_scene.get_children():
			if node.get_script() and node.get_script().get_global_name() == "GameManager":
				game_manager = node
				break
	
	if not game_manager:
		# Buscar recursivamente en todo el árbol
		game_manager = _find_node_recursive(get_tree().current_scene, "GameManager")
	
	if game_manager:
		print("CharacterMenuSystem: GameManager encontrado")
		# Sincronizar equipos si ya existe data
		_sync_with_game_manager()
	else:
		print("CharacterMenuSystem: GameManager no encontrado, trabajando en modo local")

func _find_node_recursive(node: Node, target_name: String) -> Node:
	if node.name == target_name or (node.get_script() and node.get_script().get_global_name() == target_name):
		return node
	
	for child in node.get_children():
		var result = _find_node_recursive(child, target_name)
		if result:
			return result
	
	return null

func _sync_with_game_manager():
	"""Sincronizar estado con GameManager si ya tiene datos"""
	if not game_manager:
		return
	
	# Si GameManager ya tiene un equipo, usarlo
	if not game_manager.player_team.is_empty():
		current_team = game_manager.player_team.duplicate()
		print("CharacterMenuSystem: Sincronizado con equipo existente de ", current_team.size(), " personajes")

# ==== FUNCIONES DE FILTRADO Y ORDENAMIENTO ====
func get_characters_by_element(element: Character.Element) -> Array[Character]:
	if not game_manager:
		print("Warning: GameManager no disponible para filtrar por elemento")
		return []
	return game_manager.player_inventory.filter(func(char): return char.element == element)

func get_characters_by_rarity(rarity: Character.Rarity) -> Array[Character]:
	if not game_manager:
		print("Warning: GameManager no disponible para filtrar por rareza")
		return []
	return game_manager.player_inventory.filter(func(char): return char.rarity == rarity)

func sort_characters_by_level() -> Array[Character]:
	if not game_manager:
		print("Warning: GameManager no disponible para ordenar por nivel")
		return []
	var sorted_chars = game_manager.player_inventory.duplicate()
	sorted_chars.sort_custom(func(a, b): return a.level > b.level)
	return sorted_chars

func sort_characters_by_power() -> Array[Character]:
	if not game_manager:
		print("Warning: GameManager no disponible para ordenar por poder")
		return []
	var sorted_chars = game_manager.player_inventory.duplicate()
	sorted_chars.sort_custom(func(a, b): return _calculate_power(a) > _calculate_power(b))
	return sorted_chars

func _calculate_power(character: Character) -> int:
	return character.max_hp + character.attack * 5 + character.defense * 3 + character.speed * 2

# ==== FUNCIONES DE FORMACIÓN DE EQUIPOS ====
func set_team_formation(team: Array[Character]) -> bool:
	if team.size() > max_team_size:
		print("Error: Team size cannot exceed ", max_team_size)
		return false
	
	current_team = team.duplicate()
	
	# Sincronizar con GameManager si está disponible
	if game_manager:
		game_manager.player_team = current_team.duplicate()
		print("CharacterMenuSystem: Equipo sincronizado con GameManager")
	else:
		print("CharacterMenuSystem: Equipo guardado localmente (GameManager no disponible)")
	
	team_formation_changed.emit(current_team)
	return true

func add_to_team(character: Character) -> bool:
	if current_team.size() >= max_team_size:
		print("Team is full! (", current_team.size(), "/", max_team_size, ")")
		return false
	
	if character in current_team:
		print("Character already in team!")
		return false
	
	current_team.append(character)
	
	# Sincronizar con GameManager si está disponible
	if game_manager:
		game_manager.player_team = current_team.duplicate()
	
	team_formation_changed.emit(current_team)
	print("Added ", character.character_name, " to team (", current_team.size(), "/", max_team_size, ")")
	return true

func remove_from_team(character: Character) -> bool:
	var index = current_team.find(character)
	if index == -1:
		print("Character not in team!")
		return false
	
	current_team.remove_at(index)
	
	# Sincronizar con GameManager si está disponible
	if game_manager:
		game_manager.player_team = current_team.duplicate()
	
	team_formation_changed.emit(current_team)
	print("Removed ", character.character_name, " from team (", current_team.size(), "/", max_team_size, ")")
	return true

func clear_team():
	"""Limpiar todo el equipo"""
	current_team.clear()
	
	if game_manager:
		game_manager.player_team.clear()
	
	team_formation_changed.emit(current_team)
	print("Team cleared")

# ==== FUNCIONES DE LEVEL UP ====
func level_up_character(character: Character, levels: int = 1) -> bool:
	var cost = _calculate_level_up_cost(character, levels)
	
	if not game_manager:
		print("Warning: GameManager no disponible, no se puede verificar currency")
		return false
	
	if game_manager.game_currency < cost:
		print("Not enough currency to level up! Need: ", cost, " Have: ", game_manager.game_currency)
		return false
	
	game_manager.game_currency -= cost
	character.level += levels
	character._calculate_stats()
	
	print(character.character_name, " leveled up to ", character.level, " (Cost: ", cost, ")")
	return true

func _calculate_level_up_cost(character: Character, levels: int) -> int:
	var base_cost = 100
	var current_level = character.level
	var total_cost = 0
	
	for i in range(levels):
		total_cost += base_cost * (current_level + i)
	
	return total_cost

# ==== FUNCIONES DE EQUIPAMIENTO ====
func equip_item(character: Character, equipment: Equipment) -> bool:
	if not equipment:
		print("Error: Equipment is null")
		return false
	
	match equipment.equipment_type:
		Equipment.EquipmentType.WEAPON:
			character.weapon = equipment
		Equipment.EquipmentType.ARMOR:
			character.armor = equipment
		Equipment.EquipmentType.ACCESSORY:
			character.accessory = equipment
		Equipment.EquipmentType.BOOTS:
			character.boots = equipment
	
	character._calculate_stats()
	print(equipment.equipment_name, " equipped to ", character.character_name)
	return true

# ==== FUNCIONES DE INFORMACIÓN ====
func get_character_details(character: Character) -> Dictionary:
	return {
		"name": character.character_name,
		"level": character.level,
		"element": character.get_element_name(),
		"rarity": Character.Rarity.keys()[character.rarity],
		"power": _calculate_power(character),
		"hp": str(character.current_hp) + "/" + str(character.max_hp),
		"attack": character.attack,
		"defense": character.defense,
		"speed": character.speed,
		"crit_chance": str(int(character.crit_chance * 100)) + "%",
		"crit_damage": str(int(character.crit_damage * 100)) + "%",
		"effectiveness": str(int(character.effectiveness * 100)) + "%",
		"effect_resistance": str(int(character.effect_resistance * 100)) + "%",
		"elemental_mastery": character.elemental_mastery,
		"skills": character.skills.map(func(skill): return skill.skill_name),
		"buffs": character.buffs.map(func(buff): return buff.effect_name),
		"debuffs": character.debuffs.map(func(debuff): return debuff.effect_name)
	}

# ==== ANÁLISIS DE COMPOSICIÓN DE EQUIPO ====
func analyze_team_composition(team: Array[Character]) -> Dictionary:
	var analysis = {
		"total_power": 0,
		"elements": {},
		"roles": {"dps": 0, "tank": 0, "support": 0},
		"synergies": [],
		"weaknesses": []
	}
	
	if team.is_empty():
		return analysis
	
	for character in team:
		analysis.total_power += _calculate_power(character)
		
		# Count elements
		var element_name = character.get_element_name()
		if element_name in analysis.elements:
			analysis.elements[element_name] += 1
		else:
			analysis.elements[element_name] = 1
		
		# Determine role based on stats
		var role = _determine_character_role(character)
		analysis.roles[role] += 1
	
	# Analyze synergies and weaknesses
	_analyze_team_synergies(team, analysis)
	
	return analysis

func _determine_character_role(character: Character) -> String:
	var attack_ratio = float(character.attack) / float(character.max_hp)
	var defense_ratio = float(character.defense) / float(character.max_hp)
	
	if attack_ratio > 0.3:
		return "dps"
	elif defense_ratio > 0.2:
		return "tank"
	else:
		return "support"

func _analyze_team_synergies(team: Array[Character], analysis: Dictionary):
	# Check for elemental diversity
	if analysis.elements.size() >= 3:
		analysis.synergies.append("Elemental Diversity: +10% damage")
	
	# Check for same element bonus
	for element in analysis.elements:
		if analysis.elements[element] >= 2:
			analysis.synergies.append(element + " Resonance: +15% " + element.to_lower() + " damage")
	
	# Check for balanced roles
	if analysis.roles.dps >= 1 and analysis.roles.tank >= 1 and analysis.roles.support >= 1:
		analysis.synergies.append("Balanced Formation: +5% all stats")
	
	# Check for weaknesses
	if analysis.roles.tank == 0:
		analysis.weaknesses.append("No Tank: Team vulnerable to focused damage")
	
	if analysis.roles.support == 0:
		analysis.weaknesses.append("No Support: Limited healing and buffs")
	
	if team.size() < max_team_size:
		analysis.weaknesses.append("Incomplete Team: " + str(max_team_size - team.size()) + " empty slots")

# ==== FUNCIONES PÚBLICAS DE UTILIDAD ====
func get_available_characters() -> Array[Character]:
	"""Obtener personajes disponibles (no en equipo)"""
	if not game_manager:
		return []
	
	return game_manager.player_inventory.filter(func(char): return char not in current_team)

func get_team_power() -> int:
	"""Calcular poder total del equipo"""
	var total_power = 0
	for character in current_team:
		total_power += _calculate_power(character)
	return total_power

func is_character_in_team(character: Character) -> bool:
	"""Verificar si un personaje está en el equipo"""
	return character in current_team

func get_team_size() -> int:
	"""Obtener tamaño actual del equipo"""
	return current_team.size()

func get_max_team_size() -> int:
	"""Obtener tamaño máximo del equipo"""
	return max_team_size

func has_game_manager() -> bool:
	"""Verificar si GameManager está disponible"""
	return game_manager != null

# ==== FUNCIÓN PARA RECONECTAR GAME MANAGER ====
func reconnect_game_manager():
	"""Intentar reconectar con GameManager si se perdió la conexión"""
	if not game_manager:
		_find_game_manager()
