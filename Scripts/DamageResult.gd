class_name DamageResult
extends Resource

var damage_dealt: int = 0
var is_critical: bool = false
var is_weakness: bool = false
var element_used: Character.Element
var effects_applied: Array[StatusEffect] = []
