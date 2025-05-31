# ==== GACHA PULL RESULT CORREGIDO (GachaPullResult.gd) ====
class_name GachaPullResult
extends Resource

@export var characters_obtained: Array = []  # CORREGIDO: Array genérico de Character
@export var pulls_performed: int = 0
@export var rarity_obtained: Character.Rarity = Character.Rarity.COMMON
@export var is_new_character: bool = false
@export var pity_reset: bool = false

func get_highest_rarity() -> Character.Rarity:
	var highest = Character.Rarity.COMMON
	for character in characters_obtained:
		if character is Character and character.rarity > highest:
			highest = character.rarity
	return highest

func get_characters_by_rarity(rarity: Character.Rarity) -> Array:  # CORREGIDO: Array genérico
	return characters_obtained.filter(func(char): return char is Character and char.rarity == rarity)
