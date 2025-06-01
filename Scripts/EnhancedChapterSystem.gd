# ==== ENHANCED CHAPTER SYSTEM ====
class_name EnhancedChapterSystem
extends Node

signal chapter_completed(chapter_data)
signal stage_completed(stage_data, rewards)
signal battle_victory(chapter_id, stage_id, rewards)
signal battle_defeat(chapter_id, stage_id)

var game_manager: GameManager
var chapters: Array[ChapterData] = []
var current_chapter: int = 1
var current_stage: int = 1

# Progreso del jugador
var unlocked_chapters: Array[int] = [1]  # Capítulo 1 siempre desbloqueado
var completed_stages: Dictionary = {}  # "chapter_id:stage_id" -> true

func _ready():
	await get_tree().process_frame
	_find_game_manager()
	_initialize_enhanced_chapters()
	_load_progress()

func _find_game_manager():
	# Buscar GameManager
	game_manager = get_parent().get_node_or_null("GameManager")
	
	if not game_manager:
		game_manager = get_tree().get_first_node_in_group("game_manager")
	
	if not game_manager:
		for node in get_tree().current_scene.get_children():
			if node.get_script() and node.get_script().get_global_name() == "GameManager":
				game_manager = node
				break
	
	if game_manager:
		print("EnhancedChapterSystem: GameManager encontrado")
	else:
		print("EnhancedChapterSystem: GameManager no encontrado")

func _initialize_enhanced_chapters():
	"""Inicializar capítulos con contenido épico"""
	print("EnhancedChapterSystem: Creando capítulos épicos...")
	chapters.clear()
	
	_create_chapter_forest_beginnings()
	_create_chapter_burning_desert()
	_create_chapter_crystal_caverns()
	_create_chapter_frozen_peaks()
	_create_chapter_shadow_realm()
	
	print("EnhancedChapterSystem: ", chapters.size(), " capítulos creados")

func _create_chapter_forest_beginnings():
	"""Capítulo 1: Forest of Beginnings - Tutorial y primeras batallas"""
	var chapter = ChapterData.new()
	chapter.setup(1, "Forest of Beginnings", "A mystical forest where heroes are born. Face goblins, wolves, and the ancient Forest Guardian.", 5)
	
	# Stage 1-1: First Steps
	var stage1 = _create_stage_data(1, "Goblin Scout", 
		"Your first battle! Defeat a lone goblin scout.", 
		[_create_goblin_scout()], 
		_create_rewards(75, 100, 0))
	
	# Stage 1-2: Forest Patrol
	var stage2 = _create_stage_data(2, "Forest Patrol", 
		"Two goblins block your path. Show them your strength!", 
		[_create_goblin_scout(), _create_goblin_warrior()], 
		_create_rewards(100, 150, 0))
	
	# Stage 1-3: Wolf Pack
	var stage3 = _create_stage_data(3, "Wild Wolf Pack", 
		"A pack of forest wolves threatens the village!", 
		[_create_forest_wolf(), _create_forest_wolf()], 
		_create_rewards(125, 200, 1))
	
	# Stage 1-4: Goblin Camp
	var stage4 = _create_stage_data(4, "Goblin Encampment", 
		"Raid the goblin camp and face their elite warriors!", 
		[_create_goblin_warrior(), _create_goblin_shaman(), _create_goblin_scout()], 
		_create_rewards(150, 300, 1))
	
	# Stage 1-5: BOSS - Forest Guardian
	var stage5 = _create_stage_data(5, "Ancient Forest Guardian", 
		"The mighty Forest Guardian awakens! This is your first true test!", 
		[_create_forest_guardian_boss()], 
		_create_rewards(300, 500, 3))
	
	chapter.stages = [stage1, stage2, stage3, stage4, stage5]
	chapters.append(chapter)

