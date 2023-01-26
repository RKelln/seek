extends Node

class_name CustomController

enum Mode {OFF, ON, TEST}

@export var mode : Mode = Mode.OFF
@export var sensitivity : float = 1.0


func _unhandled_input(event: InputEvent) -> void:
	if mode == Mode.OFF: return
	
	if mode == Mode.TEST:
		if not event is InputEventMouseMotion:
			print(event)

	_handle_input(event)


func _handle_input(event : InputEvent) -> void:
	print("CustomController _handle_input", event)
	pass


func linear_to_relative(value : float, increment : float, vmin : float, vmax : float, to_emit : Signal, out_min : float = 0.0, out_max : float = 1.0) -> float:
	value = clampf(value + (increment * sensitivity), vmin, vmax)
	to_emit.emit( remap(value, vmin, vmax, out_min, out_max) )
	return value
