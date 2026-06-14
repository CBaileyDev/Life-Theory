extends Node3D
func _ready() -> void:
	var w = WorldBuilder.new(1.0, 0, 1.0)
	w.build(self)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var rocks: Array = []
	_find(self, rocks)
	print("ROCK_TEST bodies=", rocks.size())
	var ok := false
	if rocks.size() > 0:
		var body = rocks[0]
		var cs = body.get_child(0) as CollisionShape3D
		print("ROCK_TEST shape=", cs.shape.get_class(), " pts=", (cs.shape.points.size() if cs.shape is ConvexPolygonShape3D else -1))
		var pos = cs.global_position
		var sp := PhysicsShapeQueryParameters3D.new()
		var sphere := SphereShape3D.new(); sphere.radius = 0.25
		sp.shape = sphere
		sp.transform = Transform3D(Basis(), pos)
		var hits = get_world_3d().direct_space_state.intersect_shape(sp, 16)
		print("ROCK_TEST intersect_at_center hits=", hits.size())
		ok = hits.size() > 0
	print("ROCK_TEST ", "PASS" if ok else "FAIL")
	get_tree().quit()
func _find(n: Node, out: Array) -> void:
	if n is StaticBody3D and n.name == "RockCollision":
		out.append(n)
	for c in n.get_children():
		_find(c, out)
