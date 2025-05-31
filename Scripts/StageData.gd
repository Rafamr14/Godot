# ==== STAGE DATA CLASS CORREGIDO ====
class_name StageData
extends Resource

@export var stage_id: int
@export var stage_name: String
@export var enemies: Array = []  # CORREGIDO: Array genérico en lugar de Array[Character]
@export var rewards: StageRewards
@export var completed: bool = false
@export var stars: int = 0  # 0-3 stars based on performance

func setup(id: int, name: String, enemy_list: Array, stage_rewards: StageRewards):
	stage_id = id
	stage_name = name
	enemies = enemy_list
	rewards = stage_rewards
