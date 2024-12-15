extends Node

enum State {
	ENTERED,
	CONNECTED,
	INGAME,
	BROWSING_HISCORES,
}

var _states_scenes: Dictionary[State, String] = {
	State.ENTERED: "res://states/entered/entered.tscn",
	State.CONNECTED: "res://states/connected/connected.tscn",
	State.INGAME: "res://states/ingame/ingame.tscn",
	State.BROWSING_HISCORES: "res://states/browsing_hiscores/browsing_hiscores.tscn",
}

var client_id: int
var _current_scene_root: Node

func set_state(state: State) -> void:
	if _current_scene_root != null:
		_current_scene_root.queue_free()
	
	var scene: PackedScene = load(_states_scenes[state])
	_current_scene_root = scene.instantiate()
	add_child(_current_scene_root)
