class_name BattleSystem
extends Node2D

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

@export var player: Character
@export var enemies: Array[Character]
@export var ui: Control
@export var skill_buttons_container: VBoxContainer
@export var targeting_ui: Control
@export var skill_preview_label: Label
@export var turn_order_container: VBoxContainer
@export var victory_label: Label
@export var defeat_label: Label
@export var turn_label: Label

var current_state: State = State.INIT:
	set(value):
		current_state = value
		if value != State.INIT:
			_on_state_changed(value)

var action_queue: Array[Dictionary] = []
var turn_queue: Array[Character] = []
var current_actor: Character = null
var pending_skill: Skill = null

func _ready() -> void:
	_connect_character_signals(player)
	for enemy in enemies:
		_connect_character_signals(enemy)
	rebuild_turn_queue()
	await run_battle()

func _connect_character_signals(character: Character) -> void:
	character.died.connect(_on_character_died)
	character.action_completed.connect(_on_action_completed)

func rebuild_turn_queue() -> void:
	turn_queue.clear()
	if player.is_alive:
		turn_queue.append(player)
	for enemy in enemies:
		if enemy.is_alive:
			turn_queue.append(enemy)
	turn_queue.sort_custom(func(a: Character, b: Character) -> bool:
		return a.stats.speed > b.stats.speed
	)
	update_turn_order_display()

func update_turn_order_display() -> void:
	for child in turn_order_container.get_children():
		child.queue_free()
	for i in range(turn_queue.size()):
		var lbl: Label = Label.new()
		lbl.text = "{0}. {1} (SPD: {2})".format([i + 1, turn_queue[i].name, turn_queue[i].stats.speed])
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
				await GlobalSignals.player_action_selected
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

func _on_skill_pressed(skill: Skill) -> void:
	if current_actor.current_mp >= skill.mp_cost:
		pending_skill = skill
		if skill.target_type == "self":
			current_actor.current_mp -= skill.mp_cost
			action_queue.append({
				"executor": current_actor,
				"target": current_actor,
				"skill": skill
			})
			GlobalSignals.player_action_selected.emit(skill.name)
		else:
			current_state = State.TARGET_SELECT

func _on_back_pressed() -> void:
	pending_skill = null
	current_state = State.PLAYER_SELECT

func _on_target_selected(target: Character) -> void:
	current_actor.current_mp -= pending_skill.mp_cost
	action_queue.append({
		"executor": current_actor,
		"target": target,
		"skill": pending_skill
	})
	GlobalSignals.player_action_selected.emit(pending_skill.name)
	pending_skill = null

func _queue_enemy_action(enemy_char: Character) -> void:
	var available_skills = enemy_char.stats.available_skills.filter(
		func(s: Skill): return enemy_char.current_mp >= s.mp_cost
	)
	if available_skills.is_empty():
		return
	# Prefer damaging skills unless HP is low
	var low_hp := float(enemy_char.current_hp) / float(enemy_char.stats.max_hp) <= 0.5
	var heal_skills: Array[Skill] = []
	var attack_skills: Array[Skill] = []
	for s in available_skills:
		if s.heal > 0:
			heal_skills.append(s)
		elif s.damage > 0:
			attack_skills.append(s)
	var skill: Skill = null
	# If low HP, prefer healing (if available)
	if low_hp and not heal_skills.is_empty():
		skill = heal_skills[randi() % heal_skills.size()]
	else:
		# Otherwise use damaging skills or random fallback
		if not attack_skills.is_empty():
			skill = attack_skills[randi() % attack_skills.size()]
		else:
			skill = available_skills[randi() % available_skills.size()]
	var target: Character = _select_enemy_target(enemy_char, skill)
	if target == null:
		return
	enemy_char.current_mp -= skill.mp_cost
	action_queue.append({
		"executor": enemy_char,
		"target": target,
		"skill": skill
	})

