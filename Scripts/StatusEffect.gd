class_name StatusEffect
extends Resource

enum EffectType { 
	ATTACK_UP, ATTACK_DOWN, 
	DEFENSE_UP, DEFENSE_DOWN,
	SPEED_UP, SPEED_DOWN,
	CRIT_CHANCE_UP, CRIT_DAMAGE_UP,
	DAMAGE_REDUCTION, DAMAGE_AMPLIFICATION,
	POISON, BURN, BLEED,
	STUN, SLEEP, SILENCE,
	IMMUNITY, INVINCIBILITY
}

@export var effect_name: String
@export var effect_type: EffectType
@export var value: float  # Multiplicador o valor fijo
@export var duration: int  # Turnos que dura
@export var is_debuff: bool = false
@export var stack_count: int = 1  # Para efectos acumulables

func setup(name: String, type: EffectType, val: float, dur: int, debuff: bool = false):
	effect_name = name
	effect_type = type
	value = val
	duration = dur
	is_debuff = debuff

func apply_effect(character: Character):
	match effect_type:
		EffectType.ATTACK_UP:
			character.attack = int(character.attack * (1.0 + value))
		EffectType.ATTACK_DOWN:
			character.attack = int(character.attack * (1.0 - value))
		EffectType.DEFENSE_UP:
			character.defense = int(character.defense * (1.0 + value))
		EffectType.DEFENSE_DOWN:
			character.defense = int(character.defense * (1.0 - value))
		EffectType.SPEED_UP:
			character.speed = int(character.speed * (1.0 + value))
		EffectType.SPEED_DOWN:
			character.speed = int(character.speed * (1.0 - value))
		EffectType.POISON:
			character.take_damage(int(character.max_hp * value))
		EffectType.BURN:
			character.take_damage(int(character.max_hp * value))

func create_copy() -> StatusEffect:
	var new_effect = StatusEffect.new()
	new_effect.effect_name = effect_name
	new_effect.effect_type = effect_type
	new_effect.value = value
	new_effect.duration = duration
	new_effect.is_debuff = is_debuff
	new_effect.stack_count = stack_count
	return new_effect
