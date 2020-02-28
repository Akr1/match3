extends Node2D

signal remove_concrete

var concrete_pieces = []
var width = 8
var height = 10
var concrete = preload("res://scenes/concrete.tscn")

func _ready():
	pass

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


func _on_grid_make_concrete(board_position):
	if concrete_pieces.size() == 0:
		concrete_pieces = make_2d_array()
	var current = concrete.instance()
	add_child(current)
	current.position = Vector2(board_position.x * 64 + 64, -board_position.y * 64 + 800)
	concrete_pieces[board_position.x][board_position.y] = current



func _on_grid_damage_concrete(board_position):
	#Check first if the part of the array still exists
	if concrete_pieces[board_position.x][board_position.y] != null:
		concrete_pieces[board_position.x][board_position.y].take_damage(1)
		if concrete_pieces[board_position.x][board_position.y].health <= 0:
			concrete_pieces[board_position.x][board_position.y].queue_free()
			concrete_pieces[board_position.x][board_position.y] = null
			emit_signal("remove_concrete", board_position)
