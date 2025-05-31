class_name ChapterData
extends Resource

@export var chapter_id: int
@export var chapter_name: String
@export var description: String
@export var max_stages: int
@export var stages: Array = []  # CORREGIDO: Array genérico en lugar de Array[StageData]
@export var completed: bool = false

func setup(id: int, name: String, desc: String, stages_count: int):
	chapter_id = id
	chapter_name = name
	description = desc
	max_stages = stages_count

func get_stage(stage_id: int) -> StageData:
	if stage_id > 0 and stage_id <= stages.size():
		return stages[stage_id - 1]
	return null
