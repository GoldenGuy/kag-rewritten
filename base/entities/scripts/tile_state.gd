extends GDScript
class_name TileState

### Metadata
var tile
### ---

### Data
var map_position
var world_position
### ---

### Behavior
var behavior
### ---

func _init(t_tile):
	if t_tile.must_instantiate:
		tile = t_tile.duplicate()
	else:
		tile = t_tile

	if tile.tile_behavior is GDScript:
		behavior = tile.tile_behavior.new(self)

func _add_to_tilemap(t_tilemap: TileMap, x, y):
	map_position = Vector2(x, y)
	world_position = t_tilemap.map_to_world(map_position)

	if tile.must_instantiate:
		tile.global_position = world_position
		t_tilemap.add_child(tile)
	else:
		t_tilemap.set_cellv(map_position, tile.tileset_id)