func _create_chapter_burning_desert():
	"""Capítulo 2: Burning Desert - Elementos de fuego y calor"""
	var chapter = ChapterData.new()
	chapter.setup(2, "Burning Desert", "A scorching wasteland inhabited by fire elementals and desert nomads. The heat is merciless.", 6)
	
	# Stage 2-1: Desert Entrance
	var stage1 = _create_stage_data(1, "Desert Bandits", 
		"Desert bandits attack travelers at the oasis!", 
		[_create_desert_bandit(), _create_desert_bandit()], 
		_create_rewards(150, 250, 0))
	
	# Stage 2-2: Fire Spirits
	var stage2 = _create_stage_data(2, "Burning Spirits", 
		"Fire spirits emerge from the scorching sands!", 
		[_create_fire_spirit(), _create_fire_spirit(), _create_lesser_fire_elemental()], 
		_create_rewards(175, 300, 1))
	
	# Stage 2-3: Sandstorm Battle
	var stage3 = _create_stage_data(3, "Sandstorm Ambush", 
		"Fight through a raging sandstorm against desert predators!", 
		[_create_sand_worm(), _create_desert_scorpion()], 
		_create_rewards(200, 350, 1))
	
	# Stage 2-4: Flame Temple
	var stage4 = _create_stage_data(4, "Temple of Flames", 
		"Ancient fire guardians protect the sacred temple!", 
		[_create_flame_guardian(), _create_fire_spirit(), _create_fire_spirit()], 
		_create_rewards(225, 400, 1))
	
	# Stage 2-5: Elite Encounter
	var stage5 = _create_stage_data(5, "Fire Djinn's Trial", 
		"A powerful Fire Djinn challenges your worthiness!", 
		[_create_fire_djinn()], 
		_create_rewards(275, 450, 2))
	
	# Stage 2-6: BOSS - Inferno Dragon
	var stage6 = _create_stage_data(6, "Inferno Dragon", 
		"Face the legendary Inferno Dragon in his volcanic lair!", 
		[_create_inferno_dragon_boss()], 
		_create_rewards(500, 800, 5))
	
	chapter.stages = [stage1, stage2, stage3, stage4, stage5, stage6]
	chapters.append(chapter)

func _create_chapter_crystal_caverns():
	"""Capítulo 3: Crystal Caverns - Elementos de tierra y cristal"""
	var chapter = ChapterData.new()
	chapter.setup(3, "Crystal Caverns", "Deep underground caverns filled with magical crystals and ancient earth elementals.", 7)
	
	# Crear stages similares pero con temática de tierra/cristal
	var stages = []
	for i in range(7):
		var stage_id = i + 1
		var stage = _create_stage_data(stage_id, "Crystal Stage " + str(stage_id), 
			"A challenging crystal cavern stage.", 
			[_create_crystal_golem()], 
			_create_rewards(200 + i * 50, 300 + i * 100, i % 3))
		stages.append(stage)
	
	chapter.stages = stages
	chapters.append(chapter)

func _create_chapter_frozen_peaks():
	"""Capítulo 4: Frozen Peaks - Elementos de agua/hielo"""
	var chapter = ChapterData.new()
	chapter.setup(4, "Frozen Peaks", "Treacherous mountain peaks where ice elementals and frost giants roam.", 8)
	
	var stages = []
	for i in range(8):
		var stage_id = i + 1
		var stage = _create_stage_data(stage_id, "Frozen Stage " + str(stage_id), 
			"A freezing mountain challenge.", 
			[_create_ice_elemental()], 
			_create_rewards(300 + i * 75, 400 + i * 125, i % 4))
		stages.append(stage)
	
	chapter.stages = stages
	chapters.append(chapter)

func _create_chapter_shadow_realm():
	"""Capítulo 5: Shadow Realm - Elementos de vacío y oscuridad"""
	var chapter = ChapterData.new()
	chapter.setup(5, "Shadow Realm", "The final frontier. A realm of darkness where the Void Emperor awaits.", 10)
	
	var stages = []
	for i in range(10):
		var stage_id = i + 1
		var is_boss = stage_id == 10
		var enemy = _create_void_emperor_boss() if is_boss else _create_shadow_knight()
		var stage = _create_stage_data(stage_id, "Shadow Stage " + str(stage_id), 
			"Face the ultimate darkness.", 
			[enemy], 
			_create_rewards(500 + i * 100, 600 + i * 150, i if is_boss else i % 3))
		stages.append(stage)
	
	chapter.stages = stages
	chapters.append(chapter)

# ==== CREACIÓN DE STAGES ====
func _create_stage_data(stage_id: int, name: String, description: String, enemies: Array, rewards: StageRewards) -> StageData:
	"""Crear datos de stage"""
	var stage = StageData.new()
	stage.stage_id = stage_id
	stage.stage_name = name
	stage.enemies = enemies
	stage.rewards = rewards
	stage.completed = false
	stage.stars = 0
	return stage

