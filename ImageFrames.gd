class_name ImageFrames extends SpriteFrames

const base_animation_name : StringName = "default"
const animation_meta_key : StringName = "animation_index"
const flags_meta_key : StringName = "frame_flags"

var version := "1.0"

@export var compress := true
@export var pack_name : String = "":
	get:
		return pack_name
	set(value):
		pack_name = ImageFrames.normalize_name(value)

@export var stretch := true
@export var fps : float  = 1.0  # default fps 

# shared by all sequences
var tags : Dictionary = {} : set  = set_tags
var flags : PackedInt64Array = PackedInt64Array() : set = set_flags
var mapping : TagFlagKeyMap : set = set_mapping
var neighbours : Array[Sequence] : set = set_neighbours

var sequences : Dictionary = {}


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


func get_base_frame_count() -> int:
	return get_frame_count(base_animation_name)


func get_all_fps() -> Dictionary:
	var all_fps = {}
	for anim in get_animation_names():
		all_fps[anim] = get_animation_speed(anim)
	return all_fps


func get_fps(animation_name : String) -> float:
	return get_all_fps()[animation_name]


func get_valid_animation_names() -> PackedStringArray:
	var names := get_animation_names()
	var i = names.find(base_animation_name)
	names.remove_at(i)
	return names

# FIXME: this only works for new animations in the same ImageFrames
func add_frames(new_frames : ImageFrames, animation_name : String = '', offset : int = 0) -> void:
	assert(new_frames.has_animation(base_animation_name))
	
	var animation_names : Array
	if animation_name == "":
		animation_names = new_frames.get_animation_names()
	else:
		animation_names = [animation_name]
	
	for aname in animation_names:
		if aname != base_animation_name:
			if get_animation_names().has(aname):
				printt("Warning duplicate animation names:", aname)
				# TODO: prefix with pack name unless name is default?
				continue
			else:
				add_animation(aname)
			
			set_animation_loop(aname, new_frames.get_animation_loop(aname))
			set_animation_speed(aname, new_frames.get_animation_speed(aname))
			
		for i in new_frames.get_frame_count(aname):
			_add_frame(aname, i+offset, new_frames.get_frame(aname, i))


func update_frames(animation_name : String, new_sequence : PackedInt32Array) -> void:
	# rebuid an imation based  on frame meta index
	if not has_animation(animation_name):
		print("update_frames(): no animation with name: ", animation_name)
		return
	if animation_name == base_animation_name:
		print("update_frames(): cannot update base animation sequence")
		return
		
	clear(animation_name)
	for i in new_sequence.size():
		var index = new_sequence[i]
		_add_frame(animation_name, index, get_frame_texture(base_animation_name, index))
	
	
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
		_add_frame(to_animation, i, get_frame_texture(from_animation, i))
	
	
func info() -> Dictionary:
	var current_info := {
		'pack_name' : pack_name,
		'frames': get_base_frame_count(),
		'sequences': get_animation_names(),
		'frame_counts': get_frame_counts(),
		'fps': get_all_fps()
	}
	print(current_info)
	for i in get_base_frame_count():
		if i != get_frame_texture(base_animation_name, i).get_meta(animation_meta_key):
			printt("index mismatch:", i, get_frame_texture(base_animation_name, i).get_meta(animation_meta_key))
	return current_info


func create_frames(image_paths: Array, animation_name : String, loaderFn) -> void:
	var start := Time.get_ticks_msec()

	_create_animation(animation_name)
		
	for i in image_paths.size():
		#print("Loading ", image_path)
		_add_frame(animation_name, i, loaderFn.call(image_paths[i]))
	print("Loading time (sec): ", (Time.get_ticks_msec() - start) / 1000.0 )


func create_frames_timed(image_paths: Array, animation_name : String, loaderFn, max_duration_ms : float) -> Texture2D:
	_create_animation(animation_name)
	
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


func _create_animation(animation_name : String, anim_fps : float = fps):
	if not get_animation_names().has(animation_name):
		add_animation(animation_name)
		set_animation_speed(animation_name, anim_fps)


# NOTE: i is the index of the base animation
func _add_frame(animation_name : String, i : int, tex : Texture2D, flags : int = 0 ) -> void:
	assert(tex != null)
	# add index to meta if animation is base
	if animation_name == base_animation_name:
		tex.set_meta(animation_meta_key, i)
		#tex.set_meta(flags_meta_key)
	elif i >= get_frame_count(base_animation_name):
		# ensure that it is added the base animation
		add_frame(base_animation_name, tex)
		tex.set_meta(animation_meta_key, i)
			
	if tex.get_meta(flags_meta_key) == null:
		tex.set_meta(flags_meta_key, flags)

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

