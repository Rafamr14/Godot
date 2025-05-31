# ==== CHAPTER SYSTEM CORREGIDO (ChapterSystem.gd) ====
class_name ChapterSystem
extends Node

signal chapter_completed(chapter_data)
signal stage_completed(stage_data, rewards)

var game_manager: GameManager
var chapters: Array = []  # Array de ChapterData
var current_chapter: int = 1
var current_stage: int = 1

func _ready():
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	_find_game_manager()
	_initialize_chapters()

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
		print("ChapterSystem: GameManager encontrado")
	else:
		print("ChapterSystem: GameManager no encontrado, algunas funciones limitadas")

func _initialize_chapters():
	print("ChapterSystem: Inicializando capítulos...")
	chapters.clear()
	
	# Verificar que las clases necesarias existen
	if not _verify_dependencies():
		print("ChapterSystem: Dependencias faltantes, creando capítulos básicos")
		_create_basic_chapters()
		return
	
	# Intentar crear capítulos normales
	var success = _create_normal_chapters()
	if not success:
		print("ChapterSystem: Error durante inicialización, creando capítulos básicos")
		_create_basic_chapters()

func _create_normal_chapters() -> bool:
	"""Crear capítulos normales usando ChapterData"""
	# Verificar que ChapterData existe
	var chapter_data_class = load("res://Scripts/ChapterData.gd")
	if not chapter_data_class:
		return false
	
	# Capítulo 1: Forest of Beginnings
	var chapter1 = ChapterData.new()
	if not chapter1:
		return false
	
	chapter1.setup(1, "Forest of Beginnings", "A peaceful forest where your journey begins", 10)
	_create_chapter_stages(chapter1)
	chapters.append(chapter1)
	
	# Capítulo 2: Burning Desert
	var chapter2 = ChapterData.new()
	if not chapter2:
		return false
	
	chapter2.setup(2, "Burning Desert", "A harsh desert filled with fire creatures", 12)
	_create_chapter_stages(chapter2)
	chapters.append(chapter2)
	
	# Capítulo 3: Crystal Caves
	var chapter3 = ChapterData.new()
	if not chapter3:
		return false
	
	chapter3.setup(3, "Crystal Caves", "Mysterious caves with earth and void creatures", 15)
	_create_chapter_stages(chapter3)
	chapters.append(chapter3)
	
	print("ChapterSystem: Creados ", chapters.size(), " capítulos exitosamente")
	return true

func _verify_dependencies() -> bool:
	# Verificar que las clases necesarias existen
	var chapter_data_script = load("res://Scripts/ChapterData.gd")
	var stage_data_script = load("res://Scripts/StageData.gd")
	var stage_rewards_script = load("res://Scripts/StageRewards.gd")
	
	return chapter_data_script != null and stage_data_script != null and stage_rewards_script != null

func _create_basic_chapters():
	"""Crear capítulos básicos sin dependencias externas"""
	print("ChapterSystem: Creando capítulos básicos...")
	
	# Capítulo básico 1
	var basic_chapter = {
		"chapter_id": 1,
		"chapter_name": "Beginning Forest",
		"description": "Start your adventure here",
		"max_stages": 5,
		"stages": [],
		"completed": false
	}
	
	# Crear stages básicos
	for i in range(1, 6):
		var basic_stage = {
			"stage_id": i,
			"stage_name": "Stage " + str(i),
			"enemies": _create_basic_enemies(1, i),
			"rewards": _create_basic_rewards(1, i),
			"completed": false,
			"stars": 0
		}
		basic_chapter.stages.append(basic_stage)
	
	chapters.append(basic_chapter)
	print("ChapterSystem: Capítulo básico creado con ", basic_chapter.stages.size(), " stages")

func _create_chapter_stages(chapter: ChapterData):
	"""Crear stages para un capítulo específico"""
	if not chapter:
		print("ChapterSystem: Error - chapter es null")
		return
	
	# Verificar que StageData existe
	var stage_data_class = load("res://Scripts/StageData.gd")
	if not stage_data_class:
		print("ChapterSystem: StageData no disponible, usando stages básicos")
		_create_basic_stages_for_chapter(chapter)
		return
	
	chapter.stages.clear()
	
	for i in range(1, chapter.max_stages + 1):
		var stage = StageData.new()
		if not stage:
			continue
			
		var enemies = _get_stage_enemies(chapter.chapter_id, i)
		var rewards = _get_stage_rewards(chapter.chapter_id, i)
		
		# Ahora que StageData usa Array genérico, esto debería funcionar
		stage.setup(i, "Stage " + str(i), enemies, rewards)
		chapter.stages.append(stage)

