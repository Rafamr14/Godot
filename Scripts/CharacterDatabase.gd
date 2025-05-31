class_name CharacterDatabase
extends Resource

@export var character_templates: Array[CharacterTemplate] = []

static var instance: CharacterDatabase

static func get_instance() -> CharacterDatabase:
	if instance == null:
		# Intentar cargar desde archivo
		if ResourceLoader.exists("res://data/character_database.tres"):
			instance = load("res://data/character_database.tres") as CharacterDatabase
		
		if instance == null:
			instance = CharacterDatabase.new()
			instance._create_default_characters()
			print("CharacterDatabase creada con ", instance.character_templates.size(), " personajes")
		else:
			print("CharacterDatabase cargada desde archivo con ", instance.character_templates.size(), " personajes")
	return instance

func _create_default_characters():
	character_templates.clear()
	
	print("Creando base de datos de personajes por defecto...")
	
	# Crear personajes de ejemplo mejorados
	_create_radiant_warrior()
	_create_void_mage()
	_create_water_healer()
	_create_fire_berserker()
	_create_earth_guardian()
	_create_legendary_characters()
	
	print("Base de datos creada con ", character_templates.size(), " personajes")

func _create_radiant_warrior():
	var template = CharacterTemplate.new()
	template.character_name = "Radiant Warrior"
	template.character_id = "radiant_warrior_001"
	template.description = "A noble warrior blessed by divine light"
	template.element = Character.Element.RADIANT
	template.rarity = Character.Rarity.RARE
	template.character_class = CharacterTemplate.CharacterClass.WARRIOR
	
	# Stats base mejorados
	template.base_hp = 140
	template.base_attack = 28
	template.base_defense = 22
	template.base_speed = 70
	template.base_crit_chance = 0.15
	template.base_crit_damage = 1.5
	
	# Growth rates
	template.hp_growth = 0.08
	template.attack_growth = 0.06
	template.defense_growth = 0.05
	template.speed_growth = 0.02
	
	character_templates.append(template)

func _create_void_mage():
	var template = CharacterTemplate.new()
	template.character_name = "Void Mage"
	template.character_id = "void_mage_001"
	template.description = "A mysterious mage who commands the power of the void"
	template.element = Character.Element.VOID
	template.rarity = Character.Rarity.EPIC
	template.character_class = CharacterTemplate.CharacterClass.MAGE
	
	template.base_hp = 95
	template.base_attack = 38
	template.base_defense = 15
	template.base_speed = 88
	template.base_crit_chance = 0.22
	template.base_crit_damage = 1.7
	
	template.hp_growth = 0.06
	template.attack_growth = 0.08
	template.defense_growth = 0.04
	template.speed_growth = 0.03
	
	character_templates.append(template)

func _create_water_healer():
	var template = CharacterTemplate.new()
	template.character_name = "Water Priestess"
	template.character_id = "water_priestess_001"
	template.description = "A gentle healer with the power of flowing water"
	template.element = Character.Element.WATER
	template.rarity = Character.Rarity.RARE
	template.character_class = CharacterTemplate.CharacterClass.HEALER
	
	template.base_hp = 115
	template.base_attack = 22
	template.base_defense = 18
	template.base_speed = 82
	template.base_crit_chance = 0.12
	template.base_crit_damage = 1.4
	
	template.hp_growth = 0.07
	template.attack_growth = 0.05
	template.defense_growth = 0.05
	template.speed_growth = 0.025
	
	character_templates.append(template)

func _create_fire_berserker():
	var template = CharacterTemplate.new()
	template.character_name = "Fire Berserker"
	template.character_id = "fire_berserker_001"
	template.description = "A wild warrior consumed by flames of fury"
	template.element = Character.Element.FIRE
	template.rarity = Character.Rarity.EPIC
	template.character_class = CharacterTemplate.CharacterClass.WARRIOR
	
	template.base_hp = 105
	template.base_attack = 42
	template.base_defense = 12
	template.base_speed = 95
	template.base_crit_chance = 0.28
	template.base_crit_damage = 1.8
	
	template.hp_growth = 0.06
	template.attack_growth = 0.09
	template.defense_growth = 0.03
	template.speed_growth = 0.04
	
	character_templates.append(template)

func _create_earth_guardian():
	var template = CharacterTemplate.new()
	template.character_name = "Earth Guardian"
	template.character_id = "earth_guardian_001"
	template.description = "An immovable protector of nature and earth"
	template.element = Character.Element.EARTH
	template.rarity = Character.Rarity.RARE
	template.character_class = CharacterTemplate.CharacterClass.TANK
	
	template.base_hp = 180
	template.base_attack = 18
	template.base_defense = 32
	template.base_speed = 55
	template.base_crit_chance = 0.08
	template.base_crit_damage = 1.3
	
	template.hp_growth = 0.09
	template.attack_growth = 0.04
	template.defense_growth = 0.07
	template.speed_growth = 0.015
	
	character_templates.append(template)

