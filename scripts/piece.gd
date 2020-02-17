extends Node2D
# Export means it is visible in the inspector
# Esto hace que la variable color sea visible en el inspector
export (String) var color;
var move_tween;

# Declare member variables here. Examples:



# Called when the node enters the scene tree for the first time.
func _ready():
	move_tween = get_node("move_tween");
	pass # Replace with function body.

func move(target):
	# Sets a property of the tween node
	move_tween.interpolate_property(self, "position", position, target, .3, 
									Tween.TRANS_ELASTIC, Tween.EASE_OUT);
	move_tween.start();

# Called every frame. 'delta' is the elapsed time since the previous frame.
# This is called every frame
#func _process(delta):
#	pass
