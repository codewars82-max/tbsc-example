class_name BattleManager
extends Node2D

# Using an enum to define all possible battle phases.
# Each name is a constant automatically assigned an integer starting from 0.
enum State {
	INIT,
	PLAYER_SELECT,
	TARGET_SELECT,
	CURRENT_TURN,
	EXECUTE_ACTIONS,
	RESOLVE,
	VICTORY,
	DEFEAT
}

## --- Scene Nodes ---
@onready var player: Character = $Player
@onready var enemies: Array[Character] = [$Enemy, $Enemy2]
@onready var ui: Control = $CanvasLayer/UI
@onready var targeting_ui: Control = $CanvasLayer/TargetingUI
@onready var skill_preview_label: Label = $CanvasLayer/TargetingUI/SkillPreviewLabel
@onready var turn_order_container: VBoxContainer = $CanvasLayer/TurnOrderContainer
@onready var victory_label: Label = $CanvasLayer/VictoryLabel
@onready var defeat_label: Label = $CanvasLayer/DefeatLabel
@onready var turn_label: Label = $CanvasLayer/TurnLabel

## --- State ---
var current_state: State = State.INIT:
	set(value):
		current_state = value
		if value != State.INIT:
			_on_state_changed(value)

var action_queue: Array[Dictionary] = []
var turn_queue: Array[Character] = []
var current_actor: Character = null
var pending_skill_key: String = ""

## --- Skills ---
var skills: Dictionary = {
	"attack": {
		"name": "Attack", "damage": 25, "cast_time": 0.0, "mp_cost": 0, "target_type": "enemy_single"
	},
	"fireball": {
		"name": "Fireball", "damage": 40, "cast_time": 2.0, "mp_cost": 10, "target_type": "enemy_single"
	},
	"heal": {
		"name": "Heal", "heal": 30, "cast_time": 1.0, "mp_cost": 15, "target_type": "self"
	}
}

## --- Signals ---
# TODO possible place all signals and emit in autoload
signal player_action_selected(action: String)
signal battle_ended(winner: String)

## --- Setup ---
func _ready() -> void:
	player.died.connect(_on_character_died.bind("player"))
	for e in enemies:
		e.died.connect(_on_character_died.bind("enemy"))
	player.action_completed.connect(_on_action_completed)
	for e in enemies:
		e.action_completed.connect(_on_action_completed)
	
	# UI setup
	%AttackBtn.pressed.connect(_on_skill_pressed.bind("attack"))
	%FireballBtn.pressed.connect(_on_skill_pressed.bind("fireball"))
	%HealBtn.pressed.connect(_on_skill_pressed.bind("heal"))
	%BackBtn.pressed.connect(_on_back_pressed)
	
	ui.visible = false
	targeting_ui.visible = false
	skill_preview_label.visible = false
	turn_order_container.visible = true
	victory_label.visible = false
	defeat_label.visible = false
	turn_label.visible = true
	turn_label.text = ""
	
	rebuild_turn_queue()
	update_turn_order_display()
	
	await run_battle()

## --- Turn System ---
func rebuild_turn_queue() -> void:
	turn_queue.clear()
	if player.is_alive:
		turn_queue.append(player)
	for e in enemies:
		if e.is_alive:
			turn_queue.append(e)
	turn_queue.sort_custom(func(a: Character, b: Character) -> bool: return a.speed > b.speed)
	update_turn_order_display()

func update_turn_order_display() -> void:
	for child in turn_order_container.get_children():
		child.queue_free()
	
	for i in range(turn_queue.size()):
		var lbl: Label = Label.new()
		lbl.text = "{0}. {1} (SPD: {2})".format([i + 1, turn_queue[i].name, turn_queue[i].speed])
		lbl.add_theme_font_size_override("font_size", 20)
		if i == 0:
			lbl.modulate = Color.RED
		turn_order_container.add_child(lbl)

func run_battle() -> void:
	print("Battle started!")
	while player.is_alive and enemies.any(func(e: Character) -> bool: return e.is_alive):
		for actor in turn_queue.duplicate():
			if not player.is_alive or not enemies.any(func(e: Character) -> bool: return e.is_alive):
				break
			
			current_actor = actor
			
			if current_actor == player:
				current_state = State.PLAYER_SELECT
				await player_action_selected
			else:
				current_state = State.CURRENT_TURN
				_queue_enemy_action(current_actor)
			
			current_state = State.EXECUTE_ACTIONS
			await execute_action_queue()
			
			current_state = State.RESOLVE
			await get_tree().create_timer(1.0).timeout
			
			rebuild_turn_queue()
	
	if player.is_alive:
		current_state = State.VICTORY
	else:
		current_state = State.DEFEAT

