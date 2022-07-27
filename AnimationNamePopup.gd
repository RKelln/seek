extends Popup


func _on_name_text_edit_text_changed():
	if $NamePanel/NameVBoxContainer/NameTextEdit.text == "":
		$NamePanel/NameVBoxContainer/Button.disabled = true


func set_default_name(animation_name : String) -> void:
	$NamePanel/NameVBoxContainer/NameTextEdit.text = animation_name
