extends KinematicBody2D

#This code asks the tilemap for a path and follows it.
#It is fairly straightforward, with one exception
#When the enemy jumps, it should be in the middle of the tile, because this is
#where we calculate the jump trajectories from. If we don't, we risk the the enemy
#missing a jump.
#So, when the next action is a jump, we only let the enemy move on to the next point
#in the path when it's in the middle of target tile.
#We could do this also if the next action is a walk action, which would simplify the code
#However, this looks strange, because then it might land on a tile, walk right,
#Only to walk left again

export (float) var movespeed = 40.0
export (float) var jumpforce = -115.0
export (float) var gravity = 150.0
export(float) var knockback_force = 40.0
export(float) var x_acceleration = INF
export(float) var health = 5
var can_jump = true

var state = "seek_target"
var actual_movespeed = 0
var motion = Vector2()
var desired_motion = 0
var connection
var next_connection
var path_to_target = []

var target_cell

var moving_to_target = false
var has_moved = false
var old_target = Vector2()

export(NodePath) var tilemap_path
onready var tilemap = get_node(tilemap_path)

export(NodePath) var target_path
onready var target = get_node(target_path)

func _ready():
	update_path_to_target()

func _unhandled_input(event):
	if not event.is_action_pressed("Click"):
		return
	target.global_position = get_global_mouse_position()
	update_path_to_target()
	if len(path_to_target)>0:
		state = "seek_target"

func _handle_basic_movement(delta):
	if is_on_floor():
		motion.x = desired_motion
		
	motion.y += gravity*delta
	motion = move_and_slide(motion, Vector2(0, -1))

func _physics_process(delta):
	_handle_basic_movement(delta)
	if state == "seek_target":
		actual_movespeed = movespeed
		move_towards_target()
	elif is_on_floor():
		actual_movespeed = 0
		desired_motion = 0
		
		

func move_towards_target():
	var map_position = tilemap.world_to_map(position)
	var tile_position_center = tilemap.get_cell_position_center(map_position)
	
	var cell_center = tilemap.get_cell_position_center(connection.tile.cell)
	
	var margin = tilemap.TILE_SIZE/2
	if next_connection != null and next_connection.jumpforce!=0:
		margin = 1

	if (map_position != old_target and map_position in tilemap.tiles and is_on_floor()
	 and abs(position.x - cell_center.x)<=margin):
			update_path_to_target()
			has_moved = false
			
		
	if len(path_to_target)==0:
		return
	
	if has_moved and is_on_floor():
		if position.x > cell_center.x:
			move_left()
		else:
			move_right()
	
	if !has_moved:
		if connection.movespeed > 0:
			move_right()
		else:
			move_left()
		if connection.type == 1:
			jump(connection.jumpforce)
		has_moved = true

func update_path_to_target():
	path_to_target = tilemap.get_the_path(position, target.position, can_jump)
	next_connection = null
	if len(path_to_target)>1:
		moving_to_target = true
		connection = tilemap.tiles[path_to_target[0]].get_connection(path_to_target[1])
		if len(path_to_target)>2:
			next_connection = tilemap.tiles[path_to_target[1]].get_connection(path_to_target[2])
		old_target = path_to_target[0]
		path_to_target.remove(0)
	else:
		path_to_target.remove(0)
		moving_to_target = false
		state = "target_reached"

func move_right():
	desired_motion = actual_movespeed
	
func move_left():
	desired_motion = -actual_movespeed
	
func jump(force):
	motion.y = force

