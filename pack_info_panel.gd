extends Panel

@export var pack_name : String
@export var sequences : PackedStringArray
@export var frames : int
@export var save_path : String
@export var frame_counts : Dictionary
@export var fps : Dictionary

# Called when the node enters the scene tree for the first time.
func _ready():
	%NumberLabel.text = str(get_index() + 1)
	%PackLabel.text = pack_name
	%FramesLabel.text = str(frames)
	%AnimLabel.text = str(sequences.size())
	%PathLabel.text = save_path


# set values from a images see images.info()
func set_values(details : Dictionary) -> void:
	pack_name = details.pack_name
	sequences = PackedStringArray(details.sequences)
	frames = details.frames
	save_path = details.save_path
	frame_counts = details.frame_counts
	if fps in details:
		fps = details.fps


func create_entry(key : String, value : Variant, index : int = -1) -> void: 
	var key_node = Label.new()
	key_node.text = key
	var value_node = Label.new()
	key_node.text = str(value)
	$MarginContainer/VBoxContainer/GridContainer
