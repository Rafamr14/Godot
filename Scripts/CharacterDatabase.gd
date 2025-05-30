class_name CharacterDatabase
extends Resource

@export var character_templates: Array[CharacterTemplate] = []

static var instance: CharacterDatabase

static func get_instance() -> CharacterDatabase:
	if instance == null:
		instance = load("res://data/character_database.tres") as CharacterDatabase
		if instance == null:
			instance = CharacterDatabase.new()
			instance._create_default_characters()
	return instance

func _create_default_characters():
	character_templates.clear()
	
	# Crear personajes de ejemplo
	_create_radiant_warrior()
	_create_void_mage()
	_create_water_healer()
	_create_fire_berserker()
	_create_earth_guardian()

func _create_radiant_warrior():
	var template = CharacterTemplate.new()
	template.character_name = "Radiant Warrior"
	template.character_id = "radiant_warrior_001"
	template.description = "A noble warrior blessed by the light"
	template.element = Character.Element.RADIANT
	template.rarity = Character.Rarity.RARE
	template.character_class = CharacterTemplate.CharacterClass.WARRIOR
	
	# Stats base
	template.base_hp = 120
	template.base_attack = 25
	template.base_defense = 18
	template.base_speed = 75
	template.base_crit_chance = 0.15
	template.base_crit_damage = 1.5
	
	# Growth rates
	template.hp_growth = 0.08
	template.attack_growth = 0.06
	template.defense_growth = 0.05
	template.speed_growth = 0.02
	
	# Skills
	var s1_template = SkillTemplate.new()
	s1_template.skill_name = "Radiant Strike"
	s1_template.skill_id = "radiant_strike"
	s1_template.skill_type = Skill.SkillType.DAMAGE
	s1_template.target_type = Skill.TargetType.SINGLE_ENEMY
	s1_template.element = Character.Element.RADIANT
	s1_template.base_multiplier = 1.0
	s1_template.base_cooldown = 0
	s1_template.attack_scaling = 1.0
	s1_template.description = "Deal damage to one enemy"
	
	var s2_template = SkillTemplate.new()
	s2_template.skill_name = "Divine Protection"
	s2_template.skill_id = "divine_protection"
	s2_template.skill_type = Skill.SkillType.BUFF
	s2_template.target_type = Skill.TargetType.ALL_ALLIES
	s2_template.element = Character.Element.RADIANT
	s2_template.base_multiplier = 0.0
	s2_template.base_cooldown = 4
	s2_template.description = "Grant defense buff to all allies"
	
	# Status effect para el buff
	var def_buff = StatusEffectTemplate.new()
	def_buff.effect_name = "Divine Shield"
	def_buff.effect_type = StatusEffect.EffectType.DEFENSE_UP
	def_buff.base_value = 0.5  # +50% defense
	def_buff.base_duration = 3
	def_buff.is_debuff = false
	s2_template.status_effect_templates.append(def_buff)
	
	var s3_template = SkillTemplate.new()
	s3_template.skill_name = "Judgment of Light"
	s3_template.skill_id = "judgment_light"
	s3_template.skill_type = Skill.SkillType.DAMAGE
	s3_template.target_type = Skill.TargetType.ALL_ENEMIES
	s3_template.element = Character.Element.RADIANT
	s3_template.base_multiplier = 1.8
	s3_template.base_cooldown = 5
	s3_template.attack_scaling = 1.2
	s3_template.description = "Deal massive light damage to all enemies"
	
	template.skill_templates = [s1_template, s2_template, s3_template]
	character_templates.append(template)

