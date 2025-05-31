# ==== DATA FOLDER GENERATOR (DataFolderGenerator.gd) ====
# Script para generar archivos de personajes en la carpeta Data
# Puedes ejecutar esto desde el editor para crear archivos de ejemplo

@tool
extends EditorScript

func _run():
	print("Generating character files in Data folder...")
	_generate_character_files()

func _generate_character_files():
	var data_path = "res://Data/"
	
	# Crear carpeta Data si no existe
	if not DirAccess.dir_exists_absolute(data_path):
		var dir_access = DirAccess.open("res://")
		if dir_access:
			dir_access.make_dir("Data")
			print("Created Data folder")
	
	# Generar personajes de ejemplo
	_create_radiant_warrior(data_path)
	_create_void_mage(data_path)
	_create_water_priestess(data_path)
	_create_fire_berserker(data_path)
	_create_earth_guardian(data_path)
	_create_wind_archer(data_path)
	_create_dragon_lord(data_path)
	_create_shadow_assassin(data_path)
	
	print("Character generation complete!")

func _create_radiant_warrior(data_path: String):
	var character = Character.new()
	character.setup("Radiant Warrior", 2, Character.Rarity.RARE, Character.Element.RADIANT, 140, 28, 22, 75, 0.18, 1.6)
	
	var result = ResourceSaver.save(character, data_path + "radiant_warrior.tres")
	if result == OK:
		print("✓ Created: radiant_warrior.tres")
	else:
		print("✗ Failed to create radiant_warrior.tres")

func _create_void_mage(data_path: String):
	var character = Character.new()
	character.setup("Void Mage", 3, Character.Rarity.EPIC, Character.Element.VOID, 95, 38, 15, 88, 0.25, 1.8)
	
	var result = ResourceSaver.save(character, data_path + "void_mage.tres")
	if result == OK:
		print("✓ Created: void_mage.tres")

func _create_water_priestess(data_path: String):
	var character = Character.new()
	character.setup("Water Priestess", 2, Character.Rarity.RARE, Character.Element.WATER, 115, 22, 18, 82, 0.12, 1.4)
	
	var result = ResourceSaver.save(character, data_path + "water_priestess.tres")
	if result == OK:
		print("✓ Created: water_priestess.tres")

func _create_fire_berserker(data_path: String):
	var character = Character.new()
	character.setup("Fire Berserker", 4, Character.Rarity.EPIC, Character.Element.FIRE, 105, 45, 12, 95, 0.30, 1.9)
	
	var result = ResourceSaver.save(character, data_path + "fire_berserker.tres")
	if result == OK:
		print("✓ Created: fire_berserker.tres")

func _create_earth_guardian(data_path: String):
	var character = Character.new()
	character.setup("Earth Guardian", 3, Character.Rarity.RARE, Character.Element.EARTH, 180, 18, 35, 55, 0.08, 1.3)
	
	var result = ResourceSaver.save(character, data_path + "earth_guardian.tres")
	if result == OK:
		print("✓ Created: earth_guardian.tres")

func _create_wind_archer(data_path: String):
	var character = Character.new()
	character.setup("Wind Archer", 3, Character.Rarity.EPIC, Character.Element.RADIANT, 90, 35, 12, 110, 0.28, 1.7)
	
	var result = ResourceSaver.save(character, data_path + "wind_archer.tres")
	if result == OK:
		print("✓ Created: wind_archer.tres")

func _create_dragon_lord(data_path: String):
	var character = Character.new()
	character.setup("Ancient Dragon", 5, Character.Rarity.LEGENDARY, Character.Element.FIRE, 250, 50, 30, 80, 0.25, 2.0)
	
	var result = ResourceSaver.save(character, data_path + "ancient_dragon.tres")
	if result == OK:
		print("✓ Created: ancient_dragon.tres")

func _create_shadow_assassin(data_path: String):
	var character = Character.new()
	character.setup("Shadow Assassin", 4, Character.Rarity.LEGENDARY, Character.Element.VOID, 85, 48, 8, 125, 0.35, 2.1)
	
	var result = ResourceSaver.save(character, data_path + "shadow_assassin.tres")
	if result == OK:
		print("✓ Created: shadow_assassin.tres")
