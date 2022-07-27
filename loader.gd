extends Node

var image_files
var images
var imagesScene

var default_image_compression = 0.7


# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder
func get_dir_contents(rootPath: String, extensions : Array = ["png", "jpg", "jpeg", "webp"]) -> Array:
	var files = Array()
	var directories = Array()
	var dir = Directory.new()

	if dir.open(rootPath) == OK:
		dir.list_dir_begin()
		_add_dir_contents(dir, files, directories, extensions)
		dir.list_dir_end()
	else:
		push_error("An error occurred when trying to access the path.")

	return [files, directories]


func _add_dir_contents(dir: Directory, files: Array, directories: Array, extensions: Array) -> void:
	var file_name = dir.get_next()

	# TODO: ensure lowercase extensions

	while (file_name != ""):
		var path = dir.get_current_dir() + "/" + file_name

		if dir.current_is_dir():
#            print("Found directory: %s" % path)
			var subDir = Directory.new()
			subDir.open(path)
			subDir.list_dir_begin()
			directories.append(path)
			_add_dir_contents(subDir, files, directories, extensions)
			subDir.list_dir_end()
		else:
#            print("Found file: %s" % path)
			if extensions.has(path.get_extension().to_lower()):
				files.append(path)

		file_name = dir.get_next()


func load_sequence_file(filename) -> PackedInt32Array:
	var data = PackedInt32Array()
	
	for line in _load_text_file(filename):
		data.append(line.to_int())
	return data
	
	
func _load_text_file(filename) -> PackedStringArray:
	var file = File.new()
	
	if file.file_exists(filename):
		file.open(filename, File.READ)
		var text := file.get_as_text()
		file.close()
		return text.split("\n", false)
	
	return PackedStringArray()

# return a float ratio to fit the object in the container
func _get_fit_ratio(container_size, object_size) -> float:
	if object_size.x > object_size.y:
		return container_size.x / object_size.x
	else:
		return container_size.y / object_size.y

func _get_new_size(container_size, object_size) -> Vector2i:
	var ratio = _get_fit_ratio(container_size, object_size)
	return Vector2i( int(ratio * object_size.x), int( ratio * object_size.y) )


func load_image(image_path: String, compress : float = default_image_compression) -> Image:
	var image = Image.load_from_file(image_path)
	assert(image != null and image is Image)
	
	# resize to max HD
#	if image.x > max_image_size.x or image.y > max_image_size.y:
#		var image_size = _get_new_size(Vector2(1920,1080), image.get_size())
#		image.resize(image_size.x, image_size.y, Image.INTERPOLATE_CUBIC)
	
	if not image.is_compressed() and compress > 0:
		image.compress(Image.COMPRESS_S3TC, Image.COMPRESS_SOURCE_SRGB, compress)
		
	return image


func load_texture(file_path : String, rescale : Vector2 = Vector2.ZERO) -> Texture:
	var texture : Texture
	if file_path.begins_with('res://'):
		texture = load(file_path)
	else: # load from external file
		texture = ImageTexture.create_from_image(load_image(file_path))
		assert(texture is ImageTexture)
		
		if rescale != Vector2.ZERO:
			if texture.get_width() < texture.get_height(): # portrait
				var viewscale = rescale.y / texture.get_height()
				if viewscale != 1.0:
					texture.set_size_override(Vector2(texture.get_width() * viewscale, texture.get_height() * viewscale))
			else: # landscape
				var viewscale = rescale.x / texture.get_width()
				if viewscale != 1.0:
					texture.set_size_override(Vector2(texture.get_width() * viewscale, texture.get_height() * viewscale))
	return texture


func _print_graphics_memory():
	print("Graphics memory (MB): ", String.humanize_size(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)))


func _parse_JSON(json_file) -> Array:
	var file = File.new()
	var json = JSON.new()
	var json_string : String
	
	if not file.file_exists(json_file):
		print("No file", json_file, "found")
		return Array()
		
	file.open(json_file, File.READ)
	json_string = file.get_as_text()
	file.close()

	var error = json.parse(json_string)
	if error == OK:
		var data_received = json.get_data()
		if typeof(data_received) == TYPE_DICTIONARY:
			return data_received
		else:
			print("Unexpected data")
	else:
		print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, " at line ", json.get_error_line())
	
	return Array()
	
	
func _init_node(nodeOrPath, defaultPath) -> Node:
	if nodeOrPath is Node:
		return nodeOrPath
	elif nodeOrPath is NodePath:
		return get_node(nodeOrPath)
	else:
		return get_parent().find_child(defaultPath)


func load_image_dir(animation_name, image_dir, max_images : int = 0, rescale : Vector2 = Vector2.ZERO ) -> Node:
	image_files = get_dir_contents(image_dir)[0]
	print("Found %d images in %s" % [image_files.size(), image_dir])
	assert(image_files.size() > 0)
	image_files.sort()
	if max_images > 0 and image_files.size() > max_images:
		image_files.resize(max_images) # take start of list only up to max_size
	
	var texture_loader = func(image_file):
		return load_texture(image_file, rescale)
	
	images.create_frames(image_files, animation_name, texture_loader)
	
	return images


func load_images(animation_name, image_files, max_images : int = 0, rescale : Vector2 = Vector2.ZERO ) -> Node:
	image_files.sort()
	if max_images > 0 and image_files.size() > max_images:
		image_files.resize(max_images) # take start of list only up to max_size
	
	var texture_loader = func(image_file):
		return load_texture(image_file, rescale)
	
	images.create_frames(image_files, animation_name, texture_loader)
	
	return images


# Called when the node enters the scene tree for the first time.
func _ready():
	imagesScene = load("res://images.tscn")
	images = imagesScene.instantiate()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass
	#load_next(current_animation)
