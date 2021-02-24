extends Node2D

export(NodePath) var tilemap_path

onready var tilemap = get_node(tilemap_path)
var font;
export(NodePath) var enemy_path

func _ready():
	var label = Label.new()
	font = label.get_font("")
	label.queue_free()
	update()

func _draw():
	for tile in tilemap.tiles.values():
		draw_string(font, tilemap.map_to_world(tile.cell)+Vector2(0, 16), str(tile.id))

		for c in tile.connections:
			if c.movespeed > 0:
				draw_line(tilemap.get_cell_position_center(tile.cell), tilemap.get_cell_position_center(c.tile.cell), Color(0, 1, 0))
			else:
				draw_line(tilemap.get_cell_position_center(tile.cell), tilemap.get_cell_position_center(c.tile.cell), Color(1, 0, 0))
###
###
#	var x = -6
#	var y = 4
#	var p0 = tilemap.map_to_world(Vector2(x, y))+Vector2(8,8)
#
#	for i in range(0,1000):
#		var step = i / 10.0
#		var p = p0 + Vector2(tilemap.movespeed * step,
#		 tilemap.jumpforce*step + 0.5*tilemap.gravity*step*step)
#		draw_circle(p, 1, Color(1,0,0,1))
###
###func _process(delta):
###	pass
