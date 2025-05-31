# ==== CHARACTER GENERATOR PARA DATA/CHARACTERS ====
# Script utilitario para generar personajes de ejemplo en la carpeta correcta
# Ejecutar desde el editor o llamar desde código

@tool
extends EditorScript

func _run():
	print("Generando personajes de ejemplo en Data/Characters...")
	_generate_characters_in_data_folder()

func _generate_characters_in_data_folder():
	var characters_path = "res://Data/Characters/"
	
	# Crear carpeta si no existe
	_ensure_directory_exists(characters_path)
	
	# Generar personajes usando CharacterDatabase si está disponible
	var character_db = CharacterDatabase.get_instance()
	if character_db and character_db.character_templates.size() > 0:
		print("Usando CharacterDatabase para generar personajes...")
		_generate_from_database(characters_path, character_db)
	else:
		print("CharacterDatabase no disponible, creando personajes básicos...")
		_generate_basic_characters(characters_path)
	
	print("Generación completada en Data/Characters/")

func _ensure_directory_exists(path: String):
	if not DirAccess.dir_exists_absolute(path):
		var dir = DirAccess.open("res://")
		if dir:
			dir.make_dir_recursive("Data/Characters")
			print("✓ Creada carpeta: ", path)
		else:
			print("✗ Error creando carpeta: ", path)

func _generate_from_database(path: String, database: CharacterDatabase):
	"""Generar personajes usando CharacterDatabase"""
	
	# Crear 10 personajes variados
	for i in range(10):
		var template = database.get_random_template_weighted()
		if template:
			var level = randi_range(1, 5)
			var character = template.create_character_instance(level)
			
			var filename = template.character_id + "_lv" + str(level) + "_" + str(i) + ".tres"
			_save_character(character, path + filename)

func _generate_basic_characters(path: String):
	"""Generar personajes básicos si no hay CharacterDatabase"""
	
	var character_data = [
		{"name": "Forest Warrior", "element": Character.Element.EARTH, "rarity": Character.Rarity.COMMON, "hp": 120, "attack": 22, "defense": 18, "speed": 70},
		{"name": "Fire Mage", "element": Character.Element.FIRE, "rarity": Character.Rarity.RARE, "hp": 90, "attack": 35, "defense": 12, "speed": 85},
		{"name": "Water Healer", "element": Character.Element.WATER, "rarity": Character.Rarity.RARE, "hp": 110, "attack": 18, "defense": 20, "speed": 80},
		{"name": "Radiant Knight", "element": Character.Element.RADIANT, "rarity": Character.Rarity.EPIC, "hp": 150, "attack": 28, "defense": 25, "speed": 65},
		{"name": "Void Assassin", "element": Character.Element.VOID, "rarity": Character.Rarity.EPIC, "hp": 85, "attack": 40, "defense": 10, "speed": 95},
		{"name": "Ancient Dragon", "element": Character.Element.FIRE, "rarity": Character.Rarity.LEGENDARY, "hp": 200, "attack": 45, "defense": 30, "speed": 75},
		{"name": "Lightning Archer", "element": Character.Element.RADIANT, "rarity": Character.Rarity.RARE, "hp": 95, "attack": 32, "defense": 15, "speed": 90},
		{"name": "Earth Guardian", "element": Character.Element.EARTH, "rarity": Character.Rarity.EPIC, "hp": 180, "attack": 20, "defense": 35, "speed": 55},
		{"name": "Shadow Mage", "element": Character.Element.VOID, "rarity": Character.Rarity.RARE, "hp": 85, "attack": 38, "defense": 12, "speed": 88},
		{"name": "Frost Warrior", "element": Character.Element.WATER, "rarity": Character.Rarity.EPIC, "hp": 135, "attack": 30, "defense": 22, "speed": 72}
	]
	
	for i in range(character_data.size()):
		var data = character_data[i]
		var character = Character.new()
		
		var level = randi_range(1, 5)
		character.setup(
			data.name,
			level,
			data.rarity,
			data.element,
			data.hp + (level - 1) * 8,
			data.attack + (level - 1) * 3,
			data.defense + (level - 1) * 2,
			data.speed + (level - 1) * 1,
			0.15 + randf() * 0.1,  # Crit chance random
			1.5 + randf() * 0.3    # Crit damage random
		)
		
		var filename = data.name.to_snake_case() + "_lv" + str(level) + ".tres"
		_save_character(character, path + filename)

func _save_character(character: Character, file_path: String) -> bool:
	var result = ResourceSaver.save(character, file_path)
	
	if result == OK:
		print("✓ Guardado: ", character.character_name, " en ", file_path.get_file())
		return true
	else:
		print("✗ Error guardando: ", character.character_name, " - Error: ", result)
		return false

