# ==== EQUIPMENT MANAGER CORREGIDO (EquipmentManager.gd) ====
class_name EquipmentManager
extends Node

signal equipment_enhanced(equipment, result)
signal equipment_equipped(character, equipment)
signal set_bonus_activated(character, set_type, pieces)

var player_equipment: Array[Equipment] = []
var equipped_items: Dictionary = {}  # character_id -> equipment_slots

func _ready():
	_generate_starter_equipment()

func _generate_starter_equipment():
	# Generar equipment inicial
	for i in range(5):
		var equipment = Equipment.new()
		var types = [Equipment.EquipmentType.WEAPON, Equipment.EquipmentType.ARMOR, Equipment.EquipmentType.BOOTS, Equipment.EquipmentType.ACCESSORY]
		var type = types[randi() % types.size()]
		var rarity = Equipment.EquipmentRarity.COMMON if randf() < 0.7 else Equipment.EquipmentRarity.RARE
		
		equipment.setup("Starter " + Equipment.EquipmentType.keys()[type], type, rarity, 1)
		player_equipment.append(equipment)

func enhance_equipment(equipment: Equipment, levels: int = 1) -> Equipment.EnhanceResultData:
	var result = equipment.enhance(levels)
	
	if result.success:
		equipment_enhanced.emit(equipment, result)
	
	return result

func equip_item(character: Character, equipment: Equipment) -> bool:
	var character_id = character.get_instance_id()
	
	if character_id not in equipped_items:
		equipped_items[character_id] = {}
	
	var equipment_slots = equipped_items[character_id]
	var slot_name = Equipment.EquipmentType.keys()[equipment.equipment_type].to_lower()
	
	# Desequipar item anterior si existe
	if slot_name in equipment_slots:
		var old_equipment = equipment_slots[slot_name]
		_remove_equipment_stats(character, old_equipment)
	
	# Equipar nuevo item
	equipment_slots[slot_name] = equipment
	_apply_equipment_stats(character, equipment)
	
	# Verificar bonus de set
	_check_set_bonuses(character)
	
	equipment_equipped.emit(character, equipment)
	return true

func unequip_item(character: Character, equipment_type: Equipment.EquipmentType) -> bool:
	var character_id = character.get_instance_id()
	
	if character_id not in equipped_items:
		return false
	
	var equipment_slots = equipped_items[character_id]
	var slot_name = Equipment.EquipmentType.keys()[equipment_type].to_lower()
	
	if slot_name not in equipment_slots:
		return false
	
	var equipment = equipment_slots[slot_name]
	_remove_equipment_stats(character, equipment)
	equipment_slots.erase(slot_name)
	
	# Recalcular bonus de set
	_check_set_bonuses(character)
	
	return true

func _apply_equipment_stats(character: Character, equipment: Equipment):
	var stats = equipment.get_total_stats()
	
	for stat_type in stats:
		var value = stats[stat_type]
		_apply_stat_to_character(character, stat_type, value)

func _remove_equipment_stats(character: Character, equipment: Equipment):
	var stats = equipment.get_total_stats()
	
	for stat_type in stats:
		var value = stats[stat_type]
		_apply_stat_to_character(character, stat_type, -value)

func _apply_stat_to_character(character: Character, stat_type: Equipment.StatType, value: float):
	match stat_type:
		Equipment.StatType.HP:
			character.base_hp += int(value)
		Equipment.StatType.HP_PERCENT:
			character.base_hp = int(character.base_hp * (1.0 + value))
		Equipment.StatType.ATTACK:
			character.base_attack += int(value)
		Equipment.StatType.ATTACK_PERCENT:
			character.base_attack = int(character.base_attack * (1.0 + value))
		Equipment.StatType.DEFENSE:
			character.base_defense += int(value)
		Equipment.StatType.DEFENSE_PERCENT:
			character.base_defense = int(character.base_defense * (1.0 + value))
		Equipment.StatType.SPEED:
			character.base_speed += int(value)
		Equipment.StatType.CRIT_CHANCE:
			character.base_crit_chance += value
		Equipment.StatType.CRIT_DAMAGE:
			character.base_crit_damage += value
		Equipment.StatType.EFFECTIVENESS:
			character.base_effectiveness += value
		Equipment.StatType.EFFECT_RESISTANCE:
			character.base_effect_resistance += value
		Equipment.StatType.ELEMENTAL_MASTERY:
			character.base_elemental_mastery += value
	
	# Recalcular stats finales
	character._calculate_stats()

