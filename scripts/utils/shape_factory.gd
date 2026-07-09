class_name ShapeFactory
extends RefCounted
## Helpers for building simple colored collision shapes and sprites without art assets.


static func make_circle_body(radius: float, color: Color, z: int = 0) -> Dictionary:
	var visual := Polygon2D.new()
	visual.polygon = _circle_points(radius, 16)
	visual.color = color
	visual.z_index = z

	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	return {"visual": visual, "collision": collision}


static func make_rect_body(size: Vector2, color: Color, z: int = 0) -> Dictionary:
	var visual := Polygon2D.new()
	var half := size * 0.5
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	visual.color = color
	visual.z_index = z

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	return {"visual": visual, "collision": collision}


static func make_health_bar(width: float = 28.0, height: float = 4.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(width, height)
	bar.size = Vector2(width, height)
	bar.position = Vector2(-width * 0.5, -22.0)
	bar.show_percentage = false
	bar.max_value = 100.0
	bar.value = 100.0
	bar.z_index = 20
	return bar


static func _circle_points(radius: float, segments: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		pts.append(Vector2(cos(a), sin(a)) * radius)
	return pts
