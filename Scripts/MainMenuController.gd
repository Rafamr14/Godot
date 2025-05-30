extends Control

@onready var game_manager = get_node("/root/GameManager")
@onready var chapter_button = $VBoxContainer/ChapterButton
@onready var team_button = $VBoxContainer/TeamButton
@onready var gacha_button = $VBoxContainer/GachaButton
@onready var inventory_button = $VBoxContainer/InventoryButton
@onready var currency_label = $VBoxContainer/CurrencyLabel
@onready var player_info = $VBoxContainer/PlayerInfo

signal menu_changed(menu_name)

func _ready():
	_setup_connections()
	_update_display()

func _setup_connections():
	chapter_button.pressed.connect(func(): menu_changed.emit("chapters"))
	team_button.pressed.connect(func(): menu_changed.emit("team"))
	gacha_button.pressed.connect(func(): menu_changed.emit("gacha"))
	inventory_button.pressed.connect(func(): menu_changed.emit("inventory"))

func _update_display():
	currency_label.text = "Gold: " + str(game_manager.game_currency)
	player_info.text = "Level: " + str(game_manager.player_level) + " | Team Power: " + str(_calculate_team_power())

func _calculate_team_power() -> int:
	var power = 0
	for character in game_manager.player_team:
		power += character.max_hp + character.attack * 5 + character.defense * 3
	return power