func _create_rewards(exp: int, gold: int, tickets: int) -> StageRewards:
	"""Crear recompensas de stage"""
	var rewards = StageRewards.new()
	rewards.experience = exp
	rewards.gold = gold
	rewards.summon_tickets = tickets
	return rewards

# ==== CREACIÓN DE ENEMIGOS ====
func _create_goblin_scout() -> Character:
	var enemy = Character.new()
	enemy.setup("Goblin Scout", 1, Character.Rarity.COMMON, Character.Element.EARTH, 80, 15, 8, 75, 0.1, 1.4)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_goblin_warrior() -> Character:
	var enemy = Character.new()
	enemy.setup("Goblin Warrior", 2, Character.Rarity.COMMON, Character.Element.EARTH, 110, 20, 12, 65, 0.12, 1.5)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_goblin_shaman() -> Character:
	var enemy = Character.new()
	enemy.setup("Goblin Shaman", 2, Character.Rarity.RARE, Character.Element.RADIANT, 90, 25, 10, 70, 0.15, 1.6)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_forest_wolf() -> Character:
	var enemy = Character.new()
	enemy.setup("Forest Wolf", 2, Character.Rarity.COMMON, Character.Element.EARTH, 95, 22, 8, 85, 0.18, 1.6)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_forest_guardian_boss() -> Character:
	var boss = Character.new()
	boss.setup("Ancient Forest Guardian", 5, Character.Rarity.EPIC, Character.Element.EARTH, 300, 35, 25, 60, 0.15, 1.8)
	boss.character_type = Character.CharacterType.ENEMY
	return boss

func _create_desert_bandit() -> Character:
	var enemy = Character.new()
	enemy.setup("Desert Bandit", 3, Character.Rarity.COMMON, Character.Element.FIRE, 120, 25, 12, 80, 0.15, 1.5)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_fire_spirit() -> Character:
	var enemy = Character.new()
	enemy.setup("Fire Spirit", 3, Character.Rarity.RARE, Character.Element.FIRE, 100, 30, 8, 90, 0.20, 1.7)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_lesser_fire_elemental() -> Character:
	var enemy = Character.new()
	enemy.setup("Lesser Fire Elemental", 4, Character.Rarity.RARE, Character.Element.FIRE, 140, 28, 15, 75, 0.15, 1.6)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_sand_worm() -> Character:
	var enemy = Character.new()
	enemy.setup("Sand Worm", 4, Character.Rarity.RARE, Character.Element.EARTH, 180, 32, 20, 50, 0.10, 1.5)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_desert_scorpion() -> Character:
	var enemy = Character.new()
	enemy.setup("Desert Scorpion", 3, Character.Rarity.COMMON, Character.Element.FIRE, 110, 28, 12, 85, 0.25, 1.8)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_flame_guardian() -> Character:
	var enemy = Character.new()
	enemy.setup("Flame Guardian", 5, Character.Rarity.EPIC, Character.Element.FIRE, 200, 35, 22, 70, 0.18, 1.7)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_fire_djinn() -> Character:
	var enemy = Character.new()
	enemy.setup("Fire Djinn", 6, Character.Rarity.EPIC, Character.Element.FIRE, 250, 40, 18, 85, 0.22, 1.9)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_inferno_dragon_boss() -> Character:
	var boss = Character.new()
	boss.setup("Inferno Dragon", 8, Character.Rarity.LEGENDARY, Character.Element.FIRE, 500, 55, 30, 75, 0.20, 2.0)
	boss.character_type = Character.CharacterType.ENEMY
	return boss

func _create_crystal_golem() -> Character:
	var enemy = Character.new()
	enemy.setup("Crystal Golem", 6, Character.Rarity.EPIC, Character.Element.EARTH, 220, 30, 35, 45, 0.10, 1.5)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_ice_elemental() -> Character:
	var enemy = Character.new()
	enemy.setup("Ice Elemental", 7, Character.Rarity.EPIC, Character.Element.WATER, 190, 38, 20, 80, 0.18, 1.7)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_shadow_knight() -> Character:
	var enemy = Character.new()
	enemy.setup("Shadow Knight", 9, Character.Rarity.EPIC, Character.Element.VOID, 280, 45, 25, 85, 0.25, 1.9)
	enemy.character_type = Character.CharacterType.ENEMY
	return enemy

