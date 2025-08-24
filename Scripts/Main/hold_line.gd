extends Sprite2D

var arrow: Node2D
var hold_duration: float

var speed: float
var direction: Vector2

func _process(delta):
	if arrow:
		hold_duration = arrow.hold_duration
	
	position += direction * speed * delta
	
	var tex_size = texture.get_size()
	var full_height = tex_size.y
	var region_height = hold_duration * full_height
	
	# Always center the region vertically
	var region_pos = Vector2(0, (full_height - region_height) / 2.0)
	var region_size = Vector2(region_height, tex_size.y)
	
	region_rect = Rect2(region_pos, region_size)
