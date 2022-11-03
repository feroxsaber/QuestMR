extends Spatial

var placing_marker = 0

func _process(_delta):
	# TODO: detect when user actually presses the button
	
	if placing_marker == 1:
		var marker
		for child in $RoomSetup.get_children():
			if "Marker" in child.name:
				marker = child
		
		if $FPController/RightHandController/RayCast.is_colliding():
			if not marker:
				marker = load("res://Marker.tscn").instance()
				$RoomSetup.add_child(marker)
			
			marker.global_translation = $FPController/RightHandController/RayCast.get_collision_point()
	elif placing_marker == 2:
		pass
