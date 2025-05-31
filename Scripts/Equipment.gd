# ==== EQUIPMENT SYSTEM CORREGIDO (Equipment.gd) ====
class_name Equipment
extends Resource

# ==== ENUMS GLOBALES ====
enum StatType {
	HP, HP_PERCENT,
	ATTACK, ATTACK_PERCENT,
	DEFENSE, DEFENSE_PERCENT,
	SPEED,
	CRIT_CHANCE, CRIT_DAMAGE,
	EFFECTIVENESS, EFFECT_RESISTANCE,
	ELEMENTAL_MASTERY
}

enum EquipmentType { WEAPON, ARMOR, BOOTS, ACCESSORY, ARTIFACT }
enum EquipmentRarity { COMMON, RARE, EPIC, LEGENDARY }
enum ArtifactSet { 
	NONE,
	ATTACK_SET,      # +15% ATK (4 pieces)
	DEFENSE_SET,     # +15% DEF (2 pieces)
	HP_SET,          # +15% HP (2 pieces)
	SPEED_SET,       # +25 Speed (4 pieces)
	CRIT_SET,        # +12% Crit Rate (2 pieces)
	CRIT_DMG_SET,    # +40% Crit DMG (4 pieces)
	EFFECTIVENESS_SET, # +20% Effectiveness (2 pieces)
	RESISTANCE_SET,  # +20% Effect Resistance (2 pieces)
	ELEMENTAL_SET,   # +15% Elemental Mastery (4 pieces)
	VAMPIRE_SET,     # Heal 20% damage dealt (4 pieces)
	COUNTER_SET,     # 15% chance to counter (4 pieces)
	IMMUNITY_SET     # Immunity to debuffs for 1 turn (2 pieces)
}

# ==== PROPIEDADES DEL EQUIPMENT ====
# Información básica
@export var equipment_name: String
@export var equipment_type: EquipmentType
@export var rarity: EquipmentRarity = EquipmentRarity.COMMON
@export var level: int = 0
@export var max_level: int = 15
@export var tier: int = 1  # T1-T8 como Epic Seven

# Set de artefacto
@export var artifact_set: ArtifactSet = ArtifactSet.NONE

# Stats principales
@export var main_stat: StatType = StatType.ATTACK
@export var main_stat_value: float = 0.0

# Substats (hasta 4 como Epic Seven) - CORREGIDO: Array genérico
@export var substats: Array = []  # Array de SubStatData
@export var max_substats: int = 4

# Costo de mejora
@export var upgrade_cost_base: int = 1000
@export var upgrade_materials: Dictionary = {}

# ==== MÉTODOS PRINCIPALES ====
func setup(name: String, type: EquipmentType, rar: EquipmentRarity, tier_level: int = 1, set: ArtifactSet = ArtifactSet.NONE):
	equipment_name = name
	equipment_type = type
	rarity = rar
	tier = tier_level
	artifact_set = set
	max_level = 15
	
	_generate_main_stat()
	_generate_substats()
	_calculate_main_stat_value()

func _generate_main_stat():
	# Determinar stat principal basado en tipo de equipo
	match equipment_type:
		EquipmentType.WEAPON:
			main_stat = StatType.ATTACK
		EquipmentType.ARMOR:
			main_stat = StatType.HP if randf() < 0.6 else StatType.DEFENSE
		EquipmentType.BOOTS:
			var boots_stats = [StatType.SPEED, StatType.HP, StatType.ATTACK, StatType.DEFENSE]
			main_stat = boots_stats[randi() % boots_stats.size()]
		EquipmentType.ACCESSORY:
			var acc_stats = [StatType.HP, StatType.ATTACK, StatType.DEFENSE, StatType.CRIT_DAMAGE, StatType.EFFECTIVENESS, StatType.EFFECT_RESISTANCE]
			main_stat = acc_stats[randi() % acc_stats.size()]
		EquipmentType.ARTIFACT:
			var art_stats = [StatType.HP, StatType.ATTACK, StatType.DEFENSE]
			main_stat = art_stats[randi() % art_stats.size()]

func _generate_substats():
	substats.clear()
	
	# Número de substats iniciales basado en rareza
	var initial_substats = _get_initial_substat_count()
	
	var available_stats = _get_available_substats()
	available_stats.shuffle()
	
	for i in range(initial_substats):
		if i < available_stats.size():
			var substat = SubStatData.new()
			substat.stat_type = available_stats[i]
			substat.base_value = _get_substat_value(available_stats[i])
			substat.current_value = substat.base_value
			substat.enhancement_count = 0
			substats.append(substat)

func _get_initial_substat_count() -> int:
	match rarity:
		EquipmentRarity.COMMON: return 2
		EquipmentRarity.RARE: return 2 + (1 if randf() < 0.4 else 0)
		EquipmentRarity.EPIC: return 3 + (1 if randf() < 0.7 else 0)
		EquipmentRarity.LEGENDARY: return 4
		_: return 2

