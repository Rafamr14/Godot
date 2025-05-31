# ==== GACHA BANNER SYSTEM (GachaBanner.gd) ====
class_name GachaBanner
extends Resource

@export var banner_id: String
@export var banner_name: String
@export var banner_description: String
@export var banner_image: Texture2D
@export var is_active: bool = true
@export var is_limited: bool = false

# Fechas de actividad
@export var start_date: String = ""
@export var end_date: String = ""

# Costos
@export var single_pull_cost: int = 100
@export var ten_pull_cost: int = 900
@export var currency_type: String = "gold"  # gold, gems, tickets, etc.

# Sistema de pity
@export var pity_threshold: int = 90
@export var soft_pity_start: int = 75
@export var guaranteed_5star_pity: int = 180  # Para banners limitados

# Pools de personajes con probabilidades
@export var character_pools: Array[GachaPool] = []

# Personajes destacados/rate-up
@export var featured_characters: Array[String] = []  # IDs de personajes
@export var rate_up_multiplier: float = 2.0

func setup(id: String, name: String, desc: String):
	banner_id = id
	banner_name = name
	banner_description = desc

func is_banner_active() -> bool:
	if not is_active:
		return false
	
	# TODO: Verificar fechas si es necesario
	return true

func get_total_rate() -> float:
	var total = 0.0
	for pool in character_pools:
		total += pool.drop_rate
	return total

func perform_single_pull(pity_counter: int = 0) -> GachaPullResult:
	var result = GachaPullResult.new()
	result.pulls_performed = 1
	
	# Aplicar pity
	var adjusted_rates = _apply_pity_rates(pity_counter)
	
	# Realizar tirada
	var random_value = randf()
	var cumulative_rate = 0.0
	
	for i in range(character_pools.size()):
		var pool = character_pools[i]
		cumulative_rate += adjusted_rates[i]
		
		if random_value <= cumulative_rate:
			var character = _get_character_from_pool(pool)
			if character:
				result.characters_obtained.append(character)
				result.rarity_obtained = character.rarity
				return result
	
	# Fallback al pool más común
	if character_pools.size() > 0:
		var character = _get_character_from_pool(character_pools[0])
		if character:
			result.characters_obtained.append(character)
			result.rarity_obtained = character.rarity
	
	return result

func perform_ten_pull(pity_counter: int = 0) -> GachaPullResult:
	var result = GachaPullResult.new()
	result.pulls_performed = 10
	
	var current_pity = pity_counter
	
	for i in range(10):
		var single_result = perform_single_pull(current_pity)
		if single_result.characters_obtained.size() > 0:
			result.characters_obtained.append_array(single_result.characters_obtained)
			
			# Reset pity si obtuvimos rareza alta
			if single_result.rarity_obtained >= Character.Rarity.EPIC:
				current_pity = 0
			else:
				current_pity += 1
	
	# Garantizar al menos un raro en 10-pull
	if not _has_rare_or_higher(result.characters_obtained):
		result.characters_obtained[9] = _get_guaranteed_rare()
	
	return result

func _apply_pity_rates(pity_counter: int) -> Array[float]:
	var adjusted_rates: Array[float] = []
	
	for pool in character_pools:
		var base_rate = pool.drop_rate
		
		# Aplicar soft pity
		if pity_counter >= soft_pity_start and pool.rarity >= Character.Rarity.EPIC:
			var pity_multiplier = 1.0 + (pity_counter - soft_pity_start) * 0.1
			base_rate *= pity_multiplier
		
		# Aplicar hard pity
		if pity_counter >= pity_threshold and pool.rarity >= Character.Rarity.EPIC:
			base_rate = 1.0  # 100% de probabilidad
		
		adjusted_rates.append(base_rate)
	
	return adjusted_rates

func _get_character_from_pool(pool: GachaPool) -> Character:
	if pool.character_ids.is_empty():
		return null
	
	# Verificar si hay personajes con rate-up
	var available_characters = pool.character_ids.duplicate()
	var selected_id: String
	
	# Aplicar rate-up a personajes destacados
	for featured_id in featured_characters:
		if featured_id in available_characters:
			if randf() < (pool.drop_rate * rate_up_multiplier):
				selected_id = featured_id
				break
	
	# Si no hay rate-up, seleccionar aleatoriamente
	if selected_id.is_empty():
		selected_id = available_characters[randi() % available_characters.size()]
	
	# Crear personaje desde CharacterDatabase
	var character_db = CharacterDatabase.get_instance()
	var template = character_db.get_template_by_id(selected_id)
	
	if template:
		return template.create_character_instance(1)
	else:
		# Fallback: crear personaje básico
		var fallback_char = Character.new()
		fallback_char.setup("Unknown Hero", 1, pool.rarity, Character.Element.WATER, 100, 20, 10, 80)
		return fallback_char

func _has_rare_or_higher(characters: Array[Character]) -> bool:
	for character in characters:
		if character.rarity >= Character.Rarity.RARE:
			return true
	return false

func _get_guaranteed_rare() -> Character:
	# Buscar pool de raros
	for pool in character_pools:
		if pool.rarity == Character.Rarity.RARE:
			return _get_character_from_pool(pool)
	
	# Fallback
	var char = Character.new()
	char.setup("Guaranteed Rare", 1, Character.Rarity.RARE, Character.Element.RADIANT, 120, 25, 15, 75)
	return char
