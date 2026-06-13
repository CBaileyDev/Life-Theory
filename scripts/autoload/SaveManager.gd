extends Node
## SaveManager
## Simple cross-platform save system using a ConfigFile under user://.
## user:// resolves natively on both platforms:
##   macOS   -> ~/Library/Application Support/Godot/app_userdata/The First Layer/
##   Windows -> %APPDATA%\Godot\app_userdata\The First Layer\
## No hardcoded paths, fully portable.

const SAVE_PATH := "user://savegame.cfg"

signal saved
signal loaded

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var cfg := ConfigFile.new()
	var data := GameState.to_dict()
	for key in data:
		cfg.set_value("game", key, data[key])
	# Player transform, if the player is currently in the tree.
	var player = _find_player()   # untyped: get_yaw()/global_position via duck-typing
	if player:
		cfg.set_value("player", "position", player.global_position)
		cfg.set_value("player", "yaw", player.get_yaw())
	# Per-fragment collected state (so collected shards stay gone on load).
	var collected_indices: Array = []
	for f in get_tree().get_nodes_in_group("fragment"):
		if f.collected:
			collected_indices.append(f.index)
	cfg.set_value("world", "fragments_collected", collected_indices)
	cfg.save(SAVE_PATH)
	saved.emit()
	print("[SaveManager] Game saved.")

func load_game() -> Dictionary:
	## Returns the saved dictionary (or empty). The Forest scene reads this on
	## load to restore world/quest/player state.
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return {}
	var data := {}
	for key in cfg.get_section_keys("game"):
		data[key] = cfg.get_value("game", key)
	if cfg.has_section("player"):
		data["player_position"] = cfg.get_value("player", "position", Vector3.ZERO)
		data["player_yaw"] = cfg.get_value("player", "yaw", 0.0)
	data["fragments_collected"] = cfg.get_value("world", "fragments_collected", [])
	loaded.emit()
	return data

func _find_player() -> Node:
	var nodes := get_tree().get_nodes_in_group("player")
	return nodes[0] if nodes.size() > 0 else null
