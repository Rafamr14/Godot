# ==== CHARACTER DATA LOADER (CharacterDataLoader.gd) ====
# Sistema para cargar datos de personajes desde la carpeta Data
class_name CharacterDataLoader
extends RefCounted

static var cached_characters: Array[Character] = []
static var cached_templates: Array[CharacterTemplate] = []

# Cargar todos los archivos de personajes desde la carpeta Data
static func load_all_characters_from_data() -> Array[Character]:
	if not cached_characters.is_empty():
		return cached_characters
	
	print("Cargando personajes desde carpeta Data...")
	
	var characters: Array[Character] = []
	var data_path = "res://Data/"
	
	# Verificar si la carpeta Data existe
	if not DirAccess.dir_exists_absolute(data_path):
		print("Carpeta Data no encontrada, creando personajes por defecto...")
		return _create_default_characters()
	
	var dir = DirAccess.open(data_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				var full_path = data_path + file_name
				var resource = load(full_path)
				
				if resource is Character:
					characters.append(resource)
					print("Cargado personaje: ", resource.character_name)
				elif resource is CharacterTemplate:
					var character = resource.create_character_instance(1)
					characters.append(character)
					cached_templates.append(resource)
					print("Cargado template de personaje: ", resource.character_name)
			
			file_name = dir.get_next()
	else:
		print("Error al abrir carpeta Data")
		return _create_default_characters()
	
	# Si no encontramos personajes en Data, crear algunos por defecto
	if characters.is_empty():
		print("No se encontraron personajes en Data, creando por defecto...")
		characters = _create_default_characters()
	
	cached_characters = characters
	return characters

# Crear personajes por defecto si no hay archivo en Data
static func _create_default_characters() -> Array[Character]:
	var characters: Array[Character] = []
	
	# Warrior básico
	var warrior = Character.new()
	warrior.setup("Iron Knight", 1, Character.Rarity.COMMON, Character.Element.EARTH, 150, 20, 25, 60, 0.12, 1.4)
	characters.append(warrior)
	
	# Mago básico
	var mage = Character.new()
	mage.setup("Fire Mage", 1, Character.Rarity.COMMON, Character.Element.FIRE, 80, 35, 10, 85, 0.18, 1.6)
	characters.append(mage)
	
	# Curandero básico
	var healer = Character.new()
	healer.setup("Water Priest", 1, Character.Rarity.RARE, Character.Element.WATER, 100, 15, 20, 75, 0.10, 1.3)
	characters.append(healer)
	
	# Arquero raro
	var archer = Character.new()
	archer.setup("Wind Archer", 2, Character.Rarity.RARE, Character.Element.RADIANT, 90, 30, 12, 95, 0.25, 1.7)
	characters.append(archer)
	
	# Asesino épico
	var assassin = Character.new()
	assassin.setup("Shadow Assassin", 3, Character.Rarity.EPIC, Character.Element.VOID, 85, 40, 8, 110, 0.30, 1.9)
	characters.append(assassin)
	
	# Paladín épico
	var paladin = Character.new()
	paladin.setup("Holy Paladin", 3, Character.Rarity.EPIC, Character.Element.RADIANT, 180, 25, 30, 65, 0.15, 1.5)
	characters.append(paladin)
	
	# Dragón legendario
	var dragon = Character.new()
	dragon.setup("Ancient Dragon", 5, Character.Rarity.LEGENDARY, Character.Element.FIRE, 250, 50, 35, 80, 0.25, 2.0)
	characters.append(dragon)
	
	# Arcángel legendario
	var archangel = Character.new()
	archangel.setup("Archangel", 5, Character.Rarity.LEGENDARY, Character.Element.RADIANT, 200, 45, 40, 90, 0.20, 1.8)
	characters.append(archangel)
	
	print("Creados ", characters.size(), " personajes por defecto")
	return characters

# Guardar un personaje en la carpeta Data
static func save_character_to_data(character: Character, filename: String = "") -> bool:
	var data_path = "res://Data/"
	
	# Crear carpeta Data si no existe
	if not DirAccess.dir_exists_absolute(data_path):
		DirAccess.open("res://").make_dir("Data")
	
	if filename.is_empty():
		filename = character.character_name.to_snake_case() + ".tres"
	
	var full_path = data_path + filename
	var result = ResourceSaver.save(character, full_path)
	
	if result == OK:
		print("Personaje guardado en: ", full_path)
		return true
	else:
		print("Error al guardar personaje: ", result)
		return false

# Crear templates de personajes mejorados
static func create_enhanced_templates() -> Array[CharacterTemplate]:
	var templates: Array[CharacterTemplate] = []
	
	# Template de Guerrero Radiante
	var radiant_warrior = CharacterTemplate.new()
	radiant_warrior.character_name = "Radiant Warrior"
	radiant_warrior.character_id = "radiant_warrior_001"
	radiant_warrior.description = "A noble warrior blessed by divine light"
	radiant_warrior.element = Character.Element.RADIANT
	radiant_warrior.rarity = Character.Rarity.RARE
	radiant_warrior.character_class = CharacterTemplate.CharacterClass.WARRIOR
	
	radiant_warrior.base_hp = 140
	radiant_warrior.base_attack = 28
	radiant_warrior.base_defense = 22
	radiant_warrior.base_speed = 70
	radiant_warrior.base_crit_chance = 0.15
	radiant_warrior.base_crit_damage = 1.5
	
	templates.append(radiant_warrior)
	
	# Template de Mago del Vacío
	var void_mage = CharacterTemplate.new()
	void_mage.character_name = "Void Mage"
	void_mage.character_id = "void_mage_001"
	void_mage.description = "A mysterious mage who commands the void"
	void_mage.element = Character.Element.VOID
	void_mage.rarity = Character.Rarity.EPIC
	void_mage.character_class = CharacterTemplate.CharacterClass.MAGE
	
	void_mage.base_hp = 95
	void_mage.base_attack = 38
	void_mage.base_defense = 15
	void_mage.base_speed = 88
	void_mage.base_crit_chance = 0.22
	void_mage.base_crit_damage = 1.7
	
	templates.append(void_mage)
	
	# Template de Sacerdotisa del Agua
	var water_priestess = CharacterTemplate.new()
	water_priestess.character_name = "Water Priestess"
	water_priestess.character_id = "water_priestess_001"
	water_priestess.description = "A gentle healer with the power of flowing water"
	water_priestess.element = Character.Element.WATER
	water_priestess.rarity = Character.Rarity.RARE
	water_priestess.character_class = CharacterTemplate.CharacterClass.HEALER
	
	water_priestess.base_hp = 115
	water_priestess.base_attack = 22
	water_priestess.base_defense = 18
	water_priestess.base_speed = 82
	water_priestess.base_crit_chance = 0.12
	water_priestess.base_crit_damage = 1.4
	
	templates.append(water_priestess)
	
	# Template de Berserker de Fuego
	var fire_berserker = CharacterTemplate.new()
	fire_berserker.character_name = "Fire Berserker"
	fire_berserker.character_id = "fire_berserker_001"
	fire_berserker.description = "A wild warrior consumed by flames"
	fire_berserker.element = Character.Element.FIRE
	fire_berserker.rarity = Character.Rarity.EPIC
	fire_berserker.character_class = CharacterTemplate.CharacterClass.WARRIOR
	
	fire_berserker.base_hp = 105
	fire_berserker.base_attack = 42
	fire_berserker.base_defense = 12
	fire_berserker.base_speed = 95
	fire_berserker.base_crit_chance = 0.28
	fire_berserker.base_crit_damage = 1.8
	
	templates.append(fire_berserker)
	
	# Template de Guardián de Tierra
	var earth_guardian = CharacterTemplate.new()
	earth_guardian.character_name = "Earth Guardian"
	earth_guardian.character_id = "earth_guardian_001"
	earth_guardian.description = "An immovable protector of nature"
	earth_guardian.element = Character.Element.EARTH
	earth_guardian.rarity = Character.Rarity.RARE
	earth_guardian.character_class = CharacterTemplate.CharacterClass.TANK
	
	earth_guardian.base_hp = 180
	earth_guardian.base_attack = 18
	earth_guardian.base_defense = 32
	earth_guardian.base_speed = 55
	earth_guardian.base_crit_chance = 0.08
	earth_guardian.base_crit_damage = 1.3
	
	templates.append(earth_guardian)
	
	return templates

# Función para generar archivos de datos de ejemplo
static func generate_sample_data_files():
	var data_path = "res://Data/"
	
	# Crear carpeta si no existe
	if not DirAccess.dir_exists_absolute(data_path):
		DirAccess.open("res://").make_dir("Data")
	
	print("Generando archivos de ejemplo en Data/...")
	
	# Crear personajes de ejemplo
	var characters = _create_default_characters()
	
	for i in range(characters.size()):
		var character = characters[i]
		var filename = character.character_name.to_snake_case() + ".tres"
		save_character_to_data(character, filename)
	
	# Crear templates de ejemplo
	var templates = create_enhanced_templates()
	
	for i in range(templates.size()):
		var template = templates[i]
		var filename = template.character_id + "_template.tres"
		var full_path = data_path + filename
		var result = ResourceSaver.save(template, full_path)
		
		if result == OK:
			print("Template guardado en: ", full_path)
		else:
			print("Error al guardar template: ", result)
	
	print("Archivos de ejemplo generados en Data/")

# Limpiar cache para forzar recarga
static func clear_cache():
	cached_characters.clear()
	cached_templates.clear()
