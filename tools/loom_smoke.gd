extends Node
var _t := 0.0
func _ready() -> void:
	GameState.reset_run()
	GameState.current_biome = GameState.Biome.LOOMSTRATA
	var f = load("res://scenes/Forest.tscn").instantiate()
	get_tree().root.add_child.call_deferred(f)
func _process(delta: float) -> void:
	_t += delta
	if _t > 2.5:
		print("LOOM_SMOKE OK")
		get_tree().quit()
