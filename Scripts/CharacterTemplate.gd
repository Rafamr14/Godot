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
@export var skill_icons: Array[Texture2D] = []

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

# Skills del personaje
@export var skill_templates: Array[SkillTemplate] = []

# Awakening materials y costos
@export var awakening_materials: Array[AwakeningMaterial] = []

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
	
	# Crear skills a partir de templates
	character.skills.clear()
	for skill_template in skill_templates:
		var skill = skill_template.create_skill_instance(level)
		character.skills.append(skill)
	
	# Calcular stats finales
	character._calculate_stats()
	character.current_hp = character.max_hp
	
	return character

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
	
	return base_value * (1.0 + (level - 1) * growth_rate)

func get_power_rating(level: int = 1) -> int:
	var hp = get_stat_at_level("hp", level)
	var attack = get_stat_at_level("attack", level)
	var defense = get_stat_at_level("defense", level)
	var speed = get_stat_at_level("speed", level)
	
	return int(hp + attack * 5 + defense * 3 + speed * 2)
