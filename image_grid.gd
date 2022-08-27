

# inspired by:
#   https://github.com/aMOPel/godot-grid/blob/master/addons/grid/Grid.gd
#   

class_name ImageGrid extends Container

@export var rows : int = 1
@export var cols: int = 1

@export var h_separation : int = 0
@export var v_separation : int = 0

var images : Array  # TextureRects
var center : int # index of the image to place at the center of the grid
var _start : int # start index of visible image
var _end : int # end index of visible images

func _init():
	pass


# Called when the node enters the scene tree for the first time.
func _ready():
	updateGridGUI()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _notification(what):
	if what == Container.NOTIFICATION_SORT_CHILDREN:
		_update_child_visiblity()
		_resize_images()


# grid_size == 0 : leave as current size
# grid_size > 0: set to grid size
# grid_size < 0: set grid size based on number of images, such that they all fit on screen
func set_images(new_images : Array, grid_size : int = 0, center_idx : int = 0) -> void:
	if grid_size > 0:
		set_grid(grid_size)
	if grid_size < 0:
		pass # TODO: set grid size based on number of images, such that they all fit on screen
	
	if center_idx == 0:
		center = floor(new_images.size() / 2)
	else:
		center = center_idx
		
	# clean up and remove everything
	clear_grid()
	images.clear()
	
	# create all textures for all images
	for img in new_images:
		add_image(img)
	
	queue_sort()


func _create_texture(imageTex : Texture2D) -> TextureRect:
	print("_create_texture", imageTex)
	var t = TextureRect.new()
	t.ignore_texture_size = true
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.texture = imageTex

	#t.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE)
	#t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	#t.size_flags_vertical = Control.SIZE_EXPAND_FILL
	#t.anchor_left = 0.5
	return t


func add_image(imageTex : Texture2D) -> void:
	print("add_image", imageTex)
	var t = _create_texture(imageTex)
	var image_idx = images.size()
	var child_idx = get_child_count()

	t.gui_input.connect(func on_input(event: InputEvent):
		if event is InputEventMouseButton:
			if event.pressed:
				var metainfo = Dictionary()
				for key in t.texture.get_meta_list():
					metainfo[key] = t.texture.get_meta(key)
				printt("image", image_idx, child_idx, metainfo)
	)
	
	images.append(t)
	add_child(t)


func clear_grid():
	# remove existing children
	for n in get_children():
		remove_child(n)
		n.queue_free()


# Ses the rows and columns, default to same number cols and rows
func set_grid(rows_ : int, cols_ : int = 0) -> void:
	if rows <= 0:
		assert(false, "set_grid() rows <= 0")
		rows = 1
	rows = rows_
	if cols_ <= 0:
		cols_ = rows_
	cols = cols_
	_update_child_visiblity()
	updateGridGUI()
	queue_sort()
	

func updateGridGUI() -> void:
	if %RowsSpinBox.value != rows:
		%RowsSpinBox.value = rows
	if %ColsSpinBox.value != cols:
		%ColsSpinBox.value = cols


# adds all images as child nodes, sets visible on images based on grid size and center
func _add_children() -> void:
	for node in images:
		add_child(node)


func _update_child_visiblity() -> void:
	if images.size() < 2: return
	
	var visible_imgs = rows * cols
	_start = maxi(center - visible_imgs / 2 - 1, 0)
	_end = mini(_start + visible_imgs, images.size())
	assert(_start < _end, "image visibility start is >= end")
	if visible_imgs != _end - _start:
		printt("not enough images to display all", visible_imgs, _start, _end, _end - _start)
		
	for i in get_child_count():
		if i >= _start and i < _end:
			get_child(i).visible = true
		else:
			get_child(i).visible = false


func _resize_images() -> void:
	var h_spaces = 0
	if cols > 1:
		h_spaces = (size.x / cols - 1) * h_separation
	var v_spaces = 0
	if rows > 1:
		v_spaces = (size.y / rows - 1) * v_separation
	var img_w = floor((size.x - h_spaces) / cols)
	var img_h = floor((size.y - v_spaces) / rows)
	var img_size = Vector2(img_w, img_h)
	#print(size, "img_size: ", img_size)
	
	var positions := Array()
	for r in rows:
		for c in cols:
			positions.append( Vector2(c * img_size.x + c * v_separation, r * img_size.y + r * h_separation) )
	
	var i = 0
	for child_idx in range(_start, _end):
		#printt("pos", i, child_idx, positions[i])
		fit_child_in_rect(get_child(child_idx), Rect2(positions[i], img_size))
		i += 1



func _on_row_spin_box_value_changed(value):
	if value != rows:
		if %GridAspectLocked.button_pressed:
			var c : int
			if rows == cols:
				c = value
			else:
				c = floor(value / rows * cols)
			set_grid(value, c)
		else:
			set_grid(value, cols)


func _on_cols_spin_box_value_changed(value):
	if value != cols:
		if %GridAspectLocked.button_pressed:
			var r : int
			if rows == cols:
				r = value
			else:
				r = floor(value / cols * rows)
			set_grid(r, value)
		else:
			set_grid(rows, value)


func _on_grid_aspect_locked_check_button_toggled(button_pressed):
	if button_pressed and rows != cols:
		set_grid(rows, rows)
