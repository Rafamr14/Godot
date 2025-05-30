class_name BattleSystem
extends Node

signal turn_started(character)
signal skill_used(caster, skill, targets, results)
signal battle_phase_changed(phase)

enum BattlePhase { PREPARATION, COMBAT, VICTORY, DEFEAT }

var game_manager: GameManager
var current_phase: BattlePhase = BattlePhase.PREPARATION
var turn_queue: Array[Character] = []
var turn_counter: int = 0

func _ready():
	await get_tree().process_frame
	game_manager = get_parent().get_node("GameManager")

func start_battle(player_team: Array[Character], enemy_team: Array[Character]):
	current_phase = BattlePhase.PREPARATION
	turn_counter = 0
	_setup_battle_queue(player_team, enemy_team)
	current_phase = BattlePhase.COMBAT
	battle_phase_changed.emit(current_phase)
	_process_turn_queue()

func _setup_battle_queue(player_team: Array[Character], enemy_team: Array[Character]):
	turn_queue.clear()
	var all_characters: Array[Character] = []
	all_characters.append_array(player_team)
	all_characters.append_array(enemy_team)
	
	# Resetear Combat Readiness
	for character in all_characters:
		character.reset_combat_readiness()
	
	# Calcular CR inicial basado en velocidad
	for character in all_characters:
		var initial_cr = (character.speed / 300.0) * 100.0
		character.add_combat_readiness(initial_cr)

func _process_turn_queue():
	if current_phase != BattlePhase.COMBAT:
		return
	
	# Encontrar personaje con mayor CR
	var next_character = _get_next_character()
	
	if next_character == null:
		_advance_all_cr()
		call_deferred("_process_turn_queue")
		return
	
	# Es el turno de este personaje
	next_character.reset_combat_readiness()
	_process_character_turn(next_character)

func _get_next_character() -> Character:
	var highest_cr = 0.0
	var next_char: Character = null
	
	for character in turn_queue:
		if character.is_alive() and character.combat_readiness >= 100.0:
			if character.combat_readiness > highest_cr:
				highest_cr = character.combat_readiness
				next_char = character
	
	return next_char

func _advance_all_cr():
	# Avanzar CR de todos los personajes vivos
	for character in turn_queue:
		if character.is_alive():
			var cr_gain = (character.speed / 300.0) * 10.0
			character.add_combat_readiness(cr_gain)

func _process_character_turn(character: Character):
	turn_started.emit(character)
	
	# Procesar efectos de estado al inicio del turno
	character.process_status_effects()
	
	# Reducir cooldowns
	for skill in character.skills:
		skill.reduce_cooldown()
	
	# Verificar si está aturdido, dormido, etc.
	if _is_character_disabled(character):
		print(character.character_name + " is disabled, skipping turn")
		call_deferred("_process_turn_queue")
		return
	
	if character.character_type == Character.CharacterType.ENEMY:
		_process_ai_turn(character)
	else:
		# Esperar input del jugador
		pass

func _is_character_disabled(character: Character) -> bool:
	for debuff in character.debuffs:
		if debuff.effect_type in [StatusEffect.EffectType.STUN, StatusEffect.EffectType.SLEEP]:
			return true
	return false

func _process_ai_turn(character: Character):
	# IA mejorada que considera skills y cooldowns
	var available_skills = character.skills.filter(func(skill): return skill.can_use())
	
	if available_skills.is_empty():
		available_skills = [character.skills[0]]  # Ataque básico siempre disponible
	
	# Elegir skill (priorizar ultimate si está disponible)
	var chosen_skill = available_skills[0]
	for skill in available_skills:
		if skill.cooldown > chosen_skill.cooldown:
			chosen_skill = skill
	
	# Elegir targets
	var targets = _get_ai_targets(character, chosen_skill)
	
	if not targets.is_empty():
		execute_skill(character, chosen_skill, targets)

func _get_ai_targets(caster: Character, skill: Skill) -> Array[Character]:
	var targets: Array[Character] = []
	
	match skill.target_type:
		Skill.TargetType.SINGLE_ENEMY:
			var enemies = game_manager.player_team.filter(func(char): return char.is_alive())
			if not enemies.is_empty():
				# Atacar al más débil
				var target = enemies.reduce(func(a, b): return a if a.current_hp < b.current_hp else b)
				targets.append(target)
		
		Skill.TargetType.ALL_ENEMIES:
			targets = game_manager.player_team.filter(func(char): return char.is_alive())
		
		Skill.TargetType.SINGLE_ALLY:
			var allies = game_manager.enemy_team.filter(func(char): return char.is_alive())
			if not allies.is_empty():
				# Curar/buffear al más débil
				var target = allies.reduce(func(a, b): return a if a.current_hp < b.current_hp else b)
				targets.append(target)
		
		Skill.TargetType.ALL_ALLIES:
			targets = game_manager.enemy_team.filter(func(char): return char.is_alive())
		
		Skill.TargetType.SELF:
			targets.append(caster)
	
	return targets

func execute_skill(caster: Character, skill: Skill, targets: Array[Character]):
	print(caster.character_name + " uses " + skill.skill_name)
	
	var results = skill.execute(caster, targets)
	skill_used.emit(caster, skill, targets, results)
	
	# Procesar resultados
	for i in range(results.size()):
		var result = results[i]
		var target = targets[i]
		
		if result.damage_dealt > 0:
			print("  -> " + target.character_name + " takes " + str(result.damage_dealt) + " damage!")
			if result.is_critical:
				print("  -> CRITICAL HIT!")
			if result.is_weakness:
				print("  -> It's super effective!")
		elif result.damage_dealt < 0:
			print("  -> " + target.character_name + " heals " + str(-result.damage_dealt) + " HP!")
		
		for effect in result.effects_applied:
			print("  -> " + effect.effect_name + " applied to " + target.character_name)
	
	# Verificar fin de batalla
	if _check_battle_end():
		return
	
	# Continuar con el siguiente turno
	call_deferred("_process_turn_queue")

func _check_battle_end() -> bool:
	var player_alive = game_manager.player_team.any(func(char): return char.is_alive())
	var enemy_alive = game_manager.enemy_team.any(func(char): return char.is_alive())
	
	if not player_alive:
		current_phase = BattlePhase.DEFEAT
		game_manager.battle_ended.emit(GameManager.BattleResult.DEFEAT)
		return true
	elif not enemy_alive:
		current_phase = BattlePhase.VICTORY
		game_manager.battle_ended.emit(GameManager.BattleResult.VICTORY)
		return true
	
	return false

func create_test_enemies() -> Array[Character]:
	var enemies: Array[Character] = []
	
	var enemy1 = Character.new()
	enemy1.setup("Fire Goblin", 1, Character.Rarity.COMMON, Character.Element.FIRE, 80, 15, 8, 70, 0.1, 1.4)
	enemy1.character_type = Character.CharacterType.ENEMY
	
	var enemy2 = Character.new()
	enemy2.setup("Earth Orc", 1, Character.Rarity.RARE, Character.Element.EARTH, 120, 20, 12, 60, 0.15, 1.5)
	enemy2.character_type = Character.CharacterType.ENEMY
	
	var boss = Character.new()
	boss.setup("Void Dragon", 2, Character.Rarity.EPIC, Character.Element.VOID, 200, 30, 18, 80, 0.2, 1.6)
	boss.character_type = Character.CharacterType.ENEMY
	
	enemies.append(enemy1)
	enemies.append(enemy2)
	enemies.append(boss)
	
	return enemies
