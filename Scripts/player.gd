extends Sprite2D
class_name Player

var money: int = 200
var job: Job 

func _init(_job: Job = null):
	job = _job
