class_name Character
extends Node2D

@export var stats: CharacterStats
@export var display_name: StringName = &""
@export var name_label: Label
@export var hp_label: Label

signal action_completed(character: Character)
signal died(character: Character)

var is_alive: bool = true

var current_hp: int:
	get: return _current_hp
	set(value):
		_current_hp = clamp(value, 0, stats.max_hp)
		_update_status_label()
		if _current_hp <= 0:
			die()

var current_mp: int:
	get: return _current_mp
	set(value):
		_current_mp = clamp(value, 0, stats.max_mp)
		_update_status_label()

var _current_hp: int
var _current_mp: int

func _ready() -> void:
	_current_hp = stats.max_hp
	_current_mp = stats.max_mp
	if name_label:
		name_label.text = display_name if display_name != &"" else name
	_update_status_label()

func _update_status_label() -> void:
	if hp_label:
		hp_label.text = "HP: {0}/{1} MP: {2}/{3}".format([current_hp, stats.max_hp, current_mp, stats.max_mp])

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	died.emit(self)
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.GRAY, 0.5)
	if name_label:
		tween.parallel().tween_property(name_label, "modulate", Color.GRAY, 0.5)
	await tween.finished
	visible = false

func perform_action(target: Character, skill: Skill) -> void:
	modulate = Color.YELLOW
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	var actor_name: StringName = display_name if display_name != &"" else name
	var target_name: StringName = target.display_name if target.display_name != &"" else target.name
	if skill.cast_time > 0.0:
		print("{0} is casting {1} for {2}s...".format([actor_name, skill.name, skill.cast_time]))
		await get_tree().create_timer(skill.cast_time).timeout
	if skill.damage > 0:
		var dmg: int = skill.damage
		target.take_damage(dmg)
		print("{0} hits {1} for {2}!".format([actor_name, target_name, dmg]))
	elif skill.heal > 0:
		var heal_amt: int = skill.heal
		target.current_hp += heal_amt
		print("{0} heals {1} for {2}!".format([actor_name, target_name, heal_amt]))
	await get_tree().create_timer(0.5).timeout
	modulate = Color.WHITE
	action_completed.emit(self)

func take_damage(amount: int) -> void:
	current_hp -= amount
