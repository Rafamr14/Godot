class_name Skill
extends Resource

enum SkillType { DAMAGE, HEAL, BUFF, DEBUFF, SPECIAL }
enum TargetType { SINGLE_ENEMY, ALL_ENEMIES, SINGLE_ALLY, ALL_ALLIES, SELF, RANDOM_ENEMY }

@export var skill_name: String
@export var energy_cost: int = 0
@export var skill_type: SkillType = SkillType.DAMAGE
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var base_multiplier: float = 1.0  # Multiplicador de ataque
@export var element: Character.Element = Character.Element.WATER
@export var description: String = ""
@export var cooldown: int = 0
@export var current_cooldown: int = 0

# Efectos adicionales
@export var status_effects: Array[StatusEffect] = []
@export var effect_chance: float = 1.0  # Probabilidad de aplicar efectos
@export var hits: int = 1  # Número de hits (para multihit)
@export var cr_boost: float = 0.0  # Combat Readiness boost

func setup(name: String, cost: int, type: SkillType, target: TargetType, multiplier: float, elem: Character.Element):
	skill_name = name
	energy_cost = cost
	skill_type = type
	target_type = target
	base_multiplier = multiplier
	element = elem
	description = _generate_description()

func _generate_description() -> String:
	var desc = ""
	match skill_type:
		SkillType.DAMAGE:
			desc = "Deal " + str(int(base_multiplier * 100)) + "% ATK damage"
		SkillType.HEAL:
			desc = "Heal " + str(int(base_multiplier * 100)) + "% ATK"
		SkillType.BUFF:
			desc = "Apply beneficial effect"
		SkillType.DEBUFF:
			desc = "Apply harmful effect"
	
	if hits > 1:
		desc += " (" + str(hits) + " hits)"
	
	return desc

func can_use() -> bool:
	return current_cooldown == 0

func use_skill():
	current_cooldown = cooldown

func reduce_cooldown():
	if current_cooldown > 0:
		current_cooldown -= 1

func execute(caster: Character, targets: Array[Character]) -> Array[DamageResult]:
	var results: Array[DamageResult] = []
	
	for target in targets:
		match skill_type:
			SkillType.DAMAGE:
				results.append(_execute_damage(caster, target))
			SkillType.HEAL:
				results.append(_execute_heal(caster, target))
			SkillType.BUFF, SkillType.DEBUFF:
				results.append(_execute_status(caster, target))
	
	use_skill()
	return results

func _execute_damage(caster: Character, target: Character) -> DamageResult:
	var total_result = DamageResult.new()
	
	for hit in range(hits):
		var damage = int(caster.attack * base_multiplier)
		
		# Calcular crítico
		var is_crit = randf() < caster.crit_chance
		
		# Aplicar maestría elemental si coincide el elemento
		if element == caster.element:
			damage = int(damage * (1.0 + caster.elemental_mastery))
		
		var hit_result = target.take_damage(damage, is_crit, element)
		total_result.damage_dealt += hit_result.damage_dealt
		
		if hit_result.is_critical:
			total_result.is_critical = true
		if hit_result.is_weakness:
			total_result.is_weakness = true
	
	# Aplicar efectos de estado
	if randf() < effect_chance:
		for effect in status_effects:
			if target.add_status_effect(effect.duplicate()):
				total_result.effects_applied.append(effect)
	
	return total_result

func _execute_heal(caster: Character, target: Character) -> DamageResult:
	var heal_amount = int(caster.attack * base_multiplier)
	target.heal(heal_amount)
	
	var result = DamageResult.new()
	result.damage_dealt = -heal_amount  # Negativo para indicar curación
	return result

func _execute_status(caster: Character, target: Character) -> DamageResult:
	var result = DamageResult.new()
	
	if randf() < effect_chance:
		for effect in status_effects:
			if target.add_status_effect(effect.duplicate()):
				result.effects_applied.append(effect)
	
	return result