func _create_void_emperor_boss() -> Character:
	var boss = Character.new()
	boss.setup("Void Emperor", 15, Character.Rarity.LEGENDARY, Character.Element.VOID, 800, 70, 40, 90, 0.30, 2.2)
	boss.character_type = Character.CharacterType.ENEMY
	return boss

# ==== GESTIÓN DE PROGRESO ====
func is_stage_unlocked(chapter_id: int, stage_id: int) -> bool:
	"""Verificar si un stage está desbloqueado"""
	# Capítulo 1, Stage 1 siempre desbloqueado
	if chapter_id == 1 and stage_id == 1:
		return true
	
	# Verificar si el capítulo está desbloqueado
	if chapter_id not in unlocked_chapters:
		return false
	
	# Verificar progreso en el capítulo
	if chapter_id == current_chapter:
		return stage_id <= current_stage
	
	return chapter_id < current_chapter

func complete_stage(chapter_id: int, stage_id: int, victory: bool = true) -> StageRewards:
	"""Completar un stage y desbloquear el siguiente"""
	var chapter_data = get_chapter_data(chapter_id)
	if not chapter_data:
		print("EnhancedChapterSystem: Chapter not found")
		return null
	
	var stage_data = chapter_data.get_stage(stage_id)
	if not stage_data:
		print("EnhancedChapterSystem: Stage not found")
		return null
	
	if not victory:
		battle_defeat.emit(chapter_id, stage_id)
		return null
	
	# Marcar como completado
	stage_data.completed = true
	var stage_key = str(chapter_id) + ":" + str(stage_id)
	completed_stages[stage_key] = true
	
	# Desbloquear siguiente stage
	if chapter_id == current_chapter and stage_id == current_stage:
		if stage_id < chapter_data.max_stages:
			current_stage += 1
		elif chapter_id < chapters.size():
			current_chapter += 1
			current_stage = 1
			if current_chapter not in unlocked_chapters:
				unlocked_chapters.append(current_chapter)
	
	# Dar recompensas
	if game_manager and stage_data.rewards:
		game_manager.add_currency(stage_data.rewards.gold)
		game_manager.add_experience(stage_data.rewards.experience)
	
	# Emitir señales
	stage_completed.emit(stage_data, stage_data.rewards)
	battle_victory.emit(chapter_id, stage_id, stage_data.rewards)
	
	# Verificar si el capítulo se completó
	if stage_id == chapter_data.max_stages:
		chapter_completed.emit(chapter_data)
	
	_save_progress()
	return stage_data.rewards

func get_chapter_data(chapter_id: int) -> ChapterData:
	"""Obtener datos de capítulo por ID"""
	if chapter_id <= 0 or chapter_id > chapters.size():
		return null
	return chapters[chapter_id - 1]

func get_stage_data(chapter_id: int, stage_id: int):
	"""Obtener datos de stage específico"""
	var chapter_data = get_chapter_data(chapter_id)
	if not chapter_data:
		return null
	return chapter_data.get_stage(stage_id)

func _save_progress():
	"""Guardar progreso del jugador"""
	# Aquí podrías guardar en un archivo o PlayerPrefs
	# Por ahora mantenemos en memoria
	pass

func _load_progress():
	"""Cargar progreso del jugador"""
	# Aquí podrías cargar desde un archivo
	# Por ahora empezamos desde el principio
	pass

# ==== FUNCIONES DE UTILIDAD ====
func get_total_stages_completed() -> int:
	"""Obtener total de stages completados"""
	return completed_stages.size()

func get_chapter_completion_percentage(chapter_id: int) -> float:
	"""Obtener porcentaje de completado de un capítulo"""
	var chapter_data = get_chapter_data(chapter_id)
	if not chapter_data:
		return 0.0
	
	var completed = 0
	for i in range(chapter_data.max_stages):
		var stage_key = str(chapter_id) + ":" + str(i + 1)
		if stage_key in completed_stages:
			completed += 1
	
	return float(completed) / float(chapter_data.max_stages)

func get_recommended_power(chapter_id: int) -> int:
	"""Obtener poder recomendado para un capítulo"""
	return chapter_id * 300 + 200