func _create_void_mage():
	var template = CharacterTemplate.new()
	template.character_name = "Void Mage"
	template.character_id = "void_mage_001"
	template.description = "A mysterious mage who commands the void"
	template.element = Character.Element.VOID
	template.rarity = Character.Rarity.EPIC
	template.character_class = CharacterTemplate.CharacterClass.MAGE
	
	template.base_hp = 90
	template.base_attack = 30
	template.base_defense = 12
	template.base_speed = 85
	template.base_crit_chance = 0.20
	template.base_crit_damage = 1.6
	
	template.hp_growth = 0.06
	template.attack_growth = 0.08
	template.defense_growth = 0.04
	template.speed_growth = 0.03
	
	# Skills con debuffs
	var s1 = SkillTemplate.new()
	s1.skill_name = "Void Bolt"
	s1.skill_id = "void_bolt"
	s1.skill_type = Skill.SkillType.DAMAGE
	s1.target_type = Skill.TargetType.SINGLE_ENEMY
	s1.element = Character.Element.VOID
	s1.base_multiplier = 1.2
	s1.attack_scaling = 1.0
	s1.description = "Dark magic that pierces defenses"
	
	var s2 = SkillTemplate.new()
	s2.skill_name = "Void Corruption"
	s2.skill_id = "void_corruption"
	s2.skill_type = Skill.SkillType.DEBUFF
	s2.target_type = Skill.TargetType.SINGLE_ENEMY
	s2.element = Character.Element.VOID
	s2.base_cooldown = 3
	s2.effect_chance = 0.8
	s2.description = "Inflict poison and attack down"
	
	# Poison debuff
	var poison = StatusEffectTemplate.new()
	poison.effect_name = "Void Poison"
	poison.effect_type = StatusEffect.EffectType.POISON
	poison.base_value = 0.1  # 10% max HP per turn
	poison.base_duration = 3
	poison.is_debuff = true
	s2.status_effect_templates.append(poison)
	
	# Attack down debuff
	var atk_down = StatusEffectTemplate.new()
	atk_down.effect_name = "Corruption"
	atk_down.effect_type = StatusEffect.EffectType.ATTACK_DOWN
	atk_down.base_value = 0.3  # -30% attack
	atk_down.base_duration = 2
	atk_down.is_debuff = true
	s2.status_effect_templates.append(atk_down)
	
	var s3 = SkillTemplate.new()
	s3.skill_name = "Void Collapse"
	s3.skill_id = "void_collapse"
	s3.skill_type = Skill.SkillType.DAMAGE
	s3.target_type = Skill.TargetType.ALL_ENEMIES
	s3.element = Character.Element.VOID
	s3.base_multiplier = 2.0
	s3.base_cooldown = 6
	s3.attack_scaling = 1.3
	s3.description = "Devastating void magic that ignores some defense"
	
	template.skill_templates = [s1, s2, s3]
	character_templates.append(template)

func _create_water_healer():
	var template = CharacterTemplate.new()
	template.character_name = "Water Priestess"
	template.character_id = "water_priestess_001"
	template.description = "A gentle healer with the power of water"
	template.element = Character.Element.WATER
	template.rarity = Character.Rarity.RARE
	template.character_class = CharacterTemplate.CharacterClass.HEALER
	
	template.base_hp = 110
	template.base_attack = 18
	template.base_defense = 15
	template.base_speed = 80
	template.base_crit_chance = 0.10
	template.base_crit_damage = 1.4
	
	# Skills de soporte y curación
	var s1 = SkillTemplate.new()
	s1.skill_name = "Healing Wave"
	s1.skill_id = "healing_wave"
	s1.skill_type = Skill.SkillType.HEAL
	s1.target_type = Skill.TargetType.SINGLE_ALLY
	s1.element = Character.Element.WATER
	s1.base_multiplier = 1.5
	s1.attack_scaling = 1.0
	s1.description = "Restore ally's HP"
	
	var s2 = SkillTemplate.new()
	s2.skill_name = "Purifying Rain"
	s2.skill_id = "purifying_rain"
	s2.skill_type = Skill.SkillType.HEAL
	s2.target_type = Skill.TargetType.ALL_ALLIES
	s2.element = Character.Element.WATER
	s2.base_multiplier = 1.0
	s2.base_cooldown = 4
	s2.attack_scaling = 0.8
	s2.description = "Heal all allies and remove debuffs"
	
	var s3 = SkillTemplate.new()
	s3.skill_name = "Tidal Blessing"
	s3.skill_id = "tidal_blessing"
	s3.skill_type = Skill.SkillType.BUFF
	s3.target_type = Skill.TargetType.ALL_ALLIES
	s3.element = Character.Element.WATER
	s3.base_cooldown = 5
	s3.cr_boost_allies = 20.0  # +20% CR a todos los aliados
	s3.description = "Grant speed boost and CR to all allies"
	
	# Speed buff
	var speed_buff = StatusEffectTemplate.new()
	speed_buff.effect_name = "Water's Grace"
	speed_buff.effect_type = StatusEffect.EffectType.SPEED_UP
	speed_buff.base_value = 0.3  # +30% speed
	speed_buff.base_duration = 3
	speed_buff.is_debuff = false
	s3.status_effect_templates.append(speed_buff)
	
	template.skill_templates = [s1, s2, s3]
	character_templates.append(template)