# FIXME: update to new sequence format
func get_sequence_old(seq_name : String = base_animation_name) -> PackedInt32Array:
	if seq_name == "":
		seq_name = base_animation_name

	var seq = PackedInt32Array()
	#prints("get sequencee ", seq_name, get_frame(seq_name, 0).get_meta_list(), info())
	for i in get_frame_count(seq_name):
		# even though the meta index info is only added the the base animation, the texture should be reused
		# TODO: check if that is true for .res loaded ImageFrames
		var tex : Texture2D = get_frame_texture(seq_name, i)
		#printt(seq_name, i, tex, tex.get_meta_list())
		var index = tex.get_meta(animation_meta_key)
		assert(index != null)
		seq.append(index)
		
	return seq


func get_sequence(seq_name : String = base_animation_name) -> Sequence:
	return 


func add_sequence(seq_name : String, sequence : Sequence) -> void:
	# adds an new animation given frame indexs of the default an imation
	if seq_name in get_animation_names():
		printt("ImageFrames already has animation:", seq_name)
		return
	assert(base_animation_name in get_animation_names())
	assert(sequence.max_value() < get_base_frame_count())
	
	if sequence.size() != get_base_frame_count():
		printt("Warning sequence size", sequence.size(), "doesn't match number of base animation frames", get_base_frame_count())
	
	_create_animation(seq_name)
	
	for i in sequence.values:
		_add_frame(seq_name, i, get_frame_texture(base_animation_name, i))

	sequences[seq_name] = AnimatedSequence.from_Sequence(sequence, seq_name)


func set_tags(t : Dictionary):
	tags = t

func set_flags(f : PackedInt64Array):
	flags = f
	for s in sequences:
		sequences[s].flags = flags

func set_mapping(m : TagFlagKeyMap):
	mapping = m
	for s in sequences:
		sequences[s].mapping = mapping

func set_neighbours(n : Array[Sequence]):
	neighbours = n
	for s in sequences:
		if sequences[s] is AnimatedMultiSequence:
			sequences[s].neighbours = n
		elif sequences[s] is AnimatedSequence:
			sequences[s] = AnimatedMultiSequence.from_AnimatedSequence(sequences[s], n)
		else:
			assert(false, "Invalid sequence type for sequence: %s" % s)


static func normalize_name(name : String) -> StringName:
	return StringName(name.strip_edges().to_snake_case().validate_node_name())


static func combine_image_packs(packs : Array[ImageFrames]) -> ImageFrames:
	var combined := ImageFrames.new()
	# FIXME: lots of bugs here, hack workaround, add default animations
	# then just add the last animation
	var offsets : Array[int] = []
	var offset : int = 0
	for p in packs:
		offsets.append(offset)
		combined.add_frames(p, base_animation_name, offset)
		offset += p.get_base_frame_count()
	for i in packs.size():
		var anims : Array = packs[i].get_valid_animation_names()
		for anim_name in anims:
			combined.add_frames(packs[i], anim_name, offsets[i])
	
	return combined


static func load_image_pack(file_path : String) -> ImageFrames:
	var iframes : ImageFrames #= ResourceLoader.load(file_path, "ImageFrames")
	if iframes == null:
		iframes = ResourceLoader.load(file_path) as ImageFrames
	if iframes == null:
		iframes = load(file_path) as ImageFrames
	assert(iframes is ImageFrames)
	assert(iframes.get_animation_names().size() >= 1)
	
	# ensure normalized names
	for old_name in iframes.get_animation_names():
		var normalized := normalize_name(old_name)
		if old_name != normalized:
			iframes.rename_animation(old_name, normalized)
		
	# ensure default
	if not iframes.has_animation(base_animation_name):
		# use first animation:
		var animation_name = iframes.get_animation_names()[0]
		for i in iframes.get_frame_count(animation_name):
			iframes.add_animation(base_animation_name)
			iframes._add_frame(base_animation_name, i, iframes.get_frame(animation_name, i))
			
	# ensure the default has sequence info
	for i in iframes.get_frame_count(base_animation_name):
		var f = iframes.get_frame_texture(base_animation_name, i)
		if f.get_meta(animation_meta_key) == null:
			iframes.get_frame(base_animation_name, i).set_meta(animation_meta_key, i)
	return iframes


