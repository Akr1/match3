extends Node2D

# State Machine
enum {wait, move}
var state;

# Grid Variables
export (int) var width;
export (int) var height;
export (int) var x_start;
export (int) var y_start;
export (int) var offset;
#how much above everything we want the piece to start
export (int) var y_offset;

#Obstacle variables
export (PoolVector2Array) var empty_spaces
export (PoolVector2Array) var ice_spaces
export (PoolVector2Array) var lock_spaces
export (PoolVector2Array) var concrete_spaces
export (PoolVector2Array) var slime_spaces
var damaged_slime = false

# Obstacle signals
signal damage_ice
signal make_ice
signal make_lock
signal damage_lock
signal make_concrete
signal damage_concrete
signal make_slime
signal damage_slime

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
var current_matches = []

# Swap back variables
var piece_one = null
var piece_two = null
var last_place = Vector2(0,0);
var last_direction = Vector2(0,0);
var move_check = false;

# Touch variables
var first_touch = Vector2(0,0);
var final_touch = Vector2(0,0);
#A flag that tells us if we are trying to control a piece or not
var controlling = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	state = move;
	randomize();
	all_pieces = make_2d_array();
	spawn_pieces()
	spawn_ice()
	spawn_locks()
	spawn_concrete()
	spawn_slime()
	
func restricted_fill(place):
	#Check the empty spaces
	if is_in_array(empty_spaces, place):
		return true
	if is_in_array(concrete_spaces, place):
		return true
	if is_in_array(slime_spaces, place):
		return true
	return false

func restricted_move(place):
	#Check the licorice pieces
	if is_in_array(lock_spaces, place):
		return true
	return false


func is_in_array(array, item):
	for i in array.size():
		if array[i] == item:
			return true
	return false

func remove_from_array(new_array, place):
	for i in range(new_array.size() - 1, -1, -1):
		if new_array[i] == place:
			new_array.remove(i)
	return new_array

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
			#Make sure its not a restricted movement place first
			if !restricted_fill(Vector2(i,j)):
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

func spawn_ice():
	for i in ice_spaces.size():
		emit_signal("make_ice", ice_spaces[i])

func spawn_locks():
	for i in lock_spaces.size():
		emit_signal("make_lock", lock_spaces[i])	

func spawn_concrete():
	for i in concrete_spaces.size():
		emit_signal("make_concrete", concrete_spaces[i])

func spawn_slime():
	for i in slime_spaces.size():
		emit_signal("make_slime", slime_spaces[i])

#Check to see what the column and row are and based on that check left, down or
#both for matches
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

func is_in_grid(grid_position):
	if grid_position.x >= 0 && grid_position.x < width:
		if grid_position.y >= 0 && grid_position.y < height:
			return true;
	return false;

func touch_input():
	if Input.is_action_just_pressed("ui_touch"):
		#Check if position of the mouse is actually in the grid
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)):
			first_touch = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y);
			controlling = true;
	if Input.is_action_just_released("ui_touch"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x,get_global_mouse_position().y)) && controlling:
			final_touch = pixel_to_grid(get_global_mouse_position().x,get_global_mouse_position().y);
			touch_difference(first_touch, final_touch);
		controlling = false;
			

#Swaps two pieces
func swap_pieces(column, row, direction):
	var first_piece = all_pieces[column][row];
	var other_piece = all_pieces[column + direction.x][row + direction.y];
	if first_piece != null && other_piece != null:
		if !restricted_move(Vector2(column, row)) && !restricted_move(Vector2(column, row) + direction):
			store_info(first_piece, other_piece, Vector2(column, row), direction);
			state = wait;
			all_pieces[column][row] = other_piece;
			all_pieces[column + direction.x][row + direction.y] = first_piece;
			first_piece.move(grid_to_pixel(column + direction.x, row + direction.y));
			other_piece.move(grid_to_pixel(column,row));
			if !move_check:
				find_matches();

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	#Move the previously swapped pieces back to its previous place
	if piece_one != null && piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = move;
	move_check = false
	pass


