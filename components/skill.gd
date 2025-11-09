class_name Skill
extends Resource

@export var name: String = ""
@export_enum("self", "enemy_single", "enemy_all", "ally_single", "ally_all") var target_type: String = "enemy_single"
@export var mp_cost: int = 0
@export var cast_time: float = 0.0
@export var damage: int = 0
@export var heal: int = 0
