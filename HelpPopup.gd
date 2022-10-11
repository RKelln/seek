extends Window


func _input(event : InputEvent) -> void:
	if visible and event is InputEventKey and not event.pressed:
		if event.is_action_released("ui_cancel") or event.is_action_released('help'):
			close()

func close() -> void:
	close_requested.emit()
	hide()
