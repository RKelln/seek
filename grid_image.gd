extends TextureRect

func _ready():
	ignore_texture_size = true
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED


func _get_drag_data(position : Vector2) -> Variant:
	var mydata = texture
	
	var tr = TextureRect.new()
	tr.texture = texture
	tr.ignore_texture_size = true
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.size = size
	#printt("texture size",  size, texture.get_size())
	set_drag_preview(tr)
	
	return get_index()


func _gui_input(event) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			var metainfo = Dictionary()
			for key in texture.get_meta_list():
				metainfo[key] = texture.get_meta(key)
			printt("image", get_index(), metainfo)

		if event.double_click:
			get_parent().center = get_index()
