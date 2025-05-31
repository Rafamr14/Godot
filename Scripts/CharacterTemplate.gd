class_name CharacterTemplate
extends Resource

# Información básica del personaje
@export var character_name: String
@export var character_id: String  # ID único para identificar el personaje
@export var description: String
@export var element: Character.Element = Character.Element.WATER
@export var rarity: Character.Rarity = Character.Rarity.COMMON
@export var character_class: CharacterClass = CharacterClass.WARRIOR

# Sprites y recursos visuales
@export var portrait: Texture2D
@export var battle_sprite: Texture2D
@export var skill_icons: Array = []  # Array genérico en lugar de Array[Texture2D]

# Stats base (nivel 1)
@export var base_hp: int = 100
@export var base_attack: int = 20
@export var base_defense: int = 10
@export var base_speed: int = 80
@export var base_crit_chance: float = 0.15
@export var base_crit_damage: float = 1.5
@export var base_effectiveness: float = 0.0
@export var base_effect_resistance: float = 0.0
@export var base_elemental_mastery: float = 0.0

# Crecimiento por nivel (multiplicadores)
@export var hp_growth: float = 0.08      # +8% por nivel
@export var attack_growth: float = 0.05  # +5% por nivel
@export var defense_growth: float = 0.04 # +4% por nivel
@export var speed_growth: float = 0.02   # +2% por nivel

# Skills del personaje - CORREGIDO: Array genérico
@export var skill_templates: Array = []  # Array de SkillTemplate

# Awakening materials y costos - CORREGIDO: Array genérico
@export var awakening_materials: Array = []  # Array de AwakeningMaterial

# Líneas de voz/diálogo
@export var voice_lines: Dictionary = {
	"summon": "I'm ready to fight!",
	"victory": "Victory is ours!",
	"defeat": "I'll be stronger next time...",
	"skill_1": "Take this!",
	"skill_2": "Feel my power!",
	"ultimate": "This ends now!"
}

enum CharacterClass { WARRIOR, MAGE, ARCHER, HEALER, ASSASSIN, TANK, SUPPORT }

func create_character_instance(level: int = 1) -> Character:
	var character = Character.new()
	
	if not character:
		print("Error: No se pudo crear instancia de Character")
		return null
	
	# Configurar información básica
	character.character_name = character_name
	character.level = level
	character.rarity = rarity
	character.element = element
	character.character_class = character_class
	
	# Calcular stats para el nivel dado
	var level_multiplier = 1.0 + ((level - 1) * 0.1)  # Base multiplier
	
	character.base_hp = int(base_hp * (1.0 + (level - 1) * hp_growth))
	character.base_attack = int(base_attack * (1.0 + (level - 1) * attack_growth))
	character.base_defense = int(base_defense * (1.0 + (level - 1) * defense_growth))
	character.base_speed = int(base_speed * (1.0 + (level - 1) * speed_growth))
	
	character.base_crit_chance = base_crit_chance
	character.base_crit_damage = base_crit_damage
	character.base_effectiveness = base_effectiveness
	character.base_effect_resistance = base_effect_resistance
	character.base_elemental_mastery = base_elemental_mastery
	
	# Crear skills a partir de templates - CON VERIFICACIÓN DE NULL
	character.skills.clear()
	_create_skills_for_character(character, level)
	
	# Calcular stats finales
	character._calculate_stats()
	character.current_hp = character.max_hp
	
	return character

func _create_skills_for_character(character: Character, level: int):
	"""Crear skills para un personaje con verificación de null"""
	
	# Si no hay skill templates, crear skills básicos
	if skill_templates.is_empty():
		print("CharacterTemplate: No skill templates found, creating basic skills for ", character_name)
		_create_basic_skills(character, level)
		return
	
	# Crear skills desde templates
	for i in range(skill_templates.size()):
		var skill_template = skill_templates[i]
		
		# Verificar que el skill_template no es null
		if not skill_template:
			print("CharacterTemplate: Skill template ", i, " is null, skipping")
			continue
		
		# Verificar que tiene el método create_skill_instance
		if not skill_template.has_method("create_skill_instance"):
			print("CharacterTemplate: Skill template ", i, " no tiene create_skill_instance, creando skill básico")
			_create_fallback_skill(character, i, level)
			continue
		
		# Crear skill desde template
		var skill = skill_template.create_skill_instance(level)
		if skill:
			character.skills.append(skill)
			print("CharacterTemplate: Created skill ", skill.skill_name, " for ", character_name)
		else:
			print("CharacterTemplate: Failed to create skill from template ", i)
			_create_fallback_skill(character, i, level)

