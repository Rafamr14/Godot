# ==== CHAPTER SELECTION UI CORREGIDO (ChapterSelectionUI.gd) ====
extends Control

@onready var chapter_list = $VBoxContainer/ScrollContainer/ChapterList
@onready var chapter_info = $VBoxContainer/ChapterInfo
@onready var back_button = $VBoxContainer/BackButton

var chapter_system: ChapterSystem
var selected_chapter: ChapterData

signal chapter_selected(chapter_data)
signal stage_selected(chapter_id, stage_id)
signal back_pressed()

func _ready():
	# Esperar varios frames para que Main.gd termine de crear los sistemas
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Buscar ChapterSystem desde el nodo padre correcto
	chapter_system = get_node_or_null("../ChapterSystem")
	
	if chapter_system == null:
		print("Warning: ChapterSystem not found! Waiting longer...")
		# Esperar más tiempo y buscar de nuevo
		await get_tree().create_timer(0.5).timeout
		chapter_system = get_node_or_null("../ChapterSystem")
		
		if chapter_system == null:
			print("Error: ChapterSystem still not found! Creating temporary system...")
			chapter_system = ChapterSystem.new()
			get_parent().add_child(chapter_system)
	
	if back_button:
		back_button.pressed.connect(func(): back_pressed.emit())
	
	_populate_chapters()

func _populate_chapters():
	if not chapter_list:
		print("Warning: Chapter list not found, creating simple structure")
		_create_simple_structure()
		return
	
	# Clear existing chapters
	for child in chapter_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Add chapter buttons
	if chapter_system and chapter_system.chapters:
		for chapter in chapter_system.chapters:
			var chapter_card = _create_chapter_card(chapter)
			chapter_list.add_child(chapter_card)

func _create_simple_structure():
	# Crear estructura básica si no existe
	var vbox = VBoxContainer.new()
	add_child(vbox)
	
	var title = Label.new()
	title.text = "Adventure"
	vbox.add_child(title)
	
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(400, 300)
	vbox.add_child(scroll)
	
	chapter_list = VBoxContainer.new()
	chapter_list.name = "ChapterList"
	scroll.add_child(chapter_list)
	
	back_button = Button.new()
	back_button.text = "Back"
	back_button.pressed.connect(func(): back_pressed.emit())
	vbox.add_child(back_button)

func _create_chapter_card(chapter: ChapterData) -> Control:
	# Crear card simple
	var card = Button.new()
	card.custom_minimum_size = Vector2(300, 80)
	
	var card_text = chapter.chapter_name + "\n"
	card_text += chapter.description + "\n"
	card_text += "Progress: " + str(_get_completed_stages(chapter)) + "/" + str(chapter.max_stages)
	
	card.text = card_text
	
	# Set unlock status
	var is_unlocked = chapter_system.is_stage_unlocked(chapter.chapter_id, 1)
	card.modulate = Color.WHITE if is_unlocked else Color.GRAY
	
	if is_unlocked:
		card.pressed.connect(func(): _on_chapter_selected(chapter))
	
	return card

func _get_completed_stages(chapter: ChapterData) -> int:
	var completed = 0
	for stage in chapter.stages:
		if stage.completed:
			completed += 1
	return completed

func _on_chapter_selected(chapter: ChapterData):
	selected_chapter = chapter
	chapter_selected.emit(chapter)
	_show_stage_selection(chapter)

func _show_stage_selection(chapter: ChapterData):
	if not chapter_list:
		return
		
	# Clear chapter list and show stages
	for child in chapter_list.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Add stage buttons
	for stage in chapter.stages:
		var stage_card = _create_stage_card(chapter.chapter_id, stage)
		chapter_list.add_child(stage_card)

func _create_stage_card(chapter_id: int, stage: StageData) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(300, 60)
	
	var card_text = stage.stage_name + "\n"
	card_text += str(stage.enemies.size()) + " enemies | "
	card_text += "Rewards: +" + str(stage.rewards.gold) + " gold"
	
	card.text = card_text
	
	# Set unlock status
	var is_unlocked = chapter_system.is_stage_unlocked(chapter_id, stage.stage_id)
	card.modulate = Color.WHITE if is_unlocked else Color.GRAY
	
	if is_unlocked:
		card.pressed.connect(func(): stage_selected.emit(chapter_id, stage.stage_id))
	
	return card