func _create_basic_stages_for_chapter(chapter: ChapterData):
	"""Crear stages básicos cuando StageData no está disponible"""
	chapter.stages.clear()
	
	for i in range(1, chapter.max_stages + 1):
		var basic_stage = {
			"stage_id": i,
			"stage_name": "Stage " + str(i),
			"enemies": _create_basic_enemies(chapter.chapter_id, i),
			"rewards": _create_basic_rewards(chapter.chapter_id, i),
			"completed": false,
			"stars": 0
		}
		chapter.stages.append(basic_stage)

func _get_stage_enemies(chapter: int, stage: int) -> Array:
	"""Crear enemigos para un stage específico"""
	var enemies: Array = []
	var enemy_level = chapter + int(stage / 3)
	
	match chapter:
		1:  # Forest Chapter
			if stage <= 5:
				# Early stages: 1-2 weak enemies
				var goblin = Character.new()
				goblin.setup("Forest Goblin", enemy_level, Character.Rarity.COMMON, Character.Element.EARTH, 80 + stage * 10, 12 + stage * 2, 8 + stage, 70)
				goblin.character_type = Character.CharacterType.ENEMY
				enemies.append(goblin)
				
				if stage >= 3:
					var wolf = Character.new()
					wolf.setup("Forest Wolf", enemy_level, Character.Rarity.COMMON, Character.Element.EARTH, 60 + stage * 8, 15 + stage * 2, 5 + stage, 85)
					wolf.character_type = Character.CharacterType.ENEMY
					enemies.append(wolf)
			
			elif stage <= 9:
				# Mid stages: 2-3 enemies
				var orc = Character.new()
				orc.setup("Forest Orc", enemy_level, Character.Rarity.RARE, Character.Element.EARTH, 120 + stage * 15, 18 + stage * 3, 12 + stage * 2, 65)
				orc.character_type = Character.CharacterType.ENEMY
				enemies.append(orc)
				
				var shaman = Character.new()
				shaman.setup("Goblin Shaman", enemy_level, Character.Rarity.RARE, Character.Element.RADIANT, 90 + stage * 12, 20 + stage * 3, 8 + stage, 75)
				shaman.character_type = Character.CharacterType.ENEMY
				enemies.append(shaman)
			
			else:
				# Boss stage
				var boss = Character.new()
				boss.setup("Ancient Treant", enemy_level + 1, Character.Rarity.EPIC, Character.Element.EARTH, 250 + stage * 20, 25 + stage * 4, 20 + stage * 3, 70, 0.2, 1.6)
				boss.character_type = Character.CharacterType.ENEMY
				enemies.append(boss)
		
		2:  # Desert Chapter
			if stage <= 6:
				var fire_spirit = Character.new()
				fire_spirit.setup("Fire Spirit", enemy_level, Character.Rarity.COMMON, Character.Element.FIRE, 70 + stage * 12, 16 + stage * 3, 6 + stage, 85)
				fire_spirit.character_type = Character.CharacterType.ENEMY
				enemies.append(fire_spirit)
				
				if stage >= 3:
					var sand_worm = Character.new()
					sand_worm.setup("Sand Worm", enemy_level, Character.Rarity.COMMON, Character.Element.EARTH, 100 + stage * 15, 14 + stage * 2, 10 + stage * 2, 50)
					sand_worm.character_type = Character.CharacterType.ENEMY
					enemies.append(sand_worm)
			
			elif stage <= 11:
				var flame_djinn = Character.new()
				flame_djinn.setup("Flame Djinn", enemy_level, Character.Rarity.RARE, Character.Element.FIRE, 140 + stage * 18, 22 + stage * 4, 10 + stage * 2, 80)
				flame_djinn.character_type = Character.CharacterType.ENEMY
				enemies.append(flame_djinn)
			
			else:
				# Boss stage
				var boss = Character.new()
				boss.setup("Inferno Dragon", enemy_level + 2, Character.Rarity.LEGENDARY, Character.Element.FIRE, 400 + stage * 30, 35 + stage * 5, 25 + stage * 4, 85, 0.25, 1.8)
				boss.character_type = Character.CharacterType.ENEMY
				enemies.append(boss)
		
		3:  # Crystal Caves Chapter
			if stage <= 7:
				var crystal_golem = Character.new()
				crystal_golem.setup("Crystal Golem", enemy_level, Character.Rarity.RARE, Character.Element.EARTH, 120 + stage * 20, 18 + stage * 3, 20 + stage * 3, 40)
				crystal_golem.character_type = Character.CharacterType.ENEMY
				enemies.append(crystal_golem)
			
			elif stage <= 14:
				var shadow_knight = Character.new()
				shadow_knight.setup("Shadow Knight", enemy_level, Character.Rarity.EPIC, Character.Element.VOID, 180 + stage * 25, 28 + stage * 4, 18 + stage * 3, 75)
				shadow_knight.character_type = Character.CharacterType.ENEMY
				enemies.append(shadow_knight)
			
			else:
				# Final Boss
				var boss = Character.new()
				boss.setup("Void Emperor", enemy_level + 3, Character.Rarity.LEGENDARY, Character.Element.VOID, 600 + stage * 40, 40 + stage * 6, 30 + stage * 5, 90, 0.3, 2.0)
				boss.character_type = Character.CharacterType.ENEMY
				enemies.append(boss)
	
	# Asegurar que siempre hay al menos un enemigo
	if enemies.is_empty():
		var default_enemy = Character.new()
		default_enemy.setup("Default Enemy", enemy_level, Character.Rarity.COMMON, Character.Element.EARTH, 100, 15, 10, 70)
		default_enemy.character_type = Character.CharacterType.ENEMY
		enemies.append(default_enemy)
	
	return enemies

