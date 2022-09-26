extends Window


func _input(event : InputEvent) -> void:
	
	if visible and event is InputEventKey and not event.pressed:
		printt("help", event)
		if event.is_action_released("ui_cancel"):
			hide()
		if event.is_action_released('help'):
			hide()


func hide() -> void:
	close_requested.emit()
