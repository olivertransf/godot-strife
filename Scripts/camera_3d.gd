extends Camera3D

@export var follow_offset := Vector3(0, 2, 4)
@export var follow_speed := 6.0

var target: Player

@onready var main := get_parent()

func _ready() -> void:
	main.turn_ended.connect(_on_turn_end)

func _process(delta: float) -> void:
	if target == null:
		return

	var desired := target.global_position + follow_offset
	global_position = global_position.lerp(desired, delta * follow_speed)
	look_at(target.global_position, Vector3.UP)

func _on_turn_end(player: Player) -> void:
	target = player
