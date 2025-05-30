class_name Character
extends Resource

enum Rarity { COMMON, RARE, EPIC, LEGENDARY }
enum CharacterType { PLAYER, ENEMY }
enum Element { WATER, FIRE, EARTH, RADIANT, VOID }

# Stats principales
@export var character_name: String
@export var level: int = 1
@export var rarity: Rarity = Rarity.COMMON
@export var element: Element = Element.WATER
@export var character_type: CharacterType = CharacterType.PLAYER

# Stats de combate base
@export var base_hp: int = 100
@export var base_attack: int = 20
@export var base_defense: int = 10
@export var base_speed: int = 80
@export var base_crit_chance: float = 0.15  # 15%
@export var base_crit_damage: float = 1.5   # 150%
@export var base_effectiveness: float = 0.0  # Para debuffs
@export var base_effect_resistance: float = 0.0  # Resistencia a debuffs
@export var base_elemental_mastery: float = 0.0  # Como el EM de Genshin

# Stats calculados (base + equipamiento + buffs)
var current_hp: int
var max_hp: int
var attack: int
var defense: int
var speed: int
var crit_chance: float
var crit_damage: float
var effectiveness: float
var effect_resistance: float
var elemental_mastery: float

# Sistema de Skills y Combat Readiness
@export var skills: Array[Skill] = []
var combat_readiness: float = 0.0  # 0-100, cuando llega a 100 es tu turno
var buffs: Array[StatusEffect] = []
var debuffs: Array[StatusEffect] = []

# Equipamiento (para futuro)
var weapon: Equipment
var armor: Equipment
var accessory: Equipment

func setup(name: String, lvl: int, rar: Rarity, elem: Element, hp: int, atk: int, def: int, spd: int, crit_c: float = 0.15, crit_d: float = 1.5):
	character_name = name
	level = lvl
	rarity = rar
	element = elem
	base_hp = hp
	base_attack = atk
	base_defense = def
	base_speed = spd
	base_crit_chance = crit_c
	base_crit_damage = crit_d
	
	_calculate_stats()
	current_hp = max_hp
	_setup_default_skills()

func _calculate_stats():
	# Calcular stats finales (base + nivel + equipamiento + buffs)
	var level_multiplier = 1.0 + (level - 1) * 0.1
	
	max_hp = int(base_hp * level_multiplier)
	attack = int(base_attack * level_multiplier)
	defense = int(base_defense * level_multiplier)
	speed = int(base_speed * level_multiplier)
	crit_chance = base_crit_chance
	crit_damage = base_crit_damage
	effectiveness = base_effectiveness
	effect_resistance = base_effect_resistance
	elemental_mastery = base_elemental_mastery
	
	# Aplicar buffs temporales
	_apply_status_effects()

func _apply_status_effects():
	for buff in buffs:
		buff.apply_effect(self)

func _setup_default_skills():
	var s1 = Skill.new()
	s1.setup("Basic Attack", 0, Skill.SkillType.DAMAGE, Skill.TargetType.SINGLE_ENEMY, 1.0, element)
	s1.description = "Deal damage to one enemy"
	
	var s2 = Skill.new()
	s2.setup("Power Strike", 0, Skill.SkillType.DAMAGE, Skill.TargetType.SINGLE_ENEMY, 1.3, element)
	s2.cooldown = 3
	s2.description = "Deal increased damage to one enemy"
	
	var s3 = Skill.new()
	s3.setup("Ultimate", 0, Skill.SkillType.DAMAGE, Skill.TargetType.ALL_ENEMIES, 1.8, element)
	s3.cooldown = 5
	s3.description = "Deal massive damage to all enemies"
	
	skills = [s1, s2, s3]

func take_damage(damage: int, is_crit: bool = false, damage_element: Element = Element.WATER) -> DamageResult:
	var result = DamageResult.new()
	
	# Calcular daño con defensa
	var final_damage = max(1, damage - defense)
	
	# Aplicar multiplicadores elementales
	var elemental_multiplier = _get_elemental_multiplier(damage_element, element)
	final_damage = int(final_damage * elemental_multiplier)
	
	# Aplicar daño crítico
	if is_crit:
		final_damage = int(final_damage * crit_damage)
		result.is_critical = true
	
	# Resistencias de buffs/debuffs
	for buff in buffs:
		if buff.effect_type == StatusEffect.EffectType.DAMAGE_REDUCTION:
			final_damage = int(final_damage * (1.0 - buff.value))
	
	current_hp = max(0, current_hp - final_damage)
	result.damage_dealt = final_damage
	result.element_used = damage_element
	result.is_weakness = elemental_multiplier > 1.0
	
	return result

func _get_elemental_multiplier(attack_element: Element, defend_element: Element) -> float:
	# Sistema de elementos: Agua > Fuego > Tierra > Agua
	# Radiant y Void son fuertes entre sí
	match [attack_element, defend_element]:
		[Element.WATER, Element.FIRE]: return 1.3
		[Element.FIRE, Element.EARTH]: return 1.3
		[Element.EARTH, Element.WATER]: return 1.3
		[Element.RADIANT, Element.VOID]: return 1.3
		[Element.VOID, Element.RADIANT]: return 1.3
		[Element.FIRE, Element.WATER]: return 0.7
		[Element.EARTH, Element.FIRE]: return 0.7
		[Element.WATER, Element.EARTH]: return 0.7
		_: return 1.0

func heal(amount: int):
	current_hp = min(max_hp, current_hp + amount)

func is_alive() -> bool:
	return current_hp > 0

func add_combat_readiness(amount: float):
	combat_readiness = min(100.0, combat_readiness + amount)

func reset_combat_readiness():
	combat_readiness = 0.0

func add_status_effect(effect: StatusEffect):
	# Verificar resistencia
	if effect.is_debuff and randf() < effect_resistance:
		return false  # Resistió el efecto
	
	if effect.is_debuff:
		debuffs.append(effect)
	else:
		buffs.append(effect)
	
	return true

func process_status_effects():
	# Procesar buffs
	for i in range(buffs.size() - 1, -1, -1):
		buffs[i].duration -= 1
		if buffs[i].duration <= 0:
			buffs.remove_at(i)
	
	# Procesar debuffs
	for i in range(debuffs.size() - 1, -1, -1):
		debuffs[i].duration -= 1
		if debuffs[i].duration <= 0:
			debuffs.remove_at(i)

func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON: return Color.GRAY
		Rarity.RARE: return Color.BLUE
		Rarity.EPIC: return Color.PURPLE
		Rarity.LEGENDARY: return Color.GOLD
		_: return Color.WHITE

func get_element_color() -> Color:
	match element:
		Element.WATER: return Color.CYAN
		Element.FIRE: return Color.RED
		Element.EARTH: return Color.GREEN
		Element.RADIANT: return Color.YELLOW
		Element.VOID: return Color.DARK_VIOLET
		_: return Color.WHITE

func get_element_name() -> String:
	match element:
		Element.WATER: return "Water"
		Element.FIRE: return "Fire"
		Element.EARTH: return "Earth"
		Element.RADIANT: return "Radiant"
		Element.VOID: return "Void"
		_: return "Unknown"
