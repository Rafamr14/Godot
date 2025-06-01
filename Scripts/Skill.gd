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

# Efectos adicionales - CORREGIDO: Array genérico
@export var status_effects: Array = []  # Array de StatusEffect
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

func execute(caster: Character, targets: Array) -> Array:
	var results: Array = []
	
	# Verificar que el caster y targets son válidos
	if not caster or targets.is_empty():
		print("Skill.execute: Invalid caster or targets")
		return results
	
	# Ejecutar skill según tipo en cada target
	for target in targets:
		if target != null and target is Character:
			match skill_type:
				SkillType.DAMAGE:
					results.append(_execute_damage(caster, target))
				SkillType.HEAL:
					results.append(_execute_heal(caster, target))
				SkillType.BUFF, SkillType.DEBUFF:
					results.append(_execute_status(caster, target))
				_:
					# Skill type no reconocido, ejecutar como daño por defecto
					results.append(_execute_damage(caster, target))
		else:
			print("Skill.execute: Invalid target: ", target)
			# Agregar resultado vacío para mantener sincronización
			var empty_result = DamageResult.new()
			results.append(empty_result)
	
	use_skill()
	return results

func _execute_damage(caster: Character, target: Character) -> DamageResult:
	var total_result = DamageResult.new()
	
	if not caster or not target:
		print("Skill._execute_damage: Invalid caster or target")
		return total_result
	
	# Ejecutar múltiples hits si es necesario
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
			if effect != null and target.add_status_effect(effect.duplicate_skill_effect() if effect.has_method("duplicate_skill_effect") else effect):
				total_result.effects_applied.append(effect)
	
	return total_result

func _execute_heal(caster: Character, target: Character) -> DamageResult:
	var result = DamageResult.new()
	
	if not caster or not target:
		print("Skill._execute_heal: Invalid caster or target")
		return result
	
	var heal_amount = int(caster.attack * base_multiplier)
	target.heal(heal_amount)
	
	result.damage_dealt = -heal_amount  # Negativo para indicar curación
	return result

func _execute_status(caster: Character, target: Character) -> DamageResult:
	var result = DamageResult.new()
	
	if not caster or not target:
		print("Skill._execute_status: Invalid caster or target")
		return result
	
	if randf() < effect_chance:
		for effect in status_effects:
			if effect != null:
				var effect_copy = effect.duplicate_skill_effect() if effect.has_method("duplicate_skill_effect") else effect
				if target.add_status_effect(effect_copy):
					result.effects_applied.append(effect)
	
	return result

# Función para duplicar el skill - FIXED: Rename to avoid override
func duplicate_skill() -> Skill:
	var new_skill = Skill.new()
	new_skill.skill_name = skill_name
	new_skill.energy_cost = energy_cost
	new_skill.skill_type = skill_type
	new_skill.target_type = target_type
	new_skill.base_multiplier = base_multiplier
	new_skill.element = element
	new_skill.description = description
	new_skill.cooldown = cooldown
	new_skill.current_cooldown = current_cooldown
	new_skill.effect_chance = effect_chance
	new_skill.hits = hits
	new_skill.cr_boost = cr_boost
	
	# Copiar efectos de estado
	for effect in status_effects:
		if effect != null:
			new_skill.status_effects.append(effect.duplicate_skill_effect() if effect.has_method("duplicate_skill_effect") else effect)
	
	return new_skill

# Función para verificar si el skill es válido
func is_valid() -> bool:
	if skill_name.is_empty():
		return false
	if base_multiplier <= 0:
		return false
	if cooldown < 0:
		return false
	return true

# Función de debug
func debug_print():
	print("=== SKILL DEBUG: ", skill_name, " ===")
	print("Type: ", SkillType.keys()[skill_type])
	print("Target: ", TargetType.keys()[target_type])
	print("Multiplier: ", base_multiplier)
	print("Element: ", Character.Element.keys()[element])
	print("Cooldown: ", current_cooldown, "/", cooldown)
	print("Hits: ", hits)
	print("Effect Chance: ", effect_chance)
	print("Status Effects: ", status_effects.size())
	print("=================================")
