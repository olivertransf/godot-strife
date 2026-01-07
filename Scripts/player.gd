extends Node3D
class_name Player

var color: Color

var money: int = 200
var job: Job 

var title: String
var age: int

var speed: int = 1

func _init(_job: Job = null):
	job = _job
