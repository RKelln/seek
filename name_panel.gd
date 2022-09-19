extends Panel

signal response_submitted

func _ready() -> void:
	%NameTextEdit.text_changed.connect(_on_name_text_edit_text_changed)
	%NameOKButton.pressed.connect(func(): response_submitted.emit(%NameTextEdit.text))
	%NameOKButton.disabled = true
	

func _on_name_text_edit_text_changed():
	if %NameTextEdit.text == "":
		%NameOKButton.disabled = true
	else:
		%NameOKButton.disabled = false


func set_default_name(animation_name : String) -> void:
	%NameTextEdit.text = animation_name
	%NameOKButton.disabled = false