func _create_basic_enemies(chapter: int, stage: int) -> Array:
	"""Crear enemigos básicos cuando no hay dependencias"""
	var enemies = []
	
	var basic_enemy = {
		"name": "Basic Enemy " + str(stage),
		"level": chapter + stage,
		"hp": 100 + stage * 20,
		"attack": 15 + stage * 3,
		"defense": 10 + stage * 2,
		"speed": 70
	}
	
	enemies.append(basic_enemy)
	return enemies

func _get_stage_rewards(chapter: int, stage: int) -> StageRewards:
	"""Crear recompensas para un stage específico"""
	
	# Verificar que StageRewards existe
	var stage_rewards_class = load("res://Scripts/StageRewards.gd")
	if not stage_rewards_class:
		print("ChapterSystem: StageRewards no disponible, usando recompensas básicas")
		return null
	
	var rewards = StageRewards.new()
	if not rewards:
		return null
	
	# Base rewards
	rewards.experience = 50 + chapter * 20 + stage * 10
	rewards.gold = 100 + chapter * 50 + stage * 25
	
	# Equipment chance increases with chapter
	if randf() < 0.1 + chapter * 0.05:
		rewards.equipment = _generate_random_equipment(chapter)
	
	# Character summon tickets
	if stage % 5 == 0:  # Every 5th stage
		rewards.summon_tickets = 1
		if stage % 10 == 0:  # Every 10th stage (boss)
			rewards.summon_tickets = 3
	
	# Boss rewards
	var chapter_data = get_chapter_data(chapter)
	if chapter_data and stage == chapter_data.max_stages:
		rewards.gold *= 2
		rewards.experience *= 2
		rewards.guaranteed_character = _generate_boss_reward_character(chapter)
	
	return rewards

func _create_basic_rewards(chapter: int, stage: int) -> Dictionary:
	"""Crear recompensas básicas cuando no hay dependencias"""
	return {
		"experience": 50 + chapter * 20 + stage * 10,
		"gold": 100 + chapter * 50 + stage * 25,
		"summon_tickets": 1 if stage % 5 == 0 else 0
	}

func _generate_random_equipment(chapter: int) -> Equipment:
	"""Generar equipment aleatorio"""
	
	# Verificar que Equipment existe
	var equipment_class = load("res://Scripts/Equipment.gd")
	if not equipment_class:
		print("ChapterSystem: Equipment no disponible")
		return null
		
	var equipment = Equipment.new()
	if not equipment:
		return null
	
	var equipment_types = [Equipment.EquipmentType.WEAPON, Equipment.EquipmentType.ARMOR, Equipment.EquipmentType.BOOTS, Equipment.EquipmentType.ACCESSORY]
	var type = equipment_types[randi() % equipment_types.size()]
	var rarity = Equipment.EquipmentRarity.COMMON
	
	if randf() < 0.3:
		rarity = Equipment.EquipmentRarity.RARE
	elif randf() < 0.1:
		rarity = Equipment.EquipmentRarity.EPIC
	
	var name = "Chapter " + str(chapter) + " " + Equipment.EquipmentType.keys()[type]
	equipment.setup(name, type, rarity, chapter)
	
	return equipment