func _get_available_substats() -> Array:  # CORREGIDO: Array genérico
	var all_stats = [
		StatType.HP, StatType.HP_PERCENT,
		StatType.ATTACK, StatType.ATTACK_PERCENT,
		StatType.DEFENSE, StatType.DEFENSE_PERCENT,
		StatType.SPEED,
		StatType.CRIT_CHANCE, StatType.CRIT_DAMAGE,
		StatType.EFFECTIVENESS, StatType.EFFECT_RESISTANCE,
		StatType.ELEMENTAL_MASTERY
	]
	
	# Remover stat principal de los disponibles
	return all_stats.filter(func(stat): return stat != main_stat)

func _get_substat_value(stat_type: StatType) -> float:
	var base_value = _get_substat_base_value(stat_type)
	var rarity_multiplier = _get_rarity_multiplier() * 0.7  # Substats son menores
	var roll_quality = randf_range(0.7, 1.0)  # 70-100% del valor máximo
	return base_value * rarity_multiplier * roll_quality

func _get_substat_base_value(stat_type: StatType) -> float:
	var tier_multiplier = tier * 0.2 + 0.8  # Menor multiplicador para substats
	
	match stat_type:
		StatType.HP: return 150 * tier_multiplier
		StatType.HP_PERCENT: return 0.08 * tier_multiplier
		StatType.ATTACK: return 25 * tier_multiplier
		StatType.ATTACK_PERCENT: return 0.08 * tier_multiplier
		StatType.DEFENSE: return 20 * tier_multiplier
		StatType.DEFENSE_PERCENT: return 0.08 * tier_multiplier
		StatType.SPEED: return 4 * tier_multiplier
		StatType.CRIT_CHANCE: return 0.05 * tier_multiplier
		StatType.CRIT_DAMAGE: return 0.07 * tier_multiplier
		StatType.EFFECTIVENESS: return 0.08 * tier_multiplier
		StatType.EFFECT_RESISTANCE: return 0.08 * tier_multiplier
		StatType.ELEMENTAL_MASTERY: return 20 * tier_multiplier
		_: return 1.0

func _calculate_main_stat_value():
	var base_value = _get_main_stat_base_value()
	var rarity_multiplier = _get_rarity_multiplier()
	var level_multiplier = 1.0 + (level * 0.08)  # +8% per level
	
	main_stat_value = base_value * rarity_multiplier * level_multiplier

func _get_main_stat_base_value() -> float:
	var tier_multiplier = tier * 0.3 + 0.7  # T1=1.0, T8=2.8
	
	match main_stat:
		StatType.HP: return 200 * tier_multiplier
		StatType.HP_PERCENT: return 0.60 * tier_multiplier
		StatType.ATTACK: return 50 * tier_multiplier
		StatType.ATTACK_PERCENT: return 0.60 * tier_multiplier
		StatType.DEFENSE: return 30 * tier_multiplier
		StatType.DEFENSE_PERCENT: return 0.60 * tier_multiplier
		StatType.SPEED: return 35 * tier_multiplier
		StatType.CRIT_CHANCE: return 0.55 * tier_multiplier
		StatType.CRIT_DAMAGE: return 0.70 * tier_multiplier
		StatType.EFFECTIVENESS: return 0.60 * tier_multiplier
		StatType.EFFECT_RESISTANCE: return 0.60 * tier_multiplier
		StatType.ELEMENTAL_MASTERY: return 60 * tier_multiplier
		_: return 1.0

func _get_rarity_multiplier() -> float:
	match rarity:
		EquipmentRarity.COMMON: return 1.0
		EquipmentRarity.RARE: return 1.3
		EquipmentRarity.EPIC: return 1.7
		EquipmentRarity.LEGENDARY: return 2.2
		_: return 1.0

func enhance(levels: int = 1) -> EnhanceResultData:
	var result = EnhanceResultData.new()
	
	for i in range(levels):
		if level >= max_level:
			result.success = false
			result.message = "Equipment already at max level"
			break
		
		var cost = _calculate_enhance_cost()
		level += 1
		result.total_cost += cost
		
		# Cada +3 niveles, mejorar un substat
		if level % 3 == 0:
			var enhanced_substat = _enhance_random_substat()
			if enhanced_substat:
				result.enhanced_substats.append(enhanced_substat)
	
	_calculate_main_stat_value()
	result.success = true
	result.new_level = level
	return result

func _calculate_enhance_cost() -> int:
	var base_cost = upgrade_cost_base * tier
	var level_multiplier = 1 + (level * 0.2)
	var rarity_multiplier = _get_rarity_multiplier()
	
	return int(base_cost * level_multiplier * rarity_multiplier)

func _enhance_random_substat() -> SubStatData:
	if substats.is_empty():
		return null
	
	# Si no tenemos el máximo de substats, agregar uno nuevo
	if substats.size() < max_substats:
		var available_stats = _get_available_substats()
		for stat in available_stats:
			var stat_exists = substats.any(func(s): return s.stat_type == stat)
			if not stat_exists:
				var new_substat = SubStatData.new()
				new_substat.stat_type = stat
				new_substat.base_value = _get_substat_value(stat)
				new_substat.current_value = new_substat.base_value
				new_substat.enhancement_count = 0
				substats.append(new_substat)
				return new_substat
	
	# Mejorar substat existente
	var random_substat = substats[randi() % substats.size()]
	var additional_value = _get_substat_value(random_substat.stat_type) * 0.8
	random_substat.current_value += additional_value
	random_substat.enhancement_count += 1
	return random_substat