#Decides which piece is to move and in which direction it should move.
#Takes two arguments: First grid position(initial touch), and the final grid position.(release)
func touch_difference(grid_1, grid_2):	
	var difference = grid_2 - grid_1;
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1,0));
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1,0));
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0,1));
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0,-1));
# Called every frame. 'delta' is the elapsed time since the previous frame.
# warning-ignore:unused_argument
func _process(delta):
	if state == move:
		touch_input();
	
func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color;
				if i > 0 && i < width - 1:
					if !is_piece_null(i-1,j) && !is_piece_null(i+1,j):
						if all_pieces[i-1][j].color == current_color && all_pieces[i+1][j].color == current_color:
							match_and_dim(all_pieces[i-1][j])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i+1][j])
							add_to_array(Vector2(i,j))
							add_to_array(Vector2(i + 1, j))
							add_to_array(Vector2(i - 1, j))
				if j > 0 && j < height - 1:
					if !is_piece_null(i,j-1) && !is_piece_null(i,j+1):
						if all_pieces[i][j-1].color == current_color && all_pieces[i][j+1].color == current_color:
							match_and_dim(all_pieces[i][j-1])
							match_and_dim(all_pieces[i][j])
							match_and_dim(all_pieces[i][j+1])
							add_to_array(Vector2(i,j))
							add_to_array(Vector2(i, j+1))
							add_to_array(Vector2(i, j-1))
	get_parent().get_node("destroy_timer").start();

func is_piece_null(column, row):
	if all_pieces[column][row] == null:
		return true
	return false
	
#Adds item into an array if the value to be added is not currently in the array
# array_to_add = current_matches is the default value
func add_to_array(value, array_to_add = current_matches):
	if !array_to_add.has(value):
		array_to_add.append(value)

func match_and_dim(item):
	item.matched = true 
	item.dim()

func find_bombs():
	#Iterate over current_matches array
	for i in current_matches.size():
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		var current_color = all_pieces[current_column][current_row].color
		var col_matched = 0
		var row_matched = 0
		#Iterate over current_matches to check for column, row and color
		for j in current_matches.size():
			var this_column = current_matches[j].x
			var this_row = current_matches[j].y
			var this_color = all_pieces[current_column][current_row].color
			if this_column == current_column && current_color == this_color:
				col_matched += 1
			if this_row == current_row and this_color == current_color:
				row_matched += 1
			#Ordered in terms of priority
			if col_matched == 5 or row_matched == 5:
				print("color bomb")	
				return
			if col_matched == 3 and row_matched == 3:
				make_bomb(0,current_color)	
				return
			if col_matched == 4:
				make_bomb(1, current_color)
				return
			if row_matched == 4:
				make_bomb(2, current_color)
				return

				
func make_bomb(bomb_type, color):
	#iterate over current_matches
	for i in current_matches.size():
		#cache some variables
		var current_column = current_matches[i].x
		var current_row = current_matches[i].y
		if all_pieces[current_column][current_row] == piece_one and piece_one.color == color:
			#Convert piece_one into a bomb piece
			piece_one.matched = false
			change_bomb(bomb_type, piece_one)
		elif all_pieces[current_column][current_row] == piece_two and piece_two.color == color:
			#Turn piece_Two into a bomb
			piece_two.matched = false
			change_bomb(bomb_type, piece_two)

func change_bomb(bomb_type, piece):
	if bomb_type == 0:
		piece.make_adjacent_bomb()
	elif bomb_type == 1:
		piece.make_row_bomb()
	elif bomb_type == 2:
		piece.make_column_bomb()

# Checks if there are matched pieces, if there are, it will
#destroy them from the queue
func destroy_matched():
	find_bombs()
	var was_matched = false;
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					damage_special(i,j)
					was_matched = true;
					all_pieces[i][j].queue_free(); 
					all_pieces[i][j] = null;
	move_check = true
	if was_matched:
		get_parent().get_node("collapse_timer").start();
	else:
		swap_back()
	current_matches.clear()

