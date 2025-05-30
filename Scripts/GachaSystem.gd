# ==== UPDATED GACHA SYSTEM (GachaSystem.gd) ====
class_name GachaSystem
extends Node

enum BannerType { STANDARD, RATE_UP, LIMITED }

var character_pool: Dictionary = {}
var gacha_rates: Dictionary = {
	Character.Rarity.COMMON: 0.7,
	Character.Rarity.RARE: 0.25,
	Character.Rarity.EPIC: 0.04,
	Character.Rarity.LEGENDARY: 0.01
}

var pity_counter: int = 0
var guaranteed_legendary_pity: int = 90

func _ready():
	_initialize_character_pool()

func _initialize_character_pool():
	# Personajes Comunes
	character_pool[Character.Rarity.COMMON] = [
		{"name": "Soldier", "element": Character.Element.EARTH, "hp": 120, "attack": 18, "defense": 12, "speed": 75, "crit_chance": 0.12, "crit_damage": 1.45},
		{"name": "Scout", "element": Character.Element.WATER, "hp": 90, "attack": 22, "defense": 8, "speed": 95, "crit_chance": 0.15, "crit_damage": 1.5},
		{"name": "Healer", "element": Character.Element.RADIANT, "hp": 100, "attack": 12, "defense": 15, "speed": 70, "crit_chance": 0.1, "crit_damage": 1.4}
	]
	
	# Personajes Raros
	character_pool[Character.Rarity.RARE] = [
		{"name": "Knight", "element": Character.Element.RADIANT, "hp": 150, "attack": 25, "defense": 20, "speed": 60, "crit_chance": 0.15, "crit_damage": 1.5},
		{"name": "Archer", "element": Character.Element.FIRE, "hp": 110, "attack": 30, "defense": 10, "speed": 85, "crit_chance": 0.2, "crit_damage": 1.6},
		{"name": "Priest", "element": Character.Element.WATER, "hp": 120, "attack": 15, "defense": 18, "speed": 80, "crit_chance": 0.12, "crit_damage": 1.45}
	]
	
	# Personajes Épicos
	character_pool[Character.Rarity.EPIC] = [
		{"name": "Paladin", "element": Character.Element.RADIANT, "hp": 180, "attack": 28, "defense": 25, "speed": 65, "crit_chance": 0.18, "crit_damage": 1.65},
		{"name": "Assassin", "element": Character.Element.VOID, "hp": 100, "attack": 40, "defense": 8, "speed": 110, "crit_chance": 0.3, "crit_damage": 1.8},
		{"name": "Mage", "element": Character.Element.FIRE, "hp": 130, "attack": 35, "defense": 12, "speed": 90, "crit_chance": 0.22, "crit_damage": 1.7}
	]
	
	# Personajes Legendarios
	character_pool[Character.Rarity.LEGENDARY] = [
		{"name": "Dragon Knight", "element": Character.Element.FIRE, "hp": 220, "attack": 35, "defense": 30, "speed": 75, "crit_chance": 0.25, "crit_damage": 1.9},
		{"name": "Archmage", "element": Character.Element.VOID, "hp": 160, "attack": 45, "defense": 15, "speed": 95, "crit_chance": 0.28, "crit_damage": 2.0},
		{"name": "Shadow Lord", "element": Character.Element.VOID, "hp": 180, "attack": 42, "defense": 18, "speed": 100, "crit_chance": 0.3, "crit_damage": 2.1}
	]

func single_pull() -> Character:
	pity_counter += 1
	
	var rarity = _determine_rarity()
	var character_data = _get_random_character(rarity)
	var new_character = _create_character_from_data(character_data, rarity)
	
	if rarity == Character.Rarity.LEGENDARY:
		pity_counter = 0
	
	return new_character

func ten_pull() -> Array[Character]:
	var results: Array[Character] = []
	
	for i in range(10):
		results.append(single_pull())
	
	return results

func _determine_rarity() -> Character.Rarity:
	if pity_counter >= guaranteed_legendary_pity:
		return Character.Rarity.LEGENDARY
	
	var random_value = randf()
	var cumulative_rate = 0.0
	
	for rarity in gacha_rates:
		cumulative_rate += gacha_rates[rarity]
		if random_value <= cumulative_rate:
			return rarity
	
	return Character.Rarity.COMMON

func _get_random_character(rarity: Character.Rarity) -> Dictionary:
	var pool = character_pool[rarity]
	return pool[randi() % pool.size()]

func _create_character_from_data(data: Dictionary, rarity: Character.Rarity) -> Character:
	var character = Character.new()
	character.setup(
		data.name,
		1,
		rarity,
		data.element,
		data.hp,
		data.attack,
		data.defense,
		data.speed,
		data.get("crit_chance", 0.15),
		data.get("crit_damage", 1.5)
	)
	return character
