extends SpriteFrames

class_name ImageFrames

const base_animation_name : StringName = "default"
const animation_meta_key : StringName = "animation_index"

@export var compress := true
@export var pack_name : String = ""
@export var stretch := true

var version := "1.0"

func get_total_frame_count() -> int:
	var count := 0
	for anim in get_animation_names():
		count += get_frame_count(anim)
	return count


func get_frame_counts() -> Dictionary:
	var counts = {}
	for anim in get_animation_names():
		counts[anim] = get_frame_count(anim)
	return counts


func add_frames(new_frames : ImageFrames) -> void:
	for aname in new_frames.get_animation_names():
		if get_animation_names().has(aname):
			printt("Warning duplicate animation names:", aname)
			# TODO: prefix with pack name unless name is default?
			continue
		else:
			add_animation(aname)

		set_animation_loop(aname, new_frames.get_animation_loop(aname))
		set_animation_speed(aname, new_frames.get_animation_speed(aname))

		var offset = get_frame_count(base_animation_name)
		for i in new_frames.get_frame_count(aname):
			_add_frame(aname, offset + i, new_frames.get_frame(aname, i))


func update_frames(animation_name : String, new_sequence : PackedInt32Array) -> void:
	# rebuid an imation based  on frame meta index
	if not has_animation(animation_name):
		print("update_frames(): no animation with name: ", animation_name)
		return
	if animation_name == base_animation_name:
		print("update_frames(): cannot update base animation sequence")
		return
		
	clear(animation_name)
	for i in new_sequence:
		var index = new_sequence[i]
		_add_frame(animation_name, i, get_frame(base_animation_name, index))
	
	
func copy_frames(from_animation : String, to_animation : String) -> void:
	if not has_animation(from_animation):
		printt("copy frames(): no animation found to copy:", from_animation)
		return
	if has_animation(to_animation):
		printt("Warning overwriting animation:", to_animation, "with animation:", from_animation)
		clear(to_animation)
	else:
		add_animation(to_animation)
	
	set_animation_loop(to_animation, get_animation_loop(from_animation))
	set_animation_speed(to_animation, get_animation_speed(from_animation))
	
	for i in get_frame_count(from_animation):
		_add_frame(to_animation, i, get_frame(from_animation, i))
	
	
func info() -> Dictionary:
	return {
		'pack_name' : pack_name,
		'frames': get_total_frame_count(),
		'sequences': get_animation_names(),
		'frame_counts': get_frame_counts(),
	}


func create_frames(image_paths: Array, animation_name : String, loaderFn) -> void:
	var start := Time.get_ticks_msec()

	if not get_animation_names().has(animation_name):
		add_animation(animation_name)
		
	for i in image_paths.size():
		#print("Loading ", image_path)
		_add_frame(animation_name, i, loaderFn.call(image_paths[i]))
	print("Loading time (sec): ", (Time.get_ticks_msec() - start) / 1000.0 )


func create_frames_timed(image_paths: Array, animation_name : String, loaderFn, max_duration_ms : float) -> Texture2D:
	if not get_animation_names().has(animation_name):
		add_animation(animation_name)
	
	var start = Time.get_ticks_msec()
	var duration = 0.0
	var tex : Texture2D
	for i in range(get_frame_count(animation_name), image_paths.size()):
		tex =  loaderFn.call(image_paths[i])
		_add_frame(animation_name, i, tex)
		duration = (Time.get_ticks_msec() - start)
		if duration >= max_duration_ms:
			break
	return tex


func _add_frame(animation_name : String, i : int, tex : Texture2D ) -> void:
	# add index to meta if animation is base
	if animation_name == base_animation_name:
		tex.set_meta(animation_meta_key, i)
	add_frame(animation_name, tex) # add to end of animation


func save(file_path : String) -> int:
	print("Saving: ", file_path)
	var start := Time.get_ticks_msec()
	#printt(frames, frames.get_class(), ImageFrames.new().get_class())
	#frames = ImageFrames.new()
	#printt(frames, frames.get_class())
	#var result := ResourceSaver.save(frames, file_path, ResourceSaver.FLAG_CHANGE_PATH | ResourceSaver.FLAG_BUNDLE_RESOURCES)
	var result := ResourceSaver.save(self, file_path, ResourceSaver.FLAG_CHANGE_PATH)
	print("Saving time (sec): ", (Time.get_ticks_msec() - start) / 1000.0 )
	return result


func get_sequence(seq_name : String = base_animation_name) -> PackedInt32Array:
	if seq_name == "":
		seq_name = base_animation_name

	var seq = PackedInt32Array()
	print("get sequencee ", get_frame(seq_name, 0).get_meta_list())
	for i in get_frame_count(seq_name):
		# even though the meta index info is only added the the base animation, the texture should be reused
		# TODO: check if that is true for .res loaded ImageFrames
		var tex : Texture2D = get_frame(seq_name, i)
		printt(seq_name, i, tex, tex.get_meta_list())
		var index = tex.get_meta(animation_meta_key)
		assert(index != null)
		seq.append(index)
		
	return seq


static func load_image_pack(file_path : String) -> ImageFrames:
	var iframes : ImageFrames = ResourceLoader.load(file_path, "ImageFrames")
	if iframes == null:
		iframes = ResourceLoader.load(file_path) as ImageFrames
	if iframes == null:
		iframes = load(file_path) as ImageFrames
	assert(iframes is ImageFrames)
	assert(iframes.get_animation_names().size() >= 1)
	# ensure default
	if not iframes.has_animation(base_animation_name):
		# use first animation:
		var animation_name = iframes.get_animation_names()[0]
		for i in iframes.get_frame_count(animation_name):
			iframes.add_animation(base_animation_name)
			iframes._add_frame(base_animation_name, i, iframes.get_frame(animation_name, i))
			
	# ensure the default has sequence info
	for i in iframes.get_frame_count(base_animation_name):
		var f = iframes.get_frame(base_animation_name, i)
		if f.get_meta(animation_meta_key) == null:
			iframes.get_frame(base_animation_name, i).set_meta(animation_meta_key, i)
	return iframes


