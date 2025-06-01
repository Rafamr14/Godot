class_name BattleSystem
extends Node

signal turn_started(character)
signal skill_used(caster, skill, targets, results)
signal battle_phase_changed(phase)

enum BattlePhase { PREPARATION, COMBAT, VICTORY, DEFEAT }

var game_manager: GameManager
var current_phase: BattlePhase = BattlePhase.PREPARATION
var turn_queue: Array = []  # Array genérico
var turn_counter: int = 0

func _ready():
	await get_tree().process_frame
	game_manager = get_parent().get_node("GameManager")

func start_battle(player_team: Array, enemy_team: Array):
	print("BattleSystem: Starting battle with ", player_team.size(), " vs ", enemy_team.size())
	current_phase = BattlePhase.PREPARATION
	turn_counter = 0
	
	# Actualizar equipos en GameManager
	if game_manager:
		game_manager.player_team = player_team.duplicate()
		game_manager.enemy_team = enemy_team.duplicate()
	
	_setup_battle_queue(player_team, enemy_team)
	current_phase = BattlePhase.COMBAT
	battle_phase_changed.emit(current_phase)
	_process_turn_queue()

func _setup_battle_queue(player_team: Array, enemy_team: Array):
	turn_queue.clear()
	var all_characters: Array = []
	
	# Agregar todos los personajes válidos
	for character in player_team:
		if character != null and character is Character:
			all_characters.append(character)
	
	for character in enemy_team:
		if character != null and character is Character:
			all_characters.append(character)
	
	print("BattleSystem: Setup queue with ", all_characters.size(), " total characters")
	
	# Resetear Combat Readiness y configurar inicial
	for character in all_characters:
		character.reset_combat_readiness()
		var initial_cr = (float(character.speed) / 300.0) * 100.0
		character.add_combat_readiness(initial_cr)
		print("BattleSystem: ", character.character_name, " initial CR: ", character.combat_readiness)
	
	turn_queue = all_characters

func _process_turn_queue():
	if current_phase != BattlePhase.COMBAT:
		return
	
	# Encontrar personaje con mayor CR
	var next_character = _get_next_character()
	
	if next_character == null:
		_advance_all_cr()
		# Usar call_deferred para evitar problemas de recursión
		call_deferred("_process_turn_queue")
		return
	
	# Es el turno de este personaje
	next_character.reset_combat_readiness()
	turn_counter += 1
	_process_character_turn(next_character)

func _get_next_character() -> Character:
	var highest_cr = 0.0
	var next_char: Character = null
	
	for character in turn_queue:
		if character != null and character is Character:
			if character.is_alive() and character.combat_readiness >= 100.0:
				if character.combat_readiness > highest_cr:
					highest_cr = character.combat_readiness
					next_char = character
	
	return next_char

func _advance_all_cr():
	# Avanzar CR de todos los personajes vivos
	for character in turn_queue:
		if character != null and character is Character and character.is_alive():
			var cr_gain = (float(character.speed) / 300.0) * 10.0
			character.add_combat_readiness(cr_gain)

func _process_character_turn(character: Character):
	print("BattleSystem: Turn started for ", character.character_name)
	turn_started.emit(character)
	
	# Procesar efectos de estado al inicio del turno
	character.process_status_effects()
	
	# Reducir cooldowns
	for skill in character.skills:
		if skill != null:
			skill.reduce_cooldown()
	
	# Verificar si está aturdido, dormido, etc.
	if _is_character_disabled(character):
		print(character.character_name + " is disabled, skipping turn")
		call_deferred("_process_turn_queue")
		return
	
	if character.character_type == Character.CharacterType.ENEMY:
		_process_ai_turn(character)
	else:
		# Esperar input del jugador - el UI manejará esto
		print("BattleSystem: Waiting for player input for ", character.character_name)

func _is_character_disabled(character: Character) -> bool:
	for debuff in character.debuffs:
		if debuff != null and debuff.effect_type in [StatusEffect.EffectType.STUN, StatusEffect.EffectType.SLEEP]:
			return true
	return false

func _process_ai_turn(character: Character):
	print("BattleSystem: Processing AI turn for ", character.character_name)
	
	# IA mejorada que considera skills y cooldowns
	var available_skills = []
	for skill in character.skills:
		if skill != null and skill.can_use():
			available_skills.append(skill)
	
	if available_skills.is_empty():
		# Usar primer skill como ataque básico
		if character.skills.size() > 0 and character.skills[0] != null:
			available_skills = [character.skills[0]]
		else:
			print("ERROR: Character has no valid skills!")
			call_deferred("_process_turn_queue")
			return
	
	# Elegir skill (priorizar ultimate si está disponible)
	var chosen_skill = available_skills[0]
	for skill in available_skills:
		if skill != null and skill.cooldown > chosen_skill.cooldown:
			chosen_skill = skill
	
	# Elegir targets
	var targets = _get_ai_targets(character, chosen_skill)
	
	if not targets.is_empty():
		execute_skill(character, chosen_skill, targets)
	else:
		print("ERROR: No valid targets found for AI")
		call_deferred("_process_turn_queue")

