# ==== CHAPTER CARD CONTROLLER ====
extends Button

# Referencias UI
@onready var chapter_icon = $ContentContainer/LeftSection/ChapterIcon
@onready var chapter_number = $ContentContainer/LeftSection/ChapterNumber
@onready var chapter_name = $ContentContainer/MiddleSection/ChapterName
@onready var description = $ContentContainer/MiddleSection/Description
@onready var progress = $ContentContainer/MiddleSection/StageProgressContainer/Progress
@onready var lock_icon = $ContentContainer/RightSection/StatusIndicator/LockIcon
@onready var stars_container = $ContentContainer/RightSection/StatusIndicator/StarsContainer
@onready var completion_badge = $ContentContainer/RightSection/CompletionBadge
@onready var recommended_power = $ContentContainer/RightSection/RecommendedPower
@onready var border_glow = $BorderGlow
@onready var inner_background = $InnerBackground

# Datos del capítulo
var chapter_data: ChapterData
var is_unlocked: bool = false
var completed_stages: int = 0
var total_stages: int = 0

# Señales
signal chapter_card_pressed(chapter_data: ChapterData)

func _ready():
	pressed.connect(_on_pressed)

func setup_chapter(data: ChapterData, unlocked: bool):
	"""Configurar la card con datos del capítulo"""
	chapter_data = data
	is_unlocked = unlocked
	
	if not chapter_data:
		print("ChapterCard: Error - chapter_data is null")
		return
	
	_calculate_progress()
	_update_visuals()

func _calculate_progress():
	"""Calcular progreso del capítulo"""
	if not chapter_data:
		return
	
	total_stages = chapter_data.max_stages
	completed_stages = 0
	
	for stage in chapter_data.stages:
		if stage and stage.completed:
			completed_stages += 1

func _update_visuals():
	"""Actualizar todos los elementos visuales"""
	if not chapter_data:
		return
	
	_update_basic_info()
	_update_progress_display()
	_update_status_indicators()
	_update_styling()

func _update_basic_info():
	"""Actualizar información básica del capítulo"""
	if chapter_icon:
		chapter_icon.text = _get_chapter_icon()
	
	if chapter_number:
		chapter_number.text = "Ch. " + str(chapter_data.chapter_id)
	
	if chapter_name:
		chapter_name.text = chapter_data.chapter_name
	
	if description:
		description.text = chapter_data.description

func _get_chapter_icon() -> String:
	"""Obtener icono basado en el ID del capítulo"""
	match chapter_data.chapter_id:
		1:
			return "🌲"  # Forest
		2:
			return "🔥"  # Desert/Fire
		3:
			return "💎"  # Crystal Caves
		4:
			return "🏔️"  # Mountains
		5:
			return "🌙"  # Dark Realm
		_:
			return "⚔️"  # Default

func _update_progress_display():
	"""Actualizar display de progreso"""
	if progress:
		progress.text = str(completed_stages) + "/" + str(total_stages) + " stages"
		
		# Color según progreso
		if completed_stages == 0:
			progress.modulate = Color(0.7, 0.7, 0.8, 1)  # Gris
		elif completed_stages == total_stages:
			progress.modulate = Color(0.3, 1, 0.3, 1)    # Verde
		else:
			progress.modulate = Color(0.7, 0.9, 1, 1)    # Azul

func _update_status_indicators():
	"""Actualizar indicadores de estado"""
	if not is_unlocked:
		_show_locked_state()
	elif completed_stages == total_stages:
		_show_completed_state()
	else:
		_show_available_state()

func _show_locked_state():
	"""Mostrar estado bloqueado"""
	disabled = true
	modulate = Color(0.6, 0.6, 0.6, 1)
	
	if lock_icon:
		lock_icon.visible = true
	if stars_container:
		stars_container.visible = false
	if completion_badge:
		completion_badge.visible = false
	if recommended_power:
		recommended_power.visible = true
		recommended_power.text = "LOCKED"
		recommended_power.modulate = Color(0.8, 0.4, 0.4, 1)

func _show_completed_state():
	"""Mostrar estado completado"""
	disabled = false
	modulate = Color(1, 1, 1, 1)
	
	if lock_icon:
		lock_icon.visible = false
	if stars_container:
		stars_container.visible = true
		_update_stars_display()
	if completion_badge:
		completion_badge.visible = true
		completion_badge.text = "COMPLETE"
		completion_badge.modulate = Color(0.2, 1, 0.3, 1)
	if recommended_power:
		recommended_power.visible = false

