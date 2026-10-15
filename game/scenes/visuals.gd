class_name Visuals
## Small helpers shared by the placeholder views.


static func material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	return mat


static func mesh(parent: Node3D, m: Mesh, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var inst := MeshInstance3D.new()
	inst.mesh = m
	inst.material_override = material(color)
	inst.position = pos
	parent.add_child(inst)
	return inst


static func box(parent: Node3D, size: Vector3, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return mesh(parent, b, color, pos)


static func sphere(parent: Node3D, radius: float, color: Color, pos := Vector3.ZERO) -> MeshInstance3D:
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	s.radial_segments = 12
	s.rings = 6
	return mesh(parent, s, color, pos)


static func multimesh(parent: Node3D, m: Mesh, color: Color, capacity: int) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = m
	mm.instance_count = capacity
	mm.visible_instance_count = 0
	var inst := MultiMeshInstance3D.new()
	inst.multimesh = mm
	inst.material_override = material(color)
	parent.add_child(inst)
	return inst


## Big billboarded number floating above a group.
static func count_label(parent: Node3D, height: float, font_size := 150) -> Label3D:
	var label := Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.font_size = font_size
	label.outline_size = 36
	label.pixel_size = 0.006
	label.outline_modulate = Color(0.1, 0.15, 0.1)
	label.position = Vector3(0, height, 0)
	parent.add_child(label)
	return label
