# ==== ENHANCED GACHA SYSTEM CORREGIDO (EnhancedGachaSystem.gd) ====
class_name EnhancedGachaSystem
extends Node

signal pull_completed(result: GachaPullResult)
signal banner_changed(banner: GachaBanner)

# Banners disponibles - CORREGIDO: Array genérico
var available_banners: Array = []  # Array de GachaBanner
var current_banner: GachaBanner
var current_banner_index: int = 0

# Sistema de pity por banner
var pity_counters: Dictionary = {}  # banner_id -> pity_count
var legendary_pity_counters: Dictionary = {}  # Para banners limitados

# Referencias
var game_manager: GameManager

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	_find_game_manager()
	_initialize_default_banners()
	_set_current_banner(0)

func _find_game_manager():
	# Buscar GameManager de múltiples maneras
	game_manager = get_parent().get_node_or_null("GameManager")
	
	if not game_manager:
		game_manager = get_tree().get_first_node_in_group("game_manager")
	
	if not game_manager:
		for node in get_tree().current_scene.get_children():
			if node.get_script() and node.get_script().get_global_name() == "GameManager":
				game_manager = node
				break
	
	if game_manager:
		print("EnhancedGachaSystem: GameManager encontrado")
	else:
		print("EnhancedGachaSystem: GameManager no encontrado, algunas funciones limitadas")

func _initialize_default_banners():
	print("Initializing gacha banners...")
	available_banners.clear()
	
	# Banner Estándar
	var standard_banner = _create_standard_banner()
	available_banners.append(standard_banner)
	
	# Banner de Fuego
	var fire_banner = _create_fire_banner()
	available_banners.append(fire_banner)
	
	# Banner Limitado
	var limited_banner = _create_limited_banner()
	available_banners.append(limited_banner)
	
	print("Created ", available_banners.size(), " banners")

func _create_standard_banner() -> GachaBanner:
	var banner = GachaBanner.new()
	banner.setup("standard", "Standard Banner", "Permanent banner with all characters")
	banner.is_limited = false
	banner.pity_threshold = 90
	
	# CORREGIDO: Usar Array genérico y crear pools correctamente
	var character_pools = []
	
	# Pool de comunes (70%)
	var common_pool = GachaPool.new()
	common_pool.setup("Common Heroes", Character.Rarity.COMMON, 0.70, 
		["basic_warrior", "basic_mage", "basic_archer"])
	character_pools.append(common_pool)
	
	# Pool de raros (25%)
	var rare_pool = GachaPool.new()
	rare_pool.setup("Rare Heroes", Character.Rarity.RARE, 0.25, 
		["radiant_warrior_001", "water_priestess_001", "earth_guardian_001"])
	character_pools.append(rare_pool)
	
	# Pool de épicos (4%)
	var epic_pool = GachaPool.new()
	epic_pool.setup("Epic Heroes", Character.Rarity.EPIC, 0.04, 
		["void_mage_001", "fire_berserker_001"])
	character_pools.append(epic_pool)
	
	# Pool de legendarios (1%)
	var legendary_pool = GachaPool.new()
	legendary_pool.setup("Legendary Heroes", Character.Rarity.LEGENDARY, 0.01, 
		["dragon_lord_001", "archangel_001"])
	character_pools.append(legendary_pool)
	
	banner.character_pools = character_pools
	return banner

func _create_fire_banner() -> GachaBanner:
	var banner = GachaBanner.new()
	banner.setup("fire_rate_up", "Fire Heroes Rate-Up", "Increased rates for Fire element heroes!")
	banner.is_limited = false
	banner.rate_up_multiplier = 3.0
	banner.featured_characters = ["fire_berserker_001"]
	
	var character_pools = []
	
	# Mismo pool pero con rate-up para personajes de fuego
	var common_pool = GachaPool.new()
	common_pool.setup("Common Fire", Character.Rarity.COMMON, 0.70, 
		["fire_soldier", "flame_scout"])
	character_pools.append(common_pool)
	
	var rare_pool = GachaPool.new()
	rare_pool.setup("Rare Fire", Character.Rarity.RARE, 0.25, 
		["fire_knight", "flame_archer"])
	character_pools.append(rare_pool)
	
	var epic_pool = GachaPool.new()
	epic_pool.setup("Epic Fire", Character.Rarity.EPIC, 0.04, 
		["fire_berserker_001", "inferno_mage"])
	character_pools.append(epic_pool)
	
	var legendary_pool = GachaPool.new()
	legendary_pool.setup("Legendary Fire", Character.Rarity.LEGENDARY, 0.01, 
		["dragon_lord_001"])
	character_pools.append(legendary_pool)
	
	banner.character_pools = character_pools
	return banner

func _create_limited_banner() -> GachaBanner:
	var banner = GachaBanner.new()
	banner.setup("void_limited", "Void Emperor Limited", "Limited time! Exclusive Void Emperor banner!")
	banner.is_limited = true
	banner.guaranteed_5star_pity = 180
	banner.featured_characters = ["void_emperor_001"]
	banner.rate_up_multiplier = 5.0
	
	var character_pools = []
	
	# Pool limitado con Void Emperor
	var common_pool = GachaPool.new()
	common_pool.setup("Limited Common", Character.Rarity.COMMON, 0.65, 
		["void_soldier", "shadow_scout"])
	character_pools.append(common_pool)
	
	var rare_pool = GachaPool.new()
	rare_pool.setup("Limited Rare", Character.Rarity.RARE, 0.30, 
		["void_knight", "shadow_mage"])
	character_pools.append(rare_pool)
	
	var epic_pool = GachaPool.new()
	epic_pool.setup("Limited Epic", Character.Rarity.EPIC, 0.04, 
		["void_mage_001"])
	character_pools.append(epic_pool)
	
	var legendary_pool = GachaPool.new()
	legendary_pool.setup("Limited Legendary", Character.Rarity.LEGENDARY, 0.01, 
		["void_emperor_001"])
	character_pools.append(legendary_pool)
	
	banner.character_pools = character_pools
	return banner