func _create_fire_berserker():
	var template = CharacterTemplate.new()
	template.character_name = "Flame Berserker"
	template.character_id = "flame_berserker_001"
	template.description = "A wild warrior consumed by flames"
	template.element = Character.Element.FIRE
	template.rarity = Character.Rarity.EPIC
	template.character_class = CharacterTemplate.CharacterClass.WARRIOR
	
	template.base_hp = 100
	template.base_attack = 35
	template.base_defense = 10
	template.base_speed = 90
	template.base_crit_chance = 0.25
	template.base_crit_damage = 1.7
	
	# Skills agresivos con auto-daño
	var s1 = SkillTemplate.new()
	s1.skill_name = "Flame Strike"
	s1.skill_id = "flame_strike"
	s1.skill_type = Skill.SkillType.DAMAGE
	s1.target_type = Skill.TargetType.SINGLE_ENEMY
	s1.element = Character.Element.FIRE
	s1.base_multiplier = 1.3
	s1.attack_scaling = 1.0
	s1.description = "Fiery attack with burn chance"
	
	# Burn effect
	var burn = StatusEffectTemplate.new()
	burn.effect_name = "Burn"
	burn.effect_type = StatusEffect.EffectType.BURN
	burn.base_value = 0.08  # 8% max HP per turn
	burn.base_duration = 2
	burn.is_debuff = true
	s1.status_effect_templates.append(burn)
	s1.effect_chance = 0.5
	
	template.skill_templates.append(s1)
	character_templates.append(template)

func _create_earth_guardian():
	var template = CharacterTemplate.new()
	template.character_name = "Earth Guardian"
	template.character_id = "earth_guardian_001"
	template.description = "An immovable protector of nature"
	template.element = Character.Element.EARTH
	template.rarity = Character.Rarity.RARE
	template.character_class = CharacterTemplate.CharacterClass.TANK
	
	template.base_hp = 160
	template.base_attack = 15
	template.base_defense = 25
	template.base_speed = 60
	template.base_crit_chance = 0.08
	template.base_crit_damage = 1.3
	
	character_templates.append(template)

func get_template_by_id(character_id: String) -> CharacterTemplate:
	for template in character_templates:
		if template.character_id == character_id:
			return template
	return null

func get_templates_by_element(element: Character.Element) -> Array[CharacterTemplate]:
	return character_templates.filter(func(template): return template.element == element)

func get_templates_by_rarity(rarity: Character.Rarity) -> Array[CharacterTemplate]:
	return character_templates.filter(func(template): return template.rarity == rarity)

func get_random_template(rarity_filter: Character.Rarity = Character.Rarity.COMMON) -> CharacterTemplate:
	var filtered_templates = get_templates_by_rarity(rarity_filter)
	if filtered_templates.is_empty():
		filtered_templates = character_templates
	
	if filtered_templates.is_empty():
		return null
	
	return filtered_templates[randi() % filtered_templates.size()]
