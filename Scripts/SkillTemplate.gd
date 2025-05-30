class_name SkillTemplate
extends Resource

@export var skill_name: String
@export var skill_id: String
@export var description: String
@export var skill_type: Skill.SkillType = Skill.SkillType.DAMAGE
@export var target_type: Skill.TargetType = Skill.TargetType.SINGLE_ENEMY
@export var element: Character.Element = Character.Element.WATER

# Valores base del skill
@export var base_multiplier: float = 1.0
@export var base_cooldown: int = 0
@export var energy_cost: int = 0
@export var hits: int = 1

# Scaling con stats del personaje
@export var attack_scaling: float = 1.0     # % del ATK que usa
@export var hp_scaling: float = 0.0         # % del HP que usa
@export var defense_scaling: float = 0.0    # % del DEF que usa
@export var speed_scaling: float = 0.0      # % del SPD que usa

# Efectos adicionales
@export var status_effect_templates: Array[StatusEffectTemplate] = []
@export var effect_chance: float = 1.0
@export var cr_boost_self: float = 0.0      # Combat Readiness boost para el caster
@export var cr_boost_allies: float = 0.0    # Combat Readiness boost para aliados

# Mejoras por nivel del skill
@export var damage_per_level: float = 0.05  # +5% daño por nivel
@export var cooldown_reduction_levels: Array[int] = []  # Niveles donde se reduce cooldown

# Recursos visuales
@export var skill_icon: Texture2D
@export var animation_name: String
@export var sound_effect: AudioStream

func create_skill_instance(character_level: int = 1) -> Skill:
	var skill = Skill.new()
	
	# Información básica
	skill.skill_name = skill_name
	skill.skill_type = skill_type
	skill.target_type = target_type
	skill.element = element
	skill.description = description
	
	# Valores calculados
	var level_bonus = 1.0 + (character_level - 1) * damage_per_level
	skill.base_multiplier = base_multiplier * level_bonus
	skill.energy_cost = energy_cost
	skill.hits = hits
	skill.effect_chance = effect_chance
	skill.cr_boost = cr_boost_self
	
	# Cooldown (puede reducirse con niveles)
	skill.cooldown = base_cooldown
	for reduction_level in cooldown_reduction_levels:
		if character_level >= reduction_level:
			skill.cooldown = max(0, skill.cooldown - 1)
	
	skill.current_cooldown = 0
	
	# Crear efectos de estado
	for effect_template in status_effect_templates:
		var effect = effect_template.create_status_effect()
		skill.status_effects.append(effect)
	
	return skill