func _create_legendary_characters():
	# Dragon Lord - Legendario de Fuego
	var dragon_lord = CharacterTemplate.new()
	dragon_lord.character_name = "Ancient Dragon Lord"
	dragon_lord.character_id = "dragon_lord_001"
	dragon_lord.description = "An ancient dragon with immense power over fire"
	dragon_lord.element = Character.Element.FIRE
	dragon_lord.rarity = Character.Rarity.LEGENDARY
	dragon_lord.character_class = CharacterTemplate.CharacterClass.WARRIOR
	
	dragon_lord.base_hp = 220
	dragon_lord.base_attack = 48
	dragon_lord.base_defense = 28
	dragon_lord.base_speed = 75
	dragon_lord.base_crit_chance = 0.25
	dragon_lord.base_crit_damage = 2.0
	
	dragon_lord.hp_growth = 0.10
	dragon_lord.attack_growth = 0.08
	dragon_lord.defense_growth = 0.06
	dragon_lord.speed_growth = 0.025
	
	character_templates.append(dragon_lord)
	
	# Archangel - Legendario Radiante
	var archangel = CharacterTemplate.new()
	archangel.character_name = "Divine Archangel"
	archangel.character_id = "archangel_001"
	archangel.description = "A divine being of pure radiant energy"
	archangel.element = Character.Element.RADIANT
	archangel.rarity = Character.Rarity.LEGENDARY
	archangel.character_class = CharacterTemplate.CharacterClass.HEALER
	
	archangel.base_hp = 160
	archangel.base_attack = 35
	archangel.base_defense = 25
	archangel.base_speed = 90
	archangel.base_crit_chance = 0.20
	archangel.base_crit_damage = 1.8
	
	archangel.hp_growth = 0.08
	archangel.attack_growth = 0.07
	archangel.defense_growth = 0.05
	archangel.speed_growth = 0.03
	
	character_templates.append(archangel)
	
	# Void Emperor - Legendario del Vacío
	var void_emperor = CharacterTemplate.new()
	void_emperor.character_name = "Void Emperor"
	void_emperor.character_id = "void_emperor_001"
	void_emperor.description = "Ruler of the void realm with unmatched dark magic"
	void_emperor.element = Character.Element.VOID
	void_emperor.rarity = Character.Rarity.LEGENDARY
	void_emperor.character_class = CharacterTemplate.CharacterClass.MAGE
	
	void_emperor.base_hp = 140
	void_emperor.base_attack = 52
	void_emperor.base_defense = 18
	void_emperor.base_speed = 100
	void_emperor.base_crit_chance = 0.30
	void_emperor.base_crit_damage = 2.2
	
	void_emperor.hp_growth = 0.07
	void_emperor.attack_growth = 0.10
	void_emperor.defense_growth = 0.04
	void_emperor.speed_growth = 0.035
	
	character_templates.append(void_emperor)

func get_template_by_id(character_id: String) -> CharacterTemplate:
	for template in character_templates:
		if template.character_id == character_id:
			return template
	return null

func get_templates_by_element(element: Character.Element) -> Array[CharacterTemplate]:
	return character_templates.filter(func(template): return template.element == element)

func get_templates_by_rarity(rarity: Character.Rarity) -> Array[CharacterTemplate]:
	return character_templates.filter(func(template): return template.rarity == rarity)

func get_templates_by_class(char_class: CharacterTemplate.CharacterClass) -> Array[CharacterTemplate]:
	return character_templates.filter(func(template): return template.character_class == char_class)

func get_random_template(rarity_filter: Character.Rarity = Character.Rarity.COMMON) -> CharacterTemplate:
	var filtered_templates = get_templates_by_rarity(rarity_filter)
	if filtered_templates.is_empty():
		filtered_templates = character_templates
	
	if filtered_templates.is_empty():
		return null
	
	return filtered_templates[randi() % filtered_templates.size()]

func get_random_template_weighted() -> CharacterTemplate:
	# Sistema de peso para rareza (como gacha real)
	var random_value = randf()
	var target_rarity: Character.Rarity
	
	if random_value < 0.03:  # 3% Legendary
		target_rarity = Character.Rarity.LEGENDARY
	elif random_value < 0.15:  # 12% Epic
		target_rarity = Character.Rarity.EPIC
	elif random_value < 0.40:  # 25% Rare
		target_rarity = Character.Rarity.RARE
	else:  # 60% Common
		target_rarity = Character.Rarity.COMMON
	
	var templates = get_templates_by_rarity(target_rarity)
	if templates.is_empty():
		# Fallback a cualquier template
		templates = character_templates
	
	if templates.is_empty():
		return null
	
	return templates[randi() % templates.size()]

# Función para crear instancias de personajes con niveles aleatorios
func create_random_character_instances(count: int, min_level: int = 1, max_level: int = 5) -> Array[Character]:
	var characters: Array[Character] = []
	
	for i in range(count):
		var template = get_random_template_weighted()
		if template:
			var level = randi_range(min_level, max_level)
			var character = template.create_character_instance(level)
			characters.append(character)
	
	return characters

# Guardar la base de datos
func save_database():
	var result = ResourceSaver.save(self, "res://data/character_database.tres")
	if result == OK:
		print("Base de datos guardada exitosamente")
	else:
		print("Error al guardar base de datos: ", result)
