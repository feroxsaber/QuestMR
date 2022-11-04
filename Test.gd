extends Spatial

var placing_marker = 1
var last_marker_position
var edit_mode = true

func _process(delta):
	if Input.is_action_pressed("rotate"):
		$FPController.global_rotation.y += 5 * delta
	
	# Move the floor mesh down if needed (shouldn't be - guardian does this automatically)
	var lowest_controller_y = $FPController/RightHandController.global_translation.y
	if $FPController/LeftHandController.global_translation.y < lowest_controller_y:
		lowest_controller_y = $FPController/LeftHandController.global_translation.y
	if $RoomGeometry/FloorMesh.global_translation.y > lowest_controller_y:
		$RoomGeometry/FloorMesh.global_translation.y = lowest_controller_y
	
	if edit_mode:
		# TODO: set last_marker_position to marker position when user places wall marker
		
		var marker
		var wall_mesh
		
		# Check to see if we already have a marker spawned
		for child in $RoomGeometry.get_children():
			if "Marker" in child.name:
				marker = child
				
		# Check to see if we already have a wall spawned
		for child in $RoomGeometry.get_children():
			if "SetupWall" in child.name:
				wall_mesh = child
		
		# placing_marker has 3 values:
		# 0 - not placing a marker (resolves to false)
		# 1 - placing an initial marker (resolves to true)
		# 2 - placing another marker (resolves to true, both here and in the if below)
		var place_button_pressed = Input.is_action_just_released("ok")
		var end_button_pressed = Input.is_action_just_released("cancel")
		if place_button_pressed:
			if placing_marker and marker:
				if placing_marker == 2 and wall_mesh:
					# Finish placing the wall
					wall_mesh.name = wall_mesh.name.replace("SetupWall", "Wall")
					last_marker_position = wall_mesh.global_translation + wall_mesh.get_node("MeshInstance").mesh.size
					last_marker_position.y = $RoomGeometry/FloorMesh.global_translation.y
					wall_mesh = null
				else:
					# Finish placing the marker
					placing_marker = 2
					last_marker_position = marker.global_translation
		
		if end_button_pressed:
			placing_marker = 0
			if marker:
				marker.queue_free()
			if wall_mesh:
				wall_mesh.queue_free()
		
		# we're placing a marker
		if placing_marker:
			# Check to see if we *should* have a marker spawned
			if $FPController/RightHandController/RayCast.is_colliding():
				# Spawn one if not
				if not marker:
					marker = load("res://Marker.tscn").instance()
					$RoomGeometry.add_child(marker)
				
				# Set the marker's position to where the controller is pointing
				marker.global_translation = $FPController/RightHandController/RayCast.get_collision_point()
			# Delete the current marker if we shouldn't
			elif marker:
				marker.queue_free()
		
		# we're placing a second marker
		if placing_marker == 2 and marker:
			# If not, spawn one
			if not wall_mesh:
				wall_mesh = load("res://Wall.tscn").instance()
				wall_mesh.global_translation = last_marker_position
				$RoomGeometry.add_child(wall_mesh)
			
			# Get the position difference between this marker and the last
			var delta_x = marker.global_translation.x - last_marker_position.x 
			var delta_z = marker.global_translation.z - last_marker_position.z
			var wall_size = Vector3(0.01, 10, 0.01)
			
			# Snap to either the X or Z axis
			# TODO: angled walls?
			if(abs(delta_x) > abs(delta_z)):
				wall_size.x = delta_x
				wall_size.z = 0.01
			else:
				wall_size.x = 0.01
				wall_size.z = delta_z
			
			# Create a new mesh for the wall and add it
			# TODO: custom material
			var mesh = CubeMesh.new()
			mesh.material = load("res://WallMaterial.tres")
			mesh.size = wall_size
			wall_mesh.get_node("MeshInstance").mesh = mesh
			wall_mesh.get_node("MeshInstance").translation.x = wall_size.x / 2
			wall_mesh.get_node("MeshInstance").translation.z = wall_size.z / 2
			
