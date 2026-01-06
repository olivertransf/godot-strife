extends Node2D

@export var game_spaces: Array[Node]
@export var players: Dictionary[int, Sprite2D] = {}
var player_space_index: Dictionary[Sprite2D, int] = {}


@onready var turn_indicator: RichTextLabel = $Control/turn_indicator
var space_resolver := SpaceResolver.new()

var number_of_spaces: int
var current_space_index: int = 0
var turn_index: int = 0
var current_player: Sprite2D
var accept_input : bool = false

var space_type: Spaces.SpaceType

func _ready() -> void:
	randomize()
	
	var button := $Control/Spin
	button.pressed_to_main.connect(_on_button_pressed)

	number_of_spaces = game_spaces.size()

	# Fetch and assign players
	var fetched_players := get_tree().get_nodes_in_group("players")

	# Deterministic order (scene order)
	fetched_players.sort_custom(func(a, b):
		return a.get_index() < b.get_index()
	)

	for i in fetched_players.size():
		players[i] = fetched_players[i]
		
	for player in players.values():
		# Logical position starts at 1
		player_space_index[player] = 1
		
		# Visual position is the start node (index 0)
		player.global_position = game_spaces[0].global_position
		
		var name_label : RichTextLabel = player.get_node("player_name")
		name_label.clear()
		name_label.add_text(player.name)

	_set_current_player(0)
	accept_input = true

func _on_button_pressed() -> void:
	if accept_input:
		accept_input = false

		var spin = randi_range(1, 10)
		print(current_player.name, "rolled:", spin)

		await _move_player(spin, current_player)

		print("Turn Ended")
		_advance_turn()

		accept_input = true


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
	var current_index = player_space_index[player]
	var last_space_index = current_index

	while spin > 0 and current_index < number_of_spaces:
		var target_space = game_spaces[current_index]

		var tween = create_tween()
		tween.tween_property(
			player,
			"position",
			target_space.global_position,
			0.6
		).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

		await tween.finished

		current_index += 1
		spin -= 1
		last_space_index = current_index - 1

	# Save updated position
	player_space_index[player] = current_index

	# Check the space landed on after roll is complete
	if last_space_index < number_of_spaces:
		var landed_space = game_spaces[last_space_index] as Spaces
		if landed_space:
			await _handle_space(landed_space)
	else:
		print(player.name, "wins!")


func _handle_space(space: Spaces) -> void:
	space_resolver.handle_space(space, current_player)
