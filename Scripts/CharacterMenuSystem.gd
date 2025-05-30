class_name CharacterMenuSystem
extends Node

signal character_selected(character)
signal team_formation_changed(new_team)

var game_manager: GameManager
var selected_character: Character
var current_team: Array[Character] = []
var max_team_size: int = 4

func _ready():
	await get_tree().process_frame
	game_manager = get_parent().get_node("GameManager")

func get_characters_by_element(element: Character.Element) -> Array[Character]:
	return game_manager.player_inventory.filter(func(char): return char.element == element)

func get_characters_by_rarity(rarity: Character.Rarity) -> Array[Character]:
	return game_manager.player_inventory.filter(func(char): return char.rarity == rarity)

func sort_characters_by_level() -> Array[Character]:
	var sorted_chars = game_manager.player_inventory.duplicate()
	sorted_chars.sort_custom(func(a, b): return a.level > b.level)
	return sorted_chars

func sort_characters_by_power() -> Array[Character]:
	var sorted_chars = game_manager.player_inventory.duplicate()
	sorted_chars.sort_custom(func(a, b): return _calculate_power(a) > _calculate_power(b))
	return sorted_chars

func _calculate_power(character: Character) -> int:
	return character.max_hp + character.attack * 5 + character.defense * 3 + character.speed * 2

func set_team_formation(team: Array[Character]) -> bool:
	if team.size() > max_team_size:
		print("Team size cannot exceed " + str(max_team_size))
		return false
	
	current_team = team.duplicate()
	game_manager.player_team = current_team.duplicate()
	team_formation_changed.emit(current_team)
	return true

func add_to_team(character: Character) -> bool:
	if current_team.size() >= max_team_size:
		print("Team is full!")
		return false
	
	if character in current_team:
		print("Character already in team!")
		return false
	
	current_team.append(character)
	game_manager.player_team = current_team.duplicate()
	team_formation_changed.emit(current_team)
	return true

func remove_from_team(character: Character) -> bool:
	var index = current_team.find(character)
	if index == -1:
		print("Character not in team!")
		return false
	
	current_team.remove_at(index)
	game_manager.player_team = current_team.duplicate()
	team_formation_changed.emit(current_team)
	return true

func level_up_character(character: Character, levels: int = 1) -> bool:
	var cost = _calculate_level_up_cost(character, levels)
	
	if game_manager.game_currency < cost:
		print("Not enough currency to level up!")
		return false
	
	game_manager.game_currency -= cost
	character.level += levels
	character._calculate_stats()
	
	print(character.character_name + " leveled up to " + str(character.level))
	return true

func _calculate_level_up_cost(character: Character, levels: int) -> int:
	var base_cost = 100
	var current_level = character.level
	var total_cost = 0
	
	for i in range(levels):
		total_cost += base_cost * (current_level + i)
	
	return total_cost

func equip_item(character: Character, equipment: Equipment) -> bool:
	match equipment.equipment_type:
		Equipment.EquipmentType.WEAPON:
			character.weapon = equipment
		Equipment.EquipmentType.ARMOR:
			character.armor = equipment
		Equipment.EquipmentType.ACCESSORY:
			character.accessory = equipment
	
	character._calculate_stats()
	print(equipment.equipment_name + " equipped to " + character.character_name)
	return true

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

# ==== TEAM COMPOSITION ANALYZER ====
func analyze_team_composition(team: Array[Character]) -> Dictionary:
	var analysis = {
		"total_power": 0,
		"elements": {},
		"roles": {"dps": 0, "tank": 0, "support": 0},
		"synergies": [],
		"weaknesses": []
	}
	
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