func _create_basic_skills(character: Character, level: int):
	"""Crear skills básicos cuando no hay templates"""
	
	# Verificar que la clase Skill existe
	var skill_class = load("res://Scripts/Skill.gd")
	if not skill_class:
		print("CharacterTemplate: Skill class not found, character will have no skills")
		return
	
	# Skill 1: Ataque básico
	var basic_attack = Skill.new()
	if basic_attack:
		basic_attack.setup("Basic Attack", 0, Skill.SkillType.DAMAGE, Skill.TargetType.SINGLE_ENEMY, 1.0, element)
		basic_attack.description = "Deal damage to one enemy"
		character.skills.append(basic_attack)
	
	# Skill 2: Ataque fuerte
	var power_strike = Skill.new()
	if power_strike:
		power_strike.setup("Power Strike", 0, Skill.SkillType.DAMAGE, Skill.TargetType.SINGLE_ENEMY, 1.3, element)
		power_strike.cooldown = 3
		power_strike.description = "Deal increased damage to one enemy"
		character.skills.append(power_strike)
	
	# Skill 3: Ultimate
	var ultimate = Skill.new()
	if ultimate:
		ultimate.setup("Ultimate", 0, Skill.SkillType.DAMAGE, Skill.TargetType.ALL_ENEMIES, 1.8, element)
		ultimate.cooldown = 5
		ultimate.description = "Deal massive damage to all enemies"
		character.skills.append(ultimate)
	
	print("CharacterTemplate: Created ", character.skills.size(), " basic skills for ", character_name)

func _create_fallback_skill(character: Character, skill_index: int, level: int):
	"""Crear skill de fallback cuando falla el template"""
	
	var skill_class = load("res://Scripts/Skill.gd")
	if not skill_class:
		return
	
	var fallback_skill = Skill.new()
	if not fallback_skill:
		return
	
	var skill_names = ["Strike", "Blast", "Crush", "Smash", "Attack"]
	var skill_name = skill_names[skill_index % skill_names.size()]
	
	var multiplier = 1.0 + (skill_index * 0.2)
	var cooldown = skill_index
	
	fallback_skill.setup(skill_name, 0, Skill.SkillType.DAMAGE, Skill.TargetType.SINGLE_ENEMY, multiplier, element)
	fallback_skill.cooldown = cooldown
	fallback_skill.description = "A " + skill_name.to_lower() + " attack"
	
	character.skills.append(fallback_skill)
	print("CharacterTemplate: Created fallback skill ", skill_name, " for ", character_name)

func get_stat_at_level(stat_type: String, level: int) -> float:
	var base_value = 0.0
	var growth_rate = 0.0
	
	match stat_type:
		"hp":
			base_value = base_hp
			growth_rate = hp_growth
		"attack":
			base_value = base_attack
			growth_rate = attack_growth
		"defense":
			base_value = base_defense
			growth_rate = defense_growth
		"speed":
			base_value = base_speed
			growth_rate = speed_growth
		_:
			return 0.0
	
	return base_value * (1.0 + (level - 1) * growth_rate)

func get_power_rating(level: int = 1) -> int:
	var hp = get_stat_at_level("hp", level)
	var attack = get_stat_at_level("attack", level)
	var defense = get_stat_at_level("defense", level)
	var speed = get_stat_at_level("speed", level)
	
	return int(hp + attack * 5 + defense * 3 + speed * 2)

# ==== FUNCIONES DE VALIDACIÓN ====
func is_valid() -> bool:
	"""Verificar si el template es válido"""
	if character_name.is_empty():
		return false
	if character_id.is_empty():
		return false
	if base_hp <= 0 or base_attack <= 0:
		return false
	return true

func get_validation_errors() -> Array:
	"""Obtener lista de errores de validación"""
	var errors = []
	
	if character_name.is_empty():
		errors.append("Character name is empty")
	if character_id.is_empty():
		errors.append("Character ID is empty")
	if base_hp <= 0:
		errors.append("Base HP must be greater than 0")
	if base_attack <= 0:
		errors.append("Base attack must be greater than 0")
	if base_speed <= 0:
		errors.append("Base speed must be greater than 0")
	
	return errors

# ==== FUNCIONES UTILITARIAS ====
func duplicate_template() -> CharacterTemplate:
	"""Crear una copia del template"""
	var new_template = CharacterTemplate.new()
	
	# Copiar propiedades básicas
	new_template.character_name = character_name
	new_template.character_id = character_id + "_copy"
	new_template.description = description
	new_template.element = element
	new_template.rarity = rarity
	new_template.character_class = character_class
	
	# Copiar stats
	new_template.base_hp = base_hp
	new_template.base_attack = base_attack
	new_template.base_defense = base_defense
	new_template.base_speed = base_speed
	new_template.base_crit_chance = base_crit_chance
	new_template.base_crit_damage = base_crit_damage
	
	# Copiar growth rates
	new_template.hp_growth = hp_growth
	new_template.attack_growth = attack_growth
	new_template.defense_growth = defense_growth
	new_template.speed_growth = speed_growth
	
	return new_template
