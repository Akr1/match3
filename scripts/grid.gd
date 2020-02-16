extends Node2D


# Grid Variables
export (int) var width;
export (int) var height;
export (int) var x_start;
export (int) var y_start;
export (int) var offset;

var possible_pieces = [
preload("res://scenes/yellow_piece.tscn"),
preload("res://scenes/blue_piece.tscn"),
preload("res://scenes/pink_piece.tscn"),
preload("res://scenes/orange_piece.tscn"),
preload("res://scenes/green_piece.tscn"),
preload("res://scenes/light_green_piece.tscn")
];

#The current pieces in the scene
var all_pieces = [];

# Touch variables
var first_touch = Vector2(0,0);
var final_touch = Vector2(0,0);

# Called when the node enters the scene tree for the first time.
func _ready():
	randomize();
	all_pieces = make_2d_array();
	spawn_pieces();

func make_2d_array():
	var array = [];
	#This is a for loop that means from 0 to width-1
	for i in width:
		array.append([]);
		for j in height:
			array[i].append(null);
	return array;

func spawn_pieces():
	for i in width:
		for j in height:
			#choose a random number and store it
			var rand = floor(rand_range(0, possible_pieces.size()));	
			var piece = possible_pieces[rand].instance();
			var loops = 0;
			while(match_at(i,j,piece.color) && loops < 100):
				rand = floor(rand_range(0,possible_pieces.size()));
				loops += 1;
				piece = possible_pieces[rand].instance();
			#Instance that piece from the array
			add_child(piece);
			piece.position = grid_to_pixel(i, j);
			all_pieces[i][j] = piece;
#Check to see what the column and row are and based on that check left, down or
#both
func match_at(i, j, color):
	
	if i > 1:
		if all_pieces[i-1][j] != null && all_pieces[i-2][j] != null:
			if all_pieces[i-1][j].color == color && all_pieces[i-2][j].color == color:
				return true;			
	if j > 1:
		if all_pieces[i][j-1] != null && all_pieces[i][j-2] != null:
			if all_pieces[i][j-1].color == color && all_pieces[i][j-2].color == color:
				return true;

#This function is used when populating the screen with the pieces
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column;
	var new_y = y_start + -offset * row;
	return Vector2(new_x, new_y);

func pixel_to_grid(pixel_x, pixel_y):
	#Based on var new_x = x_start + offset * column; from the above function,
	#Here we are trying to solve for column
	var new_x = round((pixel_x - x_start) / offset);	
	var new_y = round((pixel_y - y_start) / -offset);
	return Vector2(new_x, new_y);

func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		#Gets current mouse/touch position. Recuerda que asignaste ui_touch 
		#A left mouse click en settings.
		first_touch = get_global_mouse_position();
		#Check what piece is in that postion. 
		#To achieve this we have to convert the pixel coordinates to grid 
		#coordinates
		var grid_position = pixel_to_grid(first_touch.x, first_touch.y);
		print(grid_position);
	if Input.is_action_just_released("ui_touch"):
		final_touch = get_global_mouse_position();
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	touch_input();
