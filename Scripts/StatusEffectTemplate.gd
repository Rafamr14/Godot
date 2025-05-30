class_name StatusEffectTemplate
extends Resource

@export var effect_name: String
@export var effect_type: StatusEffect.EffectType
@export var base_value: float
@export var base_duration: int
@export var is_debuff: bool = false
@export var can_stack: bool = false
@export var max_stacks: int = 1

# Scaling con stats
@export var attack_scaling: float = 0.0
@export var hp_scaling: float = 0.0

# Recursos visuales
@export var effect_icon: Texture2D
@export var particle_effect: PackedScene

func create_status_effect() -> StatusEffect:
	var effect = StatusEffect.new()
	effect.setup(effect_name, effect_type, base_value, base_duration, is_debuff)
	effect.stack_count = 1
	return effect