func _check_set_bonuses(character: Character):
	var character_id = character.get_instance_id()
	
	if character_id not in equipped_items:
		return
	
	var equipment_slots = equipped_items[character_id]
	var set_counts = {}
	
	# Contar pieces de cada set
	for slot in equipment_slots:
		var equipment = equipment_slots[slot]
		if equipment.artifact_set != Equipment.ArtifactSet.NONE:
			var set_type = equipment.artifact_set
			if set_type in set_counts:
				set_counts[set_type] += 1
			else:
				set_counts[set_type] = 1
	
	# Aplicar bonus de sets
	for set_type in set_counts:
		var pieces = set_counts[set_type]
		_apply_set_bonus(character, set_type, pieces)

func _apply_set_bonus(character: Character, set_type: Equipment.ArtifactSet, pieces: int):
	match set_type:
		Equipment.ArtifactSet.ATTACK_SET:
			if pieces >= 4:
				character.base_attack = int(character.base_attack * 1.15)
				set_bonus_activated.emit(character, set_type, pieces)
		
		Equipment.ArtifactSet.DEFENSE_SET:
			if pieces >= 2:
				character.base_defense = int(character.base_defense * 1.15)
				set_bonus_activated.emit(character, set_type, pieces)
		
		Equipment.ArtifactSet.HP_SET:
			if pieces >= 2:
				character.base_hp = int(character.base_hp * 1.15)
				set_bonus_activated.emit(character, set_type, pieces)
		
		Equipment.ArtifactSet.SPEED_SET:
			if pieces >= 4:
				character.base_speed += 25
				set_bonus_activated.emit(character, set_type, pieces)
		
		Equipment.ArtifactSet.CRIT_SET:
			if pieces >= 2:
				character.base_crit_chance += 0.12
				set_bonus_activated.emit(character, set_type, pieces)
		
		Equipment.ArtifactSet.CRIT_DMG_SET:
			if pieces >= 4:
				character.base_crit_damage += 0.40
				set_bonus_activated.emit(character, set_type, pieces)
	
	character._calculate_stats()

func get_character_equipment(character: Character) -> Dictionary:
	var character_id = character.get_instance_id()
	
	if character_id in equipped_items:
		return equipped_items[character_id]
	
	return {}

func generate_random_equipment(tier: int = 1, force_rarity: Equipment.EquipmentRarity = Equipment.EquipmentRarity.COMMON) -> Equipment:
	var equipment = Equipment.new()
	
	var types = [Equipment.EquipmentType.WEAPON, Equipment.EquipmentType.ARMOR, Equipment.EquipmentType.BOOTS, Equipment.EquipmentType.ACCESSORY, Equipment.EquipmentType.ARTIFACT]
	var type = types[randi() % types.size()]
	
	var rarity = force_rarity
	if force_rarity == Equipment.EquipmentRarity.COMMON:
		var rarity_roll = randf()
		if rarity_roll < 0.5:
			rarity = Equipment.EquipmentRarity.COMMON
		elif rarity_roll < 0.8:
			rarity = Equipment.EquipmentRarity.RARE
		elif rarity_roll < 0.95:
			rarity = Equipment.EquipmentRarity.EPIC
		else:
			rarity = Equipment.EquipmentRarity.LEGENDARY
	
	var sets = Equipment.ArtifactSet.values()
	var artifact_set = sets[randi() % sets.size()]
	
	var name = _generate_equipment_name(type, rarity, tier)
	equipment.setup(name, type, rarity, tier, artifact_set)
	
	return equipment

func _generate_equipment_name(type: Equipment.EquipmentType, rarity: Equipment.EquipmentRarity, tier: int) -> String:
	var rarity_names = ["Common", "Rare", "Epic", "Legendary"]
	var type_names = ["Sword", "Armor", "Boots", "Ring", "Artifact"]
	
	var rarity_name = rarity_names[rarity]
	var type_name = type_names[type]
	
	return rarity_name + " " + type_name + " T" + str(tier)