func _get_ai_targets(caster: Character, skill: Skill) -> Array:
	var targets: Array = []
	
	if not game_manager:
		print("ERROR: GameManager not found for target selection")
		return targets
	
	match skill.target_type:
		Skill.TargetType.SINGLE_ENEMY:
			var enemies = []
			for char in game_manager.player_team:
				if char != null and char is Character and char.is_alive():
					enemies.append(char)
			
			if not enemies.is_empty():
				# Atacar al más débil
				var target = enemies[0]
				for enemy in enemies:
					if enemy.current_hp < target.current_hp:
						target = enemy
				targets.append(target)
		
		Skill.TargetType.ALL_ENEMIES:
			for char in game_manager.player_team:
				if char != null and char is Character and char.is_alive():
					targets.append(char)
		
		Skill.TargetType.SINGLE_ALLY:
			var allies = []
			for char in game_manager.enemy_team:
				if char != null and char is Character and char.is_alive():
					allies.append(char)
			
			if not allies.is_empty():
				# Curar/buffear al más débil
				var target = allies[0]
				for ally in allies:
					if ally.current_hp < target.current_hp:
						target = ally
				targets.append(target)
		
		Skill.TargetType.ALL_ALLIES:
			for char in game_manager.enemy_team:
				if char != null and char is Character and char.is_alive():
					targets.append(char)
		
		Skill.TargetType.SELF:
			targets.append(caster)
	
	return targets

func execute_skill(caster: Character, skill: Skill, targets: Array):
	if caster == null or skill == null or targets.is_empty():
		print("ERROR: Invalid skill execution parameters")
		call_deferred("_process_turn_queue")
		return
	
	print("BattleSystem: ", caster.character_name, " uses ", skill.skill_name)
	
	var results = skill.execute(caster, targets)
	skill_used.emit(caster, skill, targets, results)
	
	# Procesar resultados
	for i in range(min(results.size(), targets.size())):
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
			if effect != null:
				print("  -> " + effect.effect_name + " applied to " + target.character_name)
	
	# Verificar fin de batalla
	if _check_battle_end():
		return
	
	# Continuar con el siguiente turno
	call_deferred("_process_turn_queue")

func _check_battle_end() -> bool:
	if not game_manager:
		return false
	
	var player_alive = false
	for char in game_manager.player_team:
		if char != null and char is Character and char.is_alive():
			player_alive = true
			break
	
	var enemy_alive = false
	for char in game_manager.enemy_team:
		if char != null and char is Character and char.is_alive():
			enemy_alive = true
			break
	
	if not player_alive:
		current_phase = BattlePhase.DEFEAT
		print("BattleSystem: Player team defeated!")
		if game_manager.has_signal("battle_ended"):
			game_manager.battle_ended.emit(GameManager.BattleResult.DEFEAT)
		return true
	elif not enemy_alive:
		current_phase = BattlePhase.VICTORY
		print("BattleSystem: Enemy team defeated!")
		if game_manager.has_signal("battle_ended"):
			game_manager.battle_ended.emit(GameManager.BattleResult.VICTORY)
		return true
	
	return false

func create_test_enemies() -> Array:
	var enemies: Array = []
	
	var enemy1 = Character.new()
	if enemy1:
		enemy1.setup("Fire Goblin", 1, Character.Rarity.COMMON, Character.Element.FIRE, 80, 15, 8, 70, 0.1, 1.4)
		enemy1.character_type = Character.CharacterType.ENEMY
		enemies.append(enemy1)
	
	var enemy2 = Character.new()
	if enemy2:
		enemy2.setup("Earth Orc", 1, Character.Rarity.RARE, Character.Element.EARTH, 120, 20, 12, 60, 0.15, 1.5)
		enemy2.character_type = Character.CharacterType.ENEMY
		enemies.append(enemy2)
	
	var boss = Character.new()
	if boss:
		boss.setup("Void Dragon", 2, Character.Rarity.EPIC, Character.Element.VOID, 200, 30, 18, 80, 0.2, 1.6)
		boss.character_type = Character.CharacterType.ENEMY
		enemies.append(boss)
	
	return enemies

# Función pública para que la UI ejecute skills del jugador
func player_use_skill(caster: Character, skill: Skill, targets: Array) -> bool:
	if caster == null or skill == null or targets.is_empty():
		return false
	
	execute_skill(caster, skill, targets)
	return true

# Función para obtener el personaje actual del turno
func get_current_turn_character() -> Character:
	# Encontrar el personaje que debería actuar
	return _get_next_character()

# Función para verificar si es turno del jugador
func is_player_turn() -> bool:
	var current_char = get_current_turn_character()
	return current_char != null and current_char.character_type == Character.CharacterType.PLAYER
