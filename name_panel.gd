extends Panel

signal response_submitted

var _fps_func

func _ready() -> void:
	# name
	%NameTextEdit.text_changed.connect(_on_name_text_edit_text_changed)
	%NameOKButton.pressed.connect(func(): response_submitted.emit(%NameTextEdit.text, _fps_func.call()))
	%NameOKButton.disabled = true
	
	# FPS
	_fps_func = fps
	var low_opacity = 0.4
	%SPFSpinBox.modulate.a = low_opacity
	%SPFLabel.modulate.a = low_opacity
	%FPSCheckButton.toggled.connect(func(button_pressed : bool):
		if button_pressed:
			_fps_func = spf
			%FPSSpinBox.modulate.a = low_opacity
			%FPSLabel.modulate.a = low_opacity
			%SPFSpinBox.modulate.a = 1.0
			%SPFLabel.modulate.a = 1.0
		else:
			_fps_func = fps
			%FPSSpinBox.modulate.a = 1.0
			%FPSLabel.modulate.a = 1.0
			%SPFSpinBox.modulate.a = low_opacity
			%SPFLabel.modulate.a = low_opacity
	)


func spf() -> float:
	return (1.0 / %SPFSpinBox.value)
	
func fps() -> float:
	return %FPSSpinBox.value


func _on_name_text_edit_text_changed():
	if %NameTextEdit.text == "":
		%NameOKButton.disabled = true
	else:
		%NameOKButton.disabled = false


func set_default_name(animation_name : String) -> void:
	%NameTextEdit.text = animation_name
	%NameOKButton.disabled = false

