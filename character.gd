class_name Character
extends Node2D

## --- Exports ---
@export var max_hp: int = 100
@export var max_mp: int = 50
@export var speed: int = 50

## --- Signals ---
# TODO possible place all signals and emit in autoload
signal action_completed(character: Character)
signal died(character: Character)

## --- Nodes ---
@onready var hp_label: Label = $HP_Label

## --- State ---
var is_alive: bool = true
var _current_hp: int
var _current_mp: int

## --- Properties ---
# GET/SET HP
var current_hp: int:
	get: return _current_hp
	set(value):
		# Ensure the new HP value stays within 0 and max_hp (prevents negative or overhealed values)
		_current_hp = clamp(value, 0, max_hp)
		_update_status_label()
		# TODO create separate fuction for this
		if _current_hp <= 0:
			die()
# GET/SET MP
var current_mp: int:
	get: return _current_mp
	set(value):
		# Ensure the new MP value stays within 0 and max_mp (prevents negative or overhealed values)
		_current_mp = clamp(value, 0, max_mp)
		_update_status_label()

## --- Lifecycle ---
func _ready() -> void:
	current_hp = max_hp
	current_mp = max_mp

## --- UI Update ---
func _update_status_label() -> void:
	if hp_label:
		# Update the HP/MP label using String.format()
		hp_label.text = "HP: {0}/{1}  MP: {2}/{3}".format([current_hp, max_hp, current_mp, max_mp])

## --- Core Logic ---
func die() -> void:
	if not is_alive:
		return
	is_alive = false
	# TODO possible place all signals and emit in autoload
	died.emit(self)
	
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.GRAY, 0.5)
	await tween.finished
	
	visible = false

func perform_action(target: Character, skill: Dictionary) -> void:
	# Flash yellow to indicate performing action
	modulate = Color.YELLOW
	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# Handle skill casting time
	var cast_time: float = skill.get("cast_time", 0.0)
	if cast_time > 0.0:
		var skill_name: String = str(skill.get("name", "Unknown"))
		# Check values
		print("{0} is casting {1} for {2}s...".format([name, skill_name, cast_time]))
		await get_tree().create_timer(cast_time).timeout
	
	# Apply damage or healing
	if skill.has("damage"):
		var dmg: int = int(skill["damage"])
		target.take_damage(dmg)
		# Check values
		print("{0} hits {1} for {2}!".format([name, target.name, dmg]))
	elif skill.has("heal"):
		var heal_amt: int = int(skill["heal"])
		target.current_hp += heal_amt
		# Check values
		print("{0} heals {1} for {2}!".format([name, target.name, heal_amt]))
	
	# Short delay before ending action
	await get_tree().create_timer(0.5).timeout
	modulate = Color.WHITE
	
	# Notify that the action is complete
	action_completed.emit(self)

func take_damage(amount: int) -> void:
	current_hp -= amount