func _select_enemy_target(enemy_char: Character, skill: Skill) -> Character:
	match skill.target_type:
		"self":
			return enemy_char
		"enemy_single":
			return player if player.is_alive else null
		"ally_single":
			var alive_allies = enemies.filter(func(e: Character): return e.is_alive)
			if alive_allies.is_empty():
				return enemy_char
			var lowest_hp_ally: Character = alive_allies[0]
			for ally in alive_allies:
				if ally.current_hp < lowest_hp_ally.current_hp:
					lowest_hp_ally = ally
			return lowest_hp_ally
		"enemy_all":
			return player
		"ally_all":
			return enemy_char
		_:
			return player

func execute_action_queue() -> void:
	for action_data in action_queue.duplicate():
		var executor: Character = action_data["executor"]
		var target: Character = action_data["target"]
		var skill: Skill = action_data["skill"]
		if not executor.is_alive:
			continue
		await executor.perform_action(target, skill)
	action_queue.clear()

func _on_action_completed(_character: Character) -> void:
	pass

func _on_character_died(_character: Character) -> void:
	rebuild_turn_queue()

func _on_state_changed(state: State) -> void:
	reset_ui_visibility()
	match state:
		State.PLAYER_SELECT:
			_enter_player_select()
		State.TARGET_SELECT:
			_enter_target_select()
		State.CURRENT_TURN:
			_enter_current_turn()
		State.EXECUTE_ACTIONS:
			print("Executing actions...")
		State.RESOLVE:
			_enter_resolve()
		State.VICTORY:
			_show_battle_end("Victory!", "player")
		State.DEFEAT:
			_show_battle_end("Defeat!", "enemy")

func reset_ui_visibility() -> void:
	ui.visible = false
	targeting_ui.visible = false
	skill_preview_label.visible = false
	turn_order_container.visible = true
	victory_label.visible = false
	defeat_label.visible = false
	turn_label.visible = true
	turn_label.text = ""

func _enter_player_select() -> void:
	ui.visible = true
	turn_label.text = "Player's Turn"
	setup_skill_buttons()
	print("Player's turn - select action!")

func _enter_target_select() -> void:
	skill_preview_label.visible = true
	skill_preview_label.text = "Use {0}".format([pending_skill.name])
	setup_targeting_ui()
	targeting_ui.visible = true
	turn_label.text = "Select Target"
	print("Select target...")

func _enter_current_turn() -> void:
	if current_actor:
		turn_label.text = "{0}'s Turn".format([current_actor.name])
		print("{0}'s turn...".format([current_actor.name]))

func _enter_resolve() -> void:
	turn_label.text = "Resolving..."
	print("Resolving...")

func setup_skill_buttons() -> void:
	for child in skill_buttons_container.get_children():
		child.queue_free()
	for skill in player.stats.available_skills:
		var btn: Button = Button.new()
		btn.text = skill.name
		btn.disabled = player.current_mp < skill.mp_cost
		btn.pressed.connect(_on_skill_pressed.bind(skill))
		skill_buttons_container.add_child(btn)

func setup_targeting_ui() -> void:
	var vbox: VBoxContainer = targeting_ui.get_node("VBoxContainer")
	for child in vbox.get_children():
		child.queue_free()
	for enemy in enemies:
		if not enemy.is_alive:
			continue
		var btn: Button = Button.new()
		btn.text = "{0} (HP: {1})".format([enemy.name, enemy.current_hp])
		btn.pressed.connect(_on_target_selected.bind(enemy))
		vbox.add_child(btn)
	var back_btn: Button = Button.new()
	back_btn.text = "Back"
	back_btn.pressed.connect(_on_back_pressed)
	vbox.add_child(back_btn)

func _show_battle_end(text: String, winner: String) -> void:
	turn_order_container.visible = false
	turn_label.visible = false
	var label: Label = victory_label if winner == "player" else defeat_label
	label.visible = true
	label.text = text
	print(text)
	GlobalSignals.battle_ended.emit(winner)
