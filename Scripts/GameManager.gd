class_name GameManager
extends Node

signal turn_changed(current_turn)
signal battle_ended(result)
signal player_level_changed(new_level)
signal currency_changed(new_amount)

enum GameState { MENU, BATTLE, GACHA, INVENTORY, CHAPTERS, TEAM_FORMATION }
enum BattleResult { VICTORY, DEFEAT }

var current_state: GameState = GameState.MENU
var player_team: Array[Character] = []
var enemy_team: Array[Character] = []
var current_turn_index: int = 0
var turn_order: Array[Character] = []
var player_inventory: Array[Character] = []
var game_currency: int = 2000  # Más moneda inicial
var player_level: int = 1
var player_experience: int = 0
var player_experience_needed: int = 100

# Sistema de energía
var energy: int = 100
var max_energy: int = 100
var energy_regen_time: float = 300.0  # 5 minutos por energía

# Progreso del juego
var highest_chapter: int = 1
var highest_stage: int = 1

func _ready():
	# Configurar timer para regeneración de energía
	var energy_timer = Timer.new()
	energy_timer.wait_time = energy_regen_time
	energy_timer.timeout.connect(_regenerate_energy)
	energy_timer.autostart = true
	add_child(energy_timer)

func _regenerate_energy():
	if energy < max_energy:
		energy += 1
		print("Energy regenerated: " + str(energy) + "/" + str(max_energy))

func add_currency(amount: int):
	game_currency += amount
	currency_changed.emit(game_currency)

func spend_currency(amount: int) -> bool:
	if game_currency >= amount:
		game_currency -= amount
		currency_changed.emit(game_currency)
		return true
	return false

func add_experience(amount: int):
	player_experience += amount
	
	while player_experience >= player_experience_needed:
		player_experience -= player_experience_needed
		player_level += 1
		player_experience_needed = int(player_experience_needed * 1.2)
		player_level_changed.emit(player_level)
		print("Player leveled up! New level: " + str(player_level))

func start_battle(enemies: Array[Character]):
	current_state = GameState.BATTLE
	enemy_team = enemies
	_setup_turn_order()
	current_turn_index = 0
	if turn_order.size() > 0:
		turn_changed.emit(turn_order[current_turn_index])

func _setup_turn_order():
	turn_order.clear()
	var all_characters: Array[Character] = []
	all_characters.append_array(player_team)
	all_characters.append_array(enemy_team)
	
	# Resetear combat readiness y configurar inicial
	for character in all_characters:
		character.reset_combat_readiness()
		var initial_cr = (character.speed / 300.0) * 100.0
		character.add_combat_readiness(initial_cr)
	
	turn_order = all_characters

func next_turn():
	# El sistema de turnos ahora se maneja en BattleSystem
	pass

func _check_battle_end():
	var player_alive = player_team.any(func(char): return char.is_alive())
	var enemy_alive = enemy_team.any(func(char): return char.is_alive())
	
	if not player_alive:
		battle_ended.emit(BattleResult.DEFEAT)
		current_state = GameState.MENU
	elif not enemy_alive:
		battle_ended.emit(BattleResult.VICTORY)
		add_currency(150)  # Recompensa por victoria
		add_experience(50)
		current_state = GameState.MENU

func get_current_character() -> Character:
	if turn_order.size() > 0 and current_turn_index < turn_order.size():
		return turn_order[current_turn_index]
	return null

func unlock_stage(chapter: int, stage: int):
	if chapter > highest_chapter or (chapter == highest_chapter and stage > highest_stage):
		highest_chapter = chapter
		highest_stage = stage
		print("New stage unlocked: Chapter " + str(chapter) + " Stage " + str(stage))