func check_concrete(column, row):
	#Check right
	if column < width - 1:
		emit_signal("damage_concrete", Vector2(column+1,row))
	#Check left
	if column > 0:
		emit_signal("damage_concrete", Vector2(column-1,row))
	#Check up
	if row < height - 1:
		emit_signal("damage_concrete", Vector2(column,row+1))
	#Check down
	if row > 0:
		emit_signal("damage_concrete", Vector2(column,row-1))
		
func check_slime(column, row):
	#Check right
	if column < width - 1:
		emit_signal("damage_slime", Vector2(column+1,row))
	#Check left
	if column > 0:
		emit_signal("damage_slime", Vector2(column-1,row))
	#Check up
	if row < height - 1:
		emit_signal("damage_slime", Vector2(column,row+1))
	#Check down
	if row > 0:
		emit_signal("damage_slime", Vector2(column,row-1))
		
func damage_special(column, row):
	emit_signal("damage_ice", Vector2(column,row))
	emit_signal("damage_lock", Vector2(column,row))
	check_concrete(column, row)
	check_slime(column, row)
	
					
func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null && !restricted_fill(Vector2(i,j)):
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i,j));
						all_pieces[i][j] = all_pieces[i][k];
						all_pieces[i][k] = null;
						break;
	get_parent().get_node("refill_timer").start();
						
func refill_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null && !restricted_fill(Vector2(i,j)):
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
				#-y_offset because coordinates start from upper left
				piece.position = grid_to_pixel(i, j - y_offset);
				piece.move(grid_to_pixel(i,j))
				all_pieces[i][j] = piece;
	after_refill();
	
	
#Cycles through the grid after a refill to check if new matches generated
func after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if match_at(i,j,all_pieces[i][j].color):
					find_matches();
					return
	if !damaged_slime:
		generate_slime()
	state = move
	move_check = false
	damaged_slime = false

func generate_slime():
	#Make sure there are currently slime pieces on board
	if slime_spaces.size() > 0:
		var slime_made = false
		var tracker = 0
		while !slime_made && tracker < 100:
			#Check a random slime block
			var random_num = floor(rand_range(0, slime_spaces.size()))
			var curr_x = slime_spaces[random_num].x
			var curr_y = slime_spaces[random_num].y
			var neighbor = find_normal_neighbor(curr_x,curr_y)
			if neighbor != null:
				#Convert neighbor block into slime block
				# remove that piece
				all_pieces[neighbor.x][neighbor.y].queue_free()
				#set it to null
				all_pieces[neighbor.x][neighbor.y] = null
				#Add this new spot to the array of slimes
				slime_spaces.append(Vector2(neighbor.x,neighbor.y))
				#Send signal to slime holder to make new slime
				emit_signal("make_slime", Vector2(neighbor.x,neighbor.y))
				slime_made = true
			tracker += 1

#Looks if any given piece or position has a normal tile up, down, right or left to it
func find_normal_neighbor(column, row):
	#Checks right
	if is_in_grid(Vector2(column+1, row)):
		if all_pieces[column + 1][row] != null:
			return Vector2(column+1,row)
	#Check left
	if is_in_grid(Vector2(column-1, row)):
		if all_pieces[column -1][row] != null:
			return Vector2(column-1,row)
	#Check up
	if is_in_grid(Vector2(column, row + 1)):
		if all_pieces[column][row + 1] != null:
			return Vector2(column,row + 1)
	#Check down
	if is_in_grid(Vector2(column, row-1)):
		if all_pieces[column][row - 1] != null:
			return Vector2(column,row-1)
	return null
func _on_destroy_timer_timeout():
	destroy_matched();


func _on_collapse_timer_timeout():
	collapse_columns();


func _on_refill_timer_timeout():
	refill_columns();


func _on_lock_holder_remove_lock(place):
	#iterate backwards to prevent out of range exception
	#Starts with size-1, goes down by -1 intervals without including -1
	lock_spaces = remove_from_array(lock_spaces,place)

		


func _on_concrete_holder_remove_concrete(place):
	concrete_spaces = remove_from_array(concrete_spaces,place)


func _on_slime_holder_remove_slime(place):
	damaged_slime = true
	slime_spaces = remove_from_array(slime_spaces,place)
