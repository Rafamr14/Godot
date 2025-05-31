# ==== GACHA POOL (GachaPool.gd) ====
class_name GachaPool
extends Resource

@export var pool_name: String
@export var rarity: Character.Rarity = Character.Rarity.COMMON
@export var drop_rate: float = 0.7  # Probabilidad de este pool
@export var character_ids: Array[String] = []  # IDs de personajes en este pool

func setup(name: String, rar: Character.Rarity, rate: float, char_ids: Array[String]):
	pool_name = name
	rarity = rar
	drop_rate = rate
	character_ids = char_ids

func add_character(character_id: String):
	if character_id not in character_ids:
		character_ids.append(character_id)

func remove_character(character_id: String):
	var index = character_ids.find(character_id)
	if index != -1:
		character_ids.remove_at(index)
