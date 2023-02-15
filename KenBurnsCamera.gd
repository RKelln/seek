extends Camera2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	zoom.x = $DynamicMovement.process(delta)
	zoom.y = zoom.x
	
	position.x = $DynamicMovement2.process(delta)
	position.y = $DynamicMovement3.process(delta)
