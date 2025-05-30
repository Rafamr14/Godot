# ==== CHAPTER SYSTEM CORREGIDO (ChapterSystem.gd) ====
class_name ChapterSystem
extends Node

signal chapter_completed(chapter_data)
signal stage_completed(stage_data, rewards)

var game_manager: GameManager
var chapters: Array[ChapterData] = []
var current_chapter: int = 1
var current_stage: int = 1

func _ready():
	await get_tree().process_frame
	game_manager = get_parent().get_node("GameManager")
	_initialize_chapters()

func _initialize_chapters():
	# Capítulo 1: Forest of Beginnings
	var chapter1 = ChapterData.new()
	chapter1.setup(1, "Forest of Beginnings", "A peaceful forest where your journey begins", 10)
	
	# Stages del capítulo 1
	for i in range(1, 11):
		var stage = StageData.new()
		var enemies = _get_stage_enemies(1, i)
		var rewards = _get_stage_rewards(1, i)
		stage.setup(i, "Stage " + str(i), enemies, rewards)
		chapter1.stages.append(stage)
	
	chapters.append(chapter1)
	
	# Capítulo 2: Burning Desert
	var chapter2 = ChapterData.new()
	chapter2.setup(2, "Burning Desert", "A harsh desert filled with fire creatures", 12)
	
	for i in range(1, 13):
		var stage = StageData.new()
		var enemies = _get_stage_enemies(2, i)
		var rewards = _get_stage_rewards(2, i)
		stage.setup(i, "Desert " + str(i), enemies, rewards)
		chapter2.stages.append(stage)
	
	chapters.append(chapter2)
	
	# Capítulo 3: Crystal Caves
	var chapter3 = ChapterData.new()
	chapter3.setup(3, "Crystal Caves", "Mysterious caves with earth and void creatures", 15)
	
	for i in range(1, 16):
		var stage = StageData.new()
		var enemies = _get_stage_enemies(3, i)
		var rewards = _get_stage_rewards(3, i)
		stage.setup(i, "Cave " + str(i), enemies, rewards)
		chapter3.stages.append(stage)
	
	chapters.append(chapter3)

func _get_stage_enemies(chapter: int, stage: int) -> Array[Character]:
	var enemies: Array[Character] = []
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
				
				if stage >= 7:
					var archer = Character.new()
					archer.setup("Orc Archer", enemy_level, Character.Rarity.RARE, Character.Element.EARTH, 80 + stage * 10, 22 + stage * 3, 6 + stage, 90)
					archer.character_type = Character.CharacterType.ENEMY
					enemies.append(archer)
			
			else:
				# Boss stage
				var boss = Character.new()
				boss.setup("Ancient Treant", enemy_level + 1, Character.Rarity.EPIC, Character.Element.EARTH, 250 + stage * 20, 25 + stage * 4, 20 + stage * 3, 70, 0.2, 1.6)
				boss.character_type = Character.CharacterType.ENEMY
				enemies.append(boss)
				
				# Boss minions
				var minion1 = Character.new()
				minion1.setup("Tree Guardian", enemy_level, Character.Rarity.RARE, Character.Element.EARTH, 120, 18, 15, 60)
				minion1.character_type = Character.CharacterType.ENEMY
				enemies.append(minion1)
		
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
				
				var desert_lord = Character.new()
				desert_lord.setup("Desert Lord", enemy_level, Character.Rarity.RARE, Character.Element.EARTH, 160 + stage * 20, 20 + stage * 3, 15 + stage * 3, 65)
				desert_lord.character_type = Character.CharacterType.ENEMY
				enemies.append(desert_lord)
			
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
				
				if stage >= 4:
					var void_wraith = Character.new()
					void_wraith.setup("Void Wraith", enemy_level, Character.Rarity.RARE, Character.Element.VOID, 90 + stage * 15, 25 + stage * 4, 8 + stage, 95)
					void_wraith.character_type = Character.CharacterType.ENEMY
					enemies.append(void_wraith)
			
			elif stage <= 14:
				var shadow_knight = Character.new()
				shadow_knight.setup("Shadow Knight", enemy_level, Character.Rarity.EPIC, Character.Element.VOID, 180 + stage * 25, 28 + stage * 4, 18 + stage * 3, 75)
				shadow_knight.character_type = Character.CharacterType.ENEMY
				enemies.append(shadow_knight)
				
				var radiant_guardian = Character.new()
				radiant_guardian.setup("Radiant Guardian", enemy_level, Character.Rarity.EPIC, Character.Element.RADIANT, 200 + stage * 30, 25 + stage * 4, 22 + stage * 4, 70)
				radiant_guardian.character_type = Character.CharacterType.ENEMY
				enemies.append(radiant_guardian)
			
			else:
				# Final Boss
				var boss = Character.new()
				boss.setup("Void Emperor", enemy_level + 3, Character.Rarity.LEGENDARY, Character.Element.VOID, 600 + stage * 40, 40 + stage * 6, 30 + stage * 5, 90, 0.3, 2.0)
				boss.character_type = Character.CharacterType.ENEMY
				enemies.append(boss)
	
	return enemies

func _get_stage_rewards(chapter: int, stage: int) -> StageRewards:
	var rewards = StageRewards.new()
	
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
	if stage == get_chapter_data(chapter).max_stages:
		rewards.gold *= 2
		rewards.experience *= 2
		rewards.guaranteed_character = _generate_boss_reward_character(chapter)
	
	return rewards

func _generate_random_equipment(chapter: int) -> Equipment:
	var equipment = Equipment.new()
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
	
	return character

func get_chapter_data(chapter_id: int) -> ChapterData:
	if chapter_id > 0 and chapter_id <= chapters.size():
		return chapters[chapter_id - 1]
	return null

func is_stage_unlocked(chapter_id: int, stage_id: int) -> bool:
	if chapter_id == 1 and stage_id == 1:
		return true  # First stage always unlocked
	
	if chapter_id == current_chapter:
		return stage_id <= current_stage
	
	return chapter_id < current_chapter

func complete_stage(chapter_id: int, stage_id: int) -> StageRewards:
	var chapter_data = get_chapter_data(chapter_id)
	if chapter_data == null:
		return null
	
	var stage_data = chapter_data.get_stage(stage_id)
	if stage_data == null:
		return null
	
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