# ==== FUNCIONES ESTÁTICAS PARA USAR DESDE CÓDIGO ====

static func generate_characters_if_empty():
	"""Generar personajes solo si la carpeta está vacía"""
	var characters_path = "res://Data/Characters/"
	
	if not DirAccess.dir_exists_absolute(characters_path):
		print("Carpeta Data/Characters no existe, creando...")
		create_characters_folder()
		generate_sample_characters()
		return
	
	# Verificar si la carpeta está vacía
	var dir = DirAccess.open(characters_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		var has_characters = false
		
		while file_name != "":
			if file_name.ends_with(".tres") or file_name.ends_with(".res"):
				has_characters = true
				break
			file_name = dir.get_next()
		
		dir.list_dir_end()
		
		if not has_characters:
			print("Data/Characters está vacía, generando personajes de ejemplo...")
			generate_sample_characters()
		else:
			print("Data/Characters ya contiene personajes")

static func create_characters_folder():
	"""Crear la carpeta Data/Characters"""
	var dir = DirAccess.open("res://")
	if dir:
		dir.make_dir_recursive("Data/Characters")
		print("✓ Carpeta Data/Characters creada")
	else:
		print("✗ Error creando carpeta Data/Characters")

static func generate_sample_characters():
	"""Generar personajes de ejemplo"""
	var generator = CharacterGenerator.new()
	generator._generate_characters_in_data_folder()

# ==== CLASE PRINCIPAL ====
class CharacterGenerator:
	func _generate_characters_in_data_folder():
		var characters_path = "res://Data/Characters/"
		
		# Asegurar que existe la carpeta
		if not DirAccess.dir_exists_absolute(characters_path):
			var dir = DirAccess.open("res://")
			if dir:
				dir.make_dir_recursive("Data/Characters")
		
		# Generar personajes básicos
		_generate_basic_characters(characters_path)
	
	func _generate_basic_characters(path: String):
		var character_data = [
			{"name": "Forest Warrior", "element": Character.Element.EARTH, "rarity": Character.Rarity.COMMON, "hp": 120, "attack": 22, "defense": 18, "speed": 70},
			{"name": "Fire Mage", "element": Character.Element.FIRE, "rarity": Character.Rarity.RARE, "hp": 90, "attack": 35, "defense": 12, "speed": 85},
			{"name": "Water Healer", "element": Character.Element.WATER, "rarity": Character.Rarity.RARE, "hp": 110, "attack": 18, "defense": 20, "speed": 80},
			{"name": "Radiant Knight", "element": Character.Element.RADIANT, "rarity": Character.Rarity.EPIC, "hp": 150, "attack": 28, "defense": 25, "speed": 65},
			{"name": "Void Assassin", "element": Character.Element.VOID, "rarity": Character.Rarity.EPIC, "hp": 85, "attack": 40, "defense": 10, "speed": 95},
			{"name": "Ancient Dragon", "element": Character.Element.FIRE, "rarity": Character.Rarity.LEGENDARY, "hp": 200, "attack": 45, "defense": 30, "speed": 75},
			{"name": "Lightning Archer", "element": Character.Element.RADIANT, "rarity": Character.Rarity.RARE, "hp": 95, "attack": 32, "defense": 15, "speed": 90},
			{"name": "Earth Guardian", "element": Character.Element.EARTH, "rarity": Character.Rarity.EPIC, "hp": 180, "attack": 20, "defense": 35, "speed": 55},
			{"name": "Shadow Mage", "element": Character.Element.VOID, "rarity": Character.Rarity.RARE, "hp": 85, "attack": 38, "defense": 12, "speed": 88},
			{"name": "Frost Warrior", "element": Character.Element.WATER, "rarity": Character.Rarity.EPIC, "hp": 135, "attack": 30, "defense": 22, "speed": 72}
		]
		
		for i in range(character_data.size()):
			var data = character_data[i]
			var character = Character.new()
			
			var level = randi_range(1, 5)
			character.setup(
				data.name,
				level,
				data.rarity,
				data.element,
				data.hp + (level - 1) * 8,
				data.attack + (level - 1) * 3,
				data.defense + (level - 1) * 2,
				data.speed + (level - 1) * 1,
				0.15 + randf() * 0.1,
				1.5 + randf() * 0.3
			)
			
			var filename = data.name.to_snake_case() + "_lv" + str(level) + ".tres"
			_save_character(character, path + filename)
	
	func _save_character(character: Character, file_path: String) -> bool:
		var result = ResourceSaver.save(character, file_path)
		
		if result == OK:
			print("✓ Guardado: ", character.character_name, " en ", file_path.get_file())
			return true
		else:
			print("✗ Error guardando: ", character.character_name, " - Error: ", result)
			return false
