class_name AwakeningMaterial
extends Resource

@export var material_name: String
@export var material_id: String
@export var rarity: MaterialRarity = MaterialRarity.COMMON
@export var required_amount: int = 1
@export var icon: Texture2D

enum MaterialRarity { COMMON, RARE, EPIC, LEGENDARY, MYTHIC }
