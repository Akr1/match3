extends Node2D


# Grid Variables
export (int) var width;
export (int) var height;
export (int) var x_start;
export (int) var y_start;
export (int) var offset;

#Empty array
var all_pieces = [];


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func make_2d_array():
	var array = [];
	#This is a for loop that means from 0 to width-1
	for i in width:
		array.append([]);
		for j in height:
			array[i].append(null);
	return array;
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