func _show_available_state():
	"""Mostrar estado disponible"""
	disabled = false
	modulate = Color(1, 1, 1, 1)
	
	if lock_icon:
		lock_icon.visible = false
	if stars_container:
		stars_container.visible = true
		_update_stars_display()
	if completion_badge:
		completion_badge.visible = false
	if recommended_power:
		recommended_power.visible = true
		recommended_power.text = "Power: " + str(_get_recommended_power()) + "+"
		recommended_power.modulate = Color(1, 0.8, 0.4, 1)

func _update_stars_display():
	"""Actualizar display de estrellas"""
	if not stars_container:
		return
	
	var star_count = _calculate_total_stars()
	var max_stars = total_stages * 3  # 3 estrellas por stage
	
	# Actualizar las 3 estrellas principales del capítulo
	for i in range(3):
		var star_label = stars_container.get_node_or_null("Star" + str(i + 1))
		if star_label:
			if star_count >= (max_stars / 3) * (i + 1):
				star_label.text = "⭐"
				star_label.modulate = Color(1, 1, 1, 1)
			else:
				star_label.text = "☆"
				star_label.modulate = Color(0.4, 0.4, 0.4, 1)

func _calculate_total_stars() -> int:
	"""Calcular total de estrellas obtenidas en el capítulo"""
	var total_stars = 0
	
	if not chapter_data:
		return 0
	
	for stage in chapter_data.stages:
		if stage and stage.has_method("stars"):
			total_stars += stage.stars
		elif stage and stage.completed:
			total_stars += 3  # Asumir 3 estrellas si está completado
	
	return total_stars

func _get_recommended_power() -> int:
	"""Calcular poder recomendado para el capítulo"""
	return chapter_data.chapter_id * 400 + 200  # Escalado simple

func _update_styling():
	"""Actualizar styling según estado"""
	if not border_glow or not inner_background:
		return
	
	if not is_unlocked:
		# Estado bloqueado
		border_glow.color = Color(0.4, 0.4, 0.4, 0.8)
		inner_background.color = Color(0.08, 0.08, 0.12, 1)
	elif completed_stages == total_stages:
		# Completado - dorado
		border_glow.color = Color(1, 0.8, 0.2, 0.9)
		inner_background.color = Color(0.15, 0.12, 0.05, 1)
		_add_glow_effect()
	elif completed_stages > 0:
		# En progreso - azul
		border_glow.color = Color(0.3, 0.6, 1, 0.8)
		inner_background.color = Color(0.05, 0.08, 0.15, 1)
	else:
		# Disponible - normal
		border_glow.color = Color(0.2, 0.3, 0.5, 0.8)
		inner_background.color = Color(0.1, 0.1, 0.18, 1)

func _add_glow_effect():
	"""Añadir efecto de brillo para capítulos completados"""
	if not border_glow:
		return
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(border_glow, "modulate:a", 0.6, 1.5)
	tween.tween_property(border_glow, "modulate:a", 1.0, 1.5)

func _on_pressed():
	"""Manejar click en la card"""
	if is_unlocked and chapter_data:
		print("ChapterCard: Chapter selected - ", chapter_data.chapter_name)
		chapter_card_pressed.emit(chapter_data)

# ==== EFECTOS VISUALES ====
func _on_mouse_entered():
	"""Efecto hover"""
	if is_unlocked:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.02, 1.02), 0.1)

func _on_mouse_exited():
	"""Quitar efecto hover"""
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _on_button_down():
	"""Efecto press"""
	if is_unlocked:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(0.98, 0.98), 0.05)

func _on_button_up():
	"""Quitar efecto press"""
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.05)

# ==== FUNCIONES PÚBLICAS ====
func refresh_display():
	"""Refrescar display de la card"""
	if chapter_data:
		_calculate_progress()
		_update_visuals()

func set_locked(locked: bool):
	"""Cambiar estado de bloqueo"""
	is_unlocked = not locked
	_update_status_indicators()
	_update_styling()

func get_chapter_id() -> int:
	"""Obtener ID del capítulo"""
	return chapter_data.chapter_id if chapter_data else 0
