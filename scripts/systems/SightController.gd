extends Node
## SightController
## Drives "the Sight" — the fictional/mystical way to perceive the simulation.
## Toggle with Q/F; hold costs Lucidity and raises Desync. If Desync maxes the
## world "frays" and the Sight collapses (a soft cooldown). While active it:
##   - applies the sight.gdshader screen overlay (under the HUD), and
##   - reveals nodes in the "sight_only" group (hidden truth-glyphs).
## R consumes a Lucid Cap (mushroom reagent) to restore Lucidity.

const DRAIN := 12.0     # lucidity/sec while open
const DESYNC_RISE := 18.0
const LUCID_REGEN := 8.0
const DESYNC_DECAY := 14.0

var _mat: ShaderMaterial
var _rect: ColorRect
var _amount := 0.0
var _first_sight := false   # fire Auralis's first-Sight line once
var _warned_fray := false   # fire the Desync-fray warning once, then just toast

func _ready() -> void:
	_build_overlay()
	GameState.sight_toggled.connect(_on_toggled)

func _build_overlay() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0  # over the 3D world, under the HUD (layer 1)
	add_child(layer)
	_rect = ColorRect.new()
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Hidden until the Sight actually animates. The sight shader samples the
	# screen texture, which forces a full back-buffer copy + fullscreen pass every
	# frame it is visible — so keep it invisible (skipped entirely) while idle.
	_rect.visible = false
	var sh := load("res://shaders/sight.gdshader")
	if sh:
		_mat = ShaderMaterial.new()
		_mat.shader = sh
		_mat.set_shader_parameter("amount", 0.0)
		_rect.material = _mat
	layer.add_child(_rect)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("sight"):
		if not GameState.sight_active and not GameState.can_open_sight():
			GameState.toast.emit("Not enough Lucidity. Use a Lucid Cap  [R].")
		GameState.set_sight(not GameState.sight_active)
	elif event.is_action_pressed("use_reagent"):
		if not GameState.use_reagent():
			GameState.toast.emit("No Lucid Caps remain.")

func _on_toggled(active: bool) -> void:
	for n in get_tree().get_nodes_in_group("sight_only"):
		n.visible = active
	if active and not _first_sight:
		_first_sight = true
		GameState.request_dialogue("Auralis", Content.SIGHT_FIRST)

func _process(delta: float) -> void:
	if GameState.sight_active:
		GameState.add_lucidity(-DRAIN * delta)
		GameState.add_desync(DESYNC_RISE * delta)
		if GameState.lucidity <= 0.0 or GameState.desync >= GameState.MAX_DESYNC:
			GameState.add_desync(GameState.MAX_DESYNC)
			GameState.set_sight(false)
			if not _warned_fray:
				_warned_fray = true
				GameState.request_dialogue("Auralis", Content.DESYNC_WARNING)
			else:
				GameState.toast.emit("The world frays. The Sight collapses.")
	else:
		GameState.add_lucidity(LUCID_REGEN * delta)
		GameState.add_desync(-DESYNC_DECAY * delta)
	var target := 1.0 if GameState.sight_active else 0.0
	_amount = move_toward(_amount, target, delta * 4.0)
	# Only render (and pay the screen-copy cost) while the effect is on screen.
	if _rect:
		_rect.visible = _amount > 0.001
	if _mat and _amount > 0.001:
		_mat.set_shader_parameter("amount", _amount)
		_mat.set_shader_parameter("desync", GameState.desync / GameState.MAX_DESYNC)