func _generate_boss_reward_character(chapter: int) -> Character:
	"""Generar personaje de recompensa por boss"""
	var character = Character.new()
	var rarity = Character.Rarity.RARE
	if chapter >= 3:
		rarity = Character.Rarity.EPIC
	
	match chapter:
		1:
			character.setup("Forest Guardian", 1, rarity, Character.Element.EARTH, 150, 25, 20, 75, 0.2, 1.6)
		2:
			character.setup("Phoenix Warrior", 1, rarity, Character.Element.FIRE, 140, 30, 18, 80, 0.25, 1.7)
		3:
			character.setup("Void Mage", 1, rarity, Character.Element.VOID, 130, 35, 15, 85, 0.3, 1.8)
		_:
			character.setup("Legendary Hero", 1, rarity, Character.Element.RADIANT, 160, 32, 22, 78, 0.22, 1.65)
	
	return character

func get_chapter_data(chapter_id: int) -> ChapterData:
	"""Obtener datos de capítulo por ID - CON VERIFICACIÓN DE NULL"""
	if chapter_id <= 0 or chapter_id > chapters.size():
		print("ChapterSystem: Invalid chapter_id: ", chapter_id)
		return null
	
	var chapter_data = chapters[chapter_id - 1]
	
	# Verificar que el capítulo es válido
	if not chapter_data:
		print("ChapterSystem: Chapter data is null for chapter_id: ", chapter_id)
		return null
	
	# Si es un diccionario (capítulo básico), convertir a objeto simple
	if chapter_data is Dictionary:
		var basic_chapter = BasicChapterData.new()
		basic_chapter.setup_from_dict(chapter_data)
		return basic_chapter
	
	return chapter_data

func is_stage_unlocked(chapter_id: int, stage_id: int) -> bool:
	"""Verificar si un stage está desbloqueado - CON VERIFICACIÓN DE NULL"""
	if chapter_id == 1 and stage_id == 1:
		return true  # First stage always unlocked
	
	if chapter_id == current_chapter:
		return stage_id <= current_stage
	
	return chapter_id < current_chapter

func complete_stage(chapter_id: int, stage_id: int) -> StageRewards:
	"""Completar un stage - CON VERIFICACIÓN DE NULL"""
	var chapter_data = get_chapter_data(chapter_id)
	if not chapter_data:
		print("ChapterSystem: Cannot complete stage - chapter not found")
		return null
	
	var stage_data = chapter_data.get_stage(stage_id)
	if not stage_data:
		print("ChapterSystem: Cannot complete stage - stage not found")
		return null
	
	# Marcar como completado
	if stage_data is Dictionary:
		stage_data.completed = true
		var rewards_dict = stage_data.get("rewards", {})
		
		# Crear objeto StageRewards básico si la clase existe
		var stage_rewards_class = load("res://Scripts/StageRewards.gd")
		if stage_rewards_class:
			var stage_rewards = StageRewards.new()
			stage_rewards.experience = rewards_dict.get("experience", 0)
			stage_rewards.gold = rewards_dict.get("gold", 0)
			stage_rewards.summon_tickets = rewards_dict.get("summon_tickets", 0)
			return stage_rewards
		else:
			# Retornar null si no hay StageRewards disponible
			print("ChapterSystem: StageRewards no disponible, recompensas aplicadas directamente")
			if game_manager:
				game_manager.add_currency(rewards_dict.get("gold", 0))
				game_manager.add_experience(rewards_dict.get("experience", 0))
			return null
	else:
		stage_data.completed = true
		var rewards = stage_data.rewards
		
		# Unlock next stage
		if chapter_id == current_chapter and stage_id == current_stage:
			if stage_id < chapter_data.max_stages:
				current_stage += 1
			elif chapter_id < chapters.size():
				current_chapter += 1
				current_stage = 1
		
		stage_completed.emit(stage_data, rewards)
		
		# Check if chapter completed
		if stage_id == chapter_data.max_stages:
			chapter_completed.emit(chapter_data)
		
		return rewards

# Clase auxiliar para capítulos básicos
class BasicChapterData:
	var chapter_id: int
	var chapter_name: String
	var description: String
	var max_stages: int
	var stages: Array = []
	var completed: bool = false
	
	func setup_from_dict(data: Dictionary):
		chapter_id = data.get("chapter_id", 0)
		chapter_name = data.get("chapter_name", "Unknown Chapter")
		description = data.get("description", "No description")
		max_stages = data.get("max_stages", 1)
		stages = data.get("stages", [])
		completed = data.get("completed", false)
	
	func get_stage(stage_id: int):
		if stage_id > 0 and stage_id <= stages.size():
			return stages[stage_id - 1]
		return null
