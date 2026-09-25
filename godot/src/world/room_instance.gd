extends Node3D
## Attached to every generated room's root node by RoomGenerator.
## Provides runtime identity and exit-door routing for the room graph.

var room_id: String = ""


func get_room_id() -> String:
	return room_id
