extends Node2D

@export var game_spaces: Array[Node]
@export var players: Dictionary[int, Sprite2D] = {}

var player_current_node: Dictionary[Sprite2D, Spaces] = {}

@onready var turn_indicator: RichTextLabel = $Control/turn_indicator
@onready var spin_button = $Control/Spin
@onready var timer: Timer = $Timer
var pending_fork_choice: int = -1


@onready var path_ui: Control = $"Control/PathUI/path_selector"
@onready var choice_1_btn: Button = $"Control/PathUI/path_selector/choice1"
@onready var choice_2_btn: Button = $"Control/PathUI/path_selector/choice2"
@onready var spin_number_text: RichTextLabel = $spin_number

var space_resolver := SpaceResolver.new()

var turn_index: int = 0
var current_player: Sprite2D
var accept_input: bool = false

var spin_preview_value: int = 1
var is_spinning: bool = false

signal fork_path_selected(choice_index: int)

func _ready() -> void:
	randomize()

	spin_button.pressed_to_main.connect(_on_button_pressed)
	timer.timeout.connect(_on_timer_timeout)

	choice_1_btn.pressed.connect(_on_fork_choice.bind(0))
	choice_2_btn.pressed.connect(_on_fork_choice.bind(1))

	path_ui.visible = false

	var fetched_players := get_tree().get_nodes_in_group("players")
	fetched_players.sort_custom(func(a, b): return a.get_index() < b.get_index())

	for i in fetched_players.size():
		players[i] = fetched_players[i]

	var start_node := game_spaces[0] as Spaces

	for player in players.values():
		player_current_node[player] = start_node
		player.global_position = start_node.global_position

		var name_label: RichTextLabel = player.get_node("player_name")
		name_label.clear()
		name_label.add_text(player.name)

	_set_current_player(0)
	accept_input = true

func _on_timer_timeout() -> void:
	if not is_spinning:
		return

	spin_preview_value += 1
	if spin_preview_value > 10:
		spin_preview_value = 1

	spin_number_text.clear()
	spin_number_text.add_text(str(spin_preview_value))

func _on_button_pressed() -> void:
	if not accept_input:
		return

	accept_input = false

	var current_node: Spaces = player_current_node[current_player]

	if current_node.next_spaces.size() > 1:
		spin_button.disabled = true
		path_ui.visible = true

		pending_fork_choice = await fork_path_selected

		path_ui.visible = false
		spin_button.disabled = false
	else:
		pending_fork_choice = -1

	# Spin logic continues here
	is_spinning = true
	timer.start()

	await get_tree().create_timer(1.0).timeout

	is_spinning = false
	timer.stop()

	var spin := randi_range(1, 10)
	spin_number_text.clear()
	spin_number_text.add_text(str(spin))

	await _move_player(spin, current_player)

	_advance_turn()
	accept_input = true

func _on_fork_choice(index: int) -> void:
	fork_path_selected.emit(index)

func _set_current_player(index: int) -> void:
	turn_index = index
	current_player = players[turn_index]
	turn_indicator.clear()
	turn_indicator.add_text(current_player.name)

func _advance_turn() -> void:
	turn_index += 1
	if turn_index >= players.size():
		turn_index = 0
	_set_current_player(turn_index)

func _move_player(spin: int, player: Sprite2D) -> void:
	var current_node: Spaces = player_current_node[player]

	for i in spin:
		var next_paths = current_node.next_spaces
		if next_paths.is_empty():
			break

		var target_node: Spaces

		if next_paths.size() == 1:
			target_node = current_node.get_node(next_paths[0]) as Spaces
		else:
			var choice := pending_fork_choice
			pending_fork_choice = -1

			if choice >= 0 and choice < next_paths.size():
				target_node = current_node.get_node(next_paths[choice]) as Spaces
			else:
				target_node = current_node.get_node(next_paths[0]) as Spaces

		var tween := create_tween()
		tween.tween_property(
			player,
			"position",
			target_node.global_position,
			0.6
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		await tween.finished

		current_node = target_node
		player_current_node[player] = current_node

	await _handle_space(current_node)


func _handle_space(space: Spaces) -> void:
	space_resolver.handle_space(space, current_player)
