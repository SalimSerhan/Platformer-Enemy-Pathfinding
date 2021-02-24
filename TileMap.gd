extends TileMap

#A tile object represents one tile on the map, along with a list of connections
class tile:
	var id # the id of this tile in the astar() object
	var cell
	var connections = []

	func _init(cell_, id_):
		id = id_
		cell = cell_

	func get_connection(target: Vector2):
		for c in connections:
			if c.tile.cell == target:
				return c
		return null

#A connection object represents how to reach a certain tile, from the tite that the object is instanced in.
#This object only makes sense when instanced within a tile
class connection:
	var tile # A reference to the tile that can be reached
	var type #0 = walk, 1 = jump
	var movespeed
	var jumpforce = 0 
	
	func _init(tile_, type_, movespeed_, jumpforce_):
		tile = tile_
		type = type_
		movespeed = movespeed_
		jumpforce = jumpforce_



const TILE_SIZE = 16

#This variable contains the graph. Each walkable tile will be represent by a tile object in this dictionary.
#The key is the map position of the tile
var tiles = Dictionary()

export(NodePath) var enemy_path
onready var enemy = get_node(enemy_path)

onready var movespeed = enemy.movespeed
onready var jumpforce = enemy.jumpforce
onready var gravity = enemy.gravity

var tile_point = Vector2()

var astar
onready var space_state = get_world_2d().direct_space_state

func _ready():
	#We initialize the grid, connect tiles the enemy can walk between, then calculate jump connections.
	#Finally, we put this information into the astar object
	_create_grid()
	_create_walking_connections()
	_create_jumping_connections()
	astar = _create_graph()


func get_the_path(from, to, with_jumps=true):
	var from_map_position = world_to_map(from)
	var to_map_position = world_to_map(to)
	

	if !(from_map_position in tiles) or !(to_map_position in tiles):
		return []
		
	var from_map_id = tiles[from_map_position].id
	var to_map_id = tiles[to_map_position].id
	
	var path_2d = []
	
	if from_map_id != null and to_map_id != null:
		var path_3d
		path_3d = astar.get_point_path(from_map_id, to_map_id)
	
		for p in path_3d:
			path_2d.append(Vector2(p.x, p.y))
	
	return path_2d


func get_cell_position_center(cell):
	return map_to_world(cell) + Vector2(TILE_SIZE/2,TILE_SIZE/2)


func _create_grid():
	var id = 0
	for cell in get_used_cells():
		var tile_pos = get_cell_position_center(cell)
		var intersection_bottom = space_state.intersect_point(tile_pos + Vector2(0, TILE_SIZE), 32, [enemy])
		var intersection_on_cell = space_state.intersect_point(tile_pos, 32, [enemy])
		if len(intersection_bottom)>0 and len(intersection_on_cell)==0:
			tiles[cell] = tile.new(cell, id)
			id += 1


func _create_walking_connections():
	for cell in tiles.keys():
		var right_cell = cell + Vector2(1, 0)
		var left_cell = cell + Vector2(-1, 0)
		if right_cell in tiles:
			tiles[cell].connections.append(connection.new(tiles[right_cell], 0, movespeed, 0))
			
		if left_cell in tiles:
			tiles[cell].connections.append(connection.new(tiles[left_cell], 0, -movespeed, 0))


func _create_jumping_connections():
	for cell in tiles.keys():
		for ms in [movespeed, -movespeed]:
				for jf in [0, 0.5*jumpforce, 0.75*jumpforce, jumpforce]:
					var p0 = get_cell_position_center(cell)
					
					#jf == 0 means this is a falling connection. Falling starts at the edges of platforms
					if jf==0:
						if ms > 0:
							p0.x += TILE_SIZE/2
						else:
							p0.x -= TILE_SIZE/2
							
					for i in range(0,10000):
						var step = i / 100.0
						#simulate the jumping trajectory using projectile motion
						var p = p0 + Vector2(ms * step, jf*step + 0.5*gravity*step*step)
						var tile_p = world_to_map(p)
						

						var transform = Transform2D(0.0, p)
						#Move the character we control along the calculated trajectory, checking for collisions
						var intersect = enemy.test_move(transform, Vector2(0,0))
						if intersect:
							#If there is a collision, and if 1) it's a walkable tile and 2) the collision is from above.
							#Then we have a valid jump connection
							#If these conditions are not met, it is an invalid trajectory
							if tile_p in tiles and space_state.intersect_point(p + Vector2(0, TILE_SIZE), 32, [enemy]):
								if tile_p.y != cell.y:
									tiles[cell].connections.append(connection.new(tiles[tile_p], 1, ms, jf))
							if tile_p != cell:
								break


func _create_graph(with_jumps=true) -> AStar:
	var astar = AStar.new()
	for tile in tiles.values():
		astar.add_point(tile.id, Vector3(tile.cell.x, tile.cell.y, 0))
	
	for tile in tiles.values():
		for c in tile.connections:
			astar.connect_points(tile.id, c.tile.id, false)
	return astar