func get_total_stats() -> Dictionary:
	var total_stats = {}
	
	# Stat principal
	total_stats[main_stat] = main_stat_value
	
	# Substats
	for substat in substats:
		if substat.stat_type in total_stats:
			total_stats[substat.stat_type] += substat.current_value
		else:
			total_stats[substat.stat_type] = substat.current_value
	
	return total_stats

func get_set_bonus_description() -> String:
	if artifact_set == ArtifactSet.NONE:
		return ""
	
	match artifact_set:
		ArtifactSet.ATTACK_SET: return "(4) Attack +15%"
		ArtifactSet.DEFENSE_SET: return "(2) Defense +15%"
		ArtifactSet.HP_SET: return "(2) HP +15%"
		ArtifactSet.SPEED_SET: return "(4) Speed +25"
		ArtifactSet.CRIT_SET: return "(2) Crit Rate +12%"
		ArtifactSet.CRIT_DMG_SET: return "(4) Crit DMG +40%"
		ArtifactSet.EFFECTIVENESS_SET: return "(2) Effectiveness +20%"
		ArtifactSet.RESISTANCE_SET: return "(2) Effect Resistance +20%"
		ArtifactSet.ELEMENTAL_SET: return "(4) Elemental Mastery +15%"
		ArtifactSet.VAMPIRE_SET: return "(4) Heal 20% of damage dealt"
		ArtifactSet.COUNTER_SET: return "(4) 15% chance to counter attack"
		ArtifactSet.IMMUNITY_SET: return "(2) Immunity to debuffs for 1 turn"
		_: return ""

func get_rarity_color() -> Color:
	match rarity:
		EquipmentRarity.COMMON: return Color.GRAY
		EquipmentRarity.RARE: return Color.BLUE
		EquipmentRarity.EPIC: return Color.PURPLE
		EquipmentRarity.LEGENDARY: return Color.GOLD
		_: return Color.WHITE

# ==== CLASES INTERNAS ====

# SUBSTAT DATA CLASS
class SubStatData:
	var stat_type: StatType
	var base_value: float
	var current_value: float
	var enhancement_count: int = 0
	
	func get_stat_name() -> String:
		match stat_type:
			StatType.HP: return "HP"
			StatType.HP_PERCENT: return "HP%"
			StatType.ATTACK: return "ATK"
			StatType.ATTACK_PERCENT: return "ATK%"
			StatType.DEFENSE: return "DEF"
			StatType.DEFENSE_PERCENT: return "DEF%"
			StatType.SPEED: return "Speed"
			StatType.CRIT_CHANCE: return "Crit Rate"
			StatType.CRIT_DAMAGE: return "Crit DMG"
			StatType.EFFECTIVENESS: return "Effectiveness"
			StatType.EFFECT_RESISTANCE: return "Effect Resist"
			StatType.ELEMENTAL_MASTERY: return "Elemental Mastery"
			_: return "Unknown"
	
	func get_display_value() -> String:
		match stat_type:
			StatType.HP, StatType.ATTACK, StatType.DEFENSE, StatType.SPEED:
				return "+" + str(int(current_value))
			StatType.ELEMENTAL_MASTERY:
				return "+" + str(int(current_value))
			_:
				return "+" + str(snapped(current_value * 100, 0.1)) + "%"

# ENHANCE RESULT DATA CLASS
class EnhanceResultData:
	var success: bool = false
	var new_level: int = 0
	var total_cost: int = 0
	var enhanced_substats: Array = []  # CORREGIDO: Array genérico
	var message: String = ""

# ==== FUNCIONES ESTÁTICAS PARA STATS ====
static func get_stat_type_name(stat_type: StatType) -> String:
	match stat_type:
		StatType.HP: return "HP"
		StatType.HP_PERCENT: return "HP%"
		StatType.ATTACK: return "ATK"
		StatType.ATTACK_PERCENT: return "ATK%"
		StatType.DEFENSE: return "DEF"
		StatType.DEFENSE_PERCENT: return "DEF%"
		StatType.SPEED: return "Speed"
		StatType.CRIT_CHANCE: return "Crit Rate"
		StatType.CRIT_DAMAGE: return "Crit DMG"
		StatType.EFFECTIVENESS: return "Effectiveness"
		StatType.EFFECT_RESISTANCE: return "Effect Resist"
		StatType.ELEMENTAL_MASTERY: return "Elemental Mastery"
		_: return "Unknown"

static func format_stat_value(stat_type: StatType, value: float) -> String:
	match stat_type:
		StatType.HP, StatType.ATTACK, StatType.DEFENSE, StatType.SPEED:
			return "+" + str(int(value))
		StatType.ELEMENTAL_MASTERY:
			return "+" + str(int(value))
		_:
			return "+" + str(snapped(value * 100, 0.1)) + "%"