func get_available_banners() -> Array:
	return available_banners.filter(func(banner): return banner.is_banner_active())

func set_current_banner_by_id(banner_id: String):
	for i in range(available_banners.size()):
		if available_banners[i].banner_id == banner_id:
			_set_current_banner(i)
			break

func set_current_banner_by_index(index: int):
	_set_current_banner(index)

func _set_current_banner(index: int):
	if index >= 0 and index < available_banners.size():
		current_banner_index = index
		current_banner = available_banners[index]
		
		# Inicializar pity si no existe
		if current_banner.banner_id not in pity_counters:
			pity_counters[current_banner.banner_id] = 0
			legendary_pity_counters[current_banner.banner_id] = 0
		
		banner_changed.emit(current_banner)
		print("Banner changed to: ", current_banner.banner_name)

func get_current_banner() -> GachaBanner:
	return current_banner

func get_current_pity() -> int:
	if not current_banner:
		return 0
	return pity_counters.get(current_banner.banner_id, 0)

func get_current_legendary_pity() -> int:
	if not current_banner:
		return 0
	return legendary_pity_counters.get(current_banner.banner_id, 0)

func can_afford_single_pull() -> bool:
	if not current_banner or not game_manager:
		return false
	return game_manager.game_currency >= current_banner.single_pull_cost

func can_afford_ten_pull() -> bool:
	if not current_banner or not game_manager:
		return false
	return game_manager.game_currency >= current_banner.ten_pull_cost

func perform_single_pull() -> GachaPullResult:
	if not current_banner or not game_manager:
		var empty_result = GachaPullResult.new()
		return empty_result
	
	if not can_afford_single_pull():
		print("Cannot afford single pull!")
		var empty_result = GachaPullResult.new()
		return empty_result
	
	# Deducir costo
	game_manager.spend_currency(current_banner.single_pull_cost)
	
	# Realizar tirada
	var pity = get_current_pity()
	var result = current_banner.perform_single_pull(pity)
	
	# Actualizar pity
	_update_pity_counters(result)
	
	# Agregar personajes al inventario
	if game_manager and result.characters_obtained.size() > 0:
		for character in result.characters_obtained:
			game_manager.player_inventory.append(character)
	
	pull_completed.emit(result)
	return result

func perform_ten_pull() -> GachaPullResult:
	if not current_banner or not game_manager:
		var empty_result = GachaPullResult.new()
		return empty_result
	
	if not can_afford_ten_pull():
		print("Cannot afford ten pull!")
		var empty_result = GachaPullResult.new()
		return empty_result
	
	# Deducir costo
	game_manager.spend_currency(current_banner.ten_pull_cost)
	
	# Realizar tirada
	var pity = get_current_pity()
	var result = current_banner.perform_ten_pull(pity)
	
	# Actualizar pity
	_update_pity_counters(result)
	
	# Agregar personajes al inventario
	if game_manager and result.characters_obtained.size() > 0:
		for character in result.characters_obtained:
			game_manager.player_inventory.append(character)
	
	pull_completed.emit(result)
	return result

func _update_pity_counters(result: GachaPullResult):
	if not current_banner:
		return
	
	var banner_id = current_banner.banner_id
	var current_pity = pity_counters.get(banner_id, 0)
	var legendary_pity = legendary_pity_counters.get(banner_id, 0)
	
	# Verificar si obtuvimos personajes de alta rareza
	var got_epic_or_higher = false
	var got_legendary = false
	
	for character in result.characters_obtained:
		if character.rarity >= Character.Rarity.EPIC:
			got_epic_or_higher = true
		if character.rarity == Character.Rarity.LEGENDARY:
			got_legendary = true
	
	# Actualizar contadores
	if got_epic_or_higher:
		pity_counters[banner_id] = 0  # Reset pity normal
	else:
		pity_counters[banner_id] = current_pity + result.pulls_performed
	
	if got_legendary:
		legendary_pity_counters[banner_id] = 0  # Reset pity legendario
	else:
		legendary_pity_counters[banner_id] = legendary_pity + result.pulls_performed

# Función para obtener información del banner actual
func get_banner_info() -> Dictionary:
	if not current_banner:
		return {}
	
	return {
		"name": current_banner.banner_name,
		"description": current_banner.banner_description,
		"single_cost": current_banner.single_pull_cost,
		"ten_cost": current_banner.ten_pull_cost,
		"pity": get_current_pity(),
		"pity_threshold": current_banner.pity_threshold,
		"legendary_pity": get_current_legendary_pity(),
		"is_limited": current_banner.is_limited,
		"featured_characters": current_banner.featured_characters
	}

# Función para debug: resetear pity
func reset_pity():
	if current_banner:
		pity_counters[current_banner.banner_id] = 0
		legendary_pity_counters[current_banner.banner_id] = 0
		print("Pity reset for banner: ", current_banner.banner_name)