## --- Player Actions ---
func _on_skill_pressed(skill_key: String) -> void:
	var skill: Dictionary = skills[skill_key]
	var mp_cost: int = int(skill["mp_cost"])
	
	if player.current_mp >= mp_cost:
		pending_skill_key = skill_key
		ui.visible = false
		
		var target_type: String = str(skill["target_type"])
		if target_type == "self":
			player.current_mp -= mp_cost
			action_queue.append({"executor": player, "target": player, "skill": skill})
			player_action_selected.emit(skill_key)
		else:
			current_state = State.TARGET_SELECT
	else:
		print("Not enough MP for {0}!".format([str(skill["name"])]))

func _on_back_pressed() -> void:
	pending_skill_key = ""
	current_state = State.PLAYER_SELECT

func _on_target_selected(target: Character) -> void:
	var skill: Dictionary = skills[pending_skill_key]
	var mp_cost: int = int(skill["mp_cost"])
	player.current_mp -= mp_cost
	
	action_queue.append({"executor": player, "target": target, "skill": skill})
	player_action_selected.emit(pending_skill_key)
	targeting_ui.visible = false
	pending_skill_key = ""

## --- Enemy AI ---
func _queue_enemy_action(enemy_char: Character) -> void:
	var choice: String = "fireball" if randf() < 0.3 and enemy_char.current_mp >= int(skills["fireball"]["mp_cost"]) else "attack"
	var skill: Dictionary = skills[choice]
	var mp_cost: int = int(skill["mp_cost"])
	
	enemy_char.current_mp -= mp_cost
	action_queue.append({"executor": enemy_char, "target": player, "skill": skill})

## --- Execution ---
func execute_action_queue() -> void:
	for action_data in action_queue.duplicate():
		var executor: Character = action_data["executor"]
		var target: Character = action_data["target"]
		var skill: Dictionary = action_data["skill"]
		
		if not executor.is_alive:
			continue
		
		await executor.perform_action(target, skill)
	
	action_queue.clear()

## --- Event Handlers ---
func _on_action_completed(_character: Character) -> void:
	pass

func _on_character_died(_character: Character, _side: String) -> void:
	rebuild_turn_queue()

## --- State Machine ---
func _on_state_changed(state: State) -> void:
	match state:
		State.PLAYER_SELECT:
			ui.visible = true
			targeting_ui.visible = false
			skill_preview_label.visible = false
			turn_label.text = "Player's Turn"
			update_skill_buttons()
			print("Player's turn - select action!")
		State.TARGET_SELECT:
			ui.visible = false
			skill_preview_label.visible = true
			skill_preview_label.text = "Use {0}".format([str(skills[pending_skill_key]["name"])])
			setup_targeting_ui()
			targeting_ui.visible = true
			turn_label.text = "Select Target"
			print("Select target...")
		State.CURRENT_TURN:
			if current_actor:
				turn_label.text = "{0}'s Turn".format([current_actor.name])
				print("{0}'s turn...".format([current_actor.name]))
		State.EXECUTE_ACTIONS:
			targeting_ui.visible = false
			skill_preview_label.visible = false
			print("Executing actions...")
		State.RESOLVE:
			turn_label.text = "Resolving..."
			print("Resolving...")
		State.VICTORY:
			_handle_battle_end("Victory!", "player")
		State.DEFEAT:
			_handle_battle_end("Defeat!", "enemy")

## --- UI Helpers ---
func update_skill_buttons() -> void:
	%AttackBtn.disabled = player.current_mp < int(skills["attack"]["mp_cost"])
	%FireballBtn.disabled = player.current_mp < int(skills["fireball"]["mp_cost"])
	%HealBtn.disabled = player.current_mp < int(skills["heal"]["mp_cost"])

func setup_targeting_ui() -> void:
	var hbox: HBoxContainer = targeting_ui.get_node("HBoxContainer")
	for child in hbox.get_children():
		child.queue_free()
	
	for enemy in enemies:
		if not enemy.is_alive:
			continue
		var btn: Button = Button.new()
		btn.text = "{0} (HP: {1})".format([enemy.name, enemy.current_hp])
		btn.pressed.connect(_on_target_selected.bind(enemy))
		hbox.add_child(btn)

## --- Battle End ---
func _handle_battle_end(text: String, winner: String) -> void:
	ui.visible = false
	targeting_ui.visible = false
	turn_order_container.visible = false
	turn_label.visible = false
	
	var label: Label = victory_label if winner == "player" else defeat_label
	label.visible = true
	label.text = text
	print(text)
	# Transition to a new scene after the battle has ended
	# get_tree().create_timer(3.0).timeout.connect(func(): get_tree().change_scene_to_file("res://MainMenu.tscn"))
	battle_ended.emit(winner)
