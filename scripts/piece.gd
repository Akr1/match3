extends Node2D
# Export means it is visible in the inspector
# Esto hace que la variable color sea visible en el inspector
export (String) var color;
#For use when we want to change texture based on bomb type
export (Texture) var row_texture
export (Texture) var column_texture
export (Texture) var adjacent_texture

var is_row_bomb = false
var is_column_bomb = false
var is_adjacent_bomb = false

var move_tween;
var matched = false;



# Called when the node enters the scene tree for the first time.
func _ready():
	move_tween = get_node("move_tween");
	pass # Replace with function body.

func move(target):
	# Sets a property of the tween node
	move_tween.interpolate_property(self, "position", position, target, .3, 
									Tween.TRANS_ELASTIC, Tween.EASE_OUT);
	move_tween.start();
	
func make_column_bomb():
	is_column_bomb = true
	$Sprite.texture = column_texture
	$Sprite.modulate = Color(1,1,1,1)

func make_row_bomb():
	is_row_bomb = true
	$Sprite.texture = row_texture
	$Sprite.modulate = Color(1,1,1,1)
	
func make_adjacent_bomb():
	is_adjacent_bomb = true
	$Sprite.texture = adjacent_texture
	$Sprite.modulate = Color(1,1,1,1)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
# This is called every frame
#func _process(delta):
#	pass

func dim():
	var sprite = get_node("Sprite");
	sprite.modulate = Color(1,1,1,.5);
	
