class_name DamageResult
extends Resource

var damage_dealt: int = 0
var is_critical: bool = false
var is_weakness: bool = false
var element_used: Character.Element
var effects_applied: Array = []  # CORREGIDO: Array genérico de StatusEffect

func _init():
	damage_dealt = 0
	is_critical = false
	is_weakness = false
	element_used = Character.Element.WATER
	effects_applied.clear()

# Función para agregar un efecto aplicado
func add_effect(effect: StatusEffect):
	if effect != null:
		effects_applied.append(effect)

# Función para obtener información del resultado
func get_result_summary() -> String:
	var summary = ""
	
	if damage_dealt > 0:
		summary = "Dealt " + str(damage_dealt) + " damage"
		if is_critical:
			summary += " (CRITICAL)"
		if is_weakness:
			summary += " (WEAKNESS)"
	elif damage_dealt < 0:
		summary = "Healed " + str(-damage_dealt) + " HP"
	else:
		summary = "No damage/healing"
	
	if not effects_applied.is_empty():
		summary += " + " + str(effects_applied.size()) + " effects"
	
	return summary

# Función para duplicar el resultado - FIXED: Rename to avoid override
func duplicate_result() -> DamageResult:
	var new_result = DamageResult.new()
	new_result.damage_dealt = damage_dealt
	new_result.is_critical = is_critical
	new_result.is_weakness = is_weakness
	new_result.element_used = element_used
	
	# Copiar efectos
	for effect in effects_applied:
		if effect != null:
			new_result.effects_applied.append(effect)
	
	return new_result
