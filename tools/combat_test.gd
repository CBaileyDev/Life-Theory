extends Node
## Headless combat smoke test. Boots the Forest, enters the First Layer (so
## wisps activate), stages a wisp in front of the player, fires a melee swing
## (exercises spark + hit-stop), casts a pulse, and kills a wisp (death pop).
## Prints COMBAT_TEST PASS/FAIL. Run:
##   godot --headless --quit-after 600 res://tools/combat_test.tscn

var _step := 0
var _t := 0.0
var _forest: Node
var _ok := true
var _target = null
var _hp0 := 0.0

func _ready() -> void:
	GameState.reset_run()
	_forest = load("res://scenes/Forest.tscn").instantiate()
	get_tree().root.add_child.call_deferred(_forest)

func _process(delta: float) -> void:
	_t += delta
	if _t < 1.0:
		return
	match _step:
		0:
			GameState.activate_mushroom()   # -> FIRST_LAYER, wisps activate
			GameState.magic_unlocked = true
			GameState.set_sight(true)       # exercise the Sight weak-seam combat path
			_step = 1
			_t = 0.0
		1:
			if _t < 0.6:
				return
			var player = _first("player")
			var wisp = _first_wisp()
			if not player or not wisp:
				_fail("missing player(%s) or wisp(%s)" % [player != null, wisp != null])
				_finish()
				return
			# Stage the wisp directly in front of the camera, in range.
			var cam = player.fp_camera
			var fwd = -cam.global_transform.basis.z
			wisp.global_position = cam.global_position + fwd * 1.8
			_target = wisp
			_step = 2
			_t = 0.0
		2:
			if _t < 0.2:
				return
			var player = _first("player")
			if not is_instance_valid(_target):
				_target = _first_wisp()
			var before_count = get_tree().get_nodes_in_group("enemy").size()
			# Re-stage in front THIS frame (the wisp drifts via its own physics).
			var cam = player.fp_camera
			var fwd = -cam.global_transform.basis.z
			_target.global_position = cam.global_position + fwd * 1.8
			_target.velocity = Vector3.ZERO
			_hp0 = _target.health
			player._attack()        # Sight is open -> weak-seam hit (1.8x)
			var dealt = _hp0 - (_target.health if is_instance_valid(_target) else _hp0)
			print("COMBAT_TEST weakpoint dealt=%.1f (base melee=%.1f) sight=%s" % [dealt, GameState.melee_damage, GameState.sight_active])
			if dealt < GameState.melee_damage + 1.0:
				_fail("Sight weak-seam multiplier did not apply (dealt %.1f)" % dealt)
			player._cast()          # projectile + muzzle spark + kick
			print("COMBAT_TEST melee+cast fired; enemies=", before_count)
			_step = 3
			_t = 0.0
		3:
			if _t < 0.3:
				return
			if not is_equal_approx(Engine.time_scale, 1.0):
				_fail("time_scale not restored after hitstop: %f" % Engine.time_scale)
			# Verify the Dimmer archetype exists and its strike emits the blind.
			var dimmer = null
			for e in get_tree().get_nodes_in_group("enemy"):
				if e is Dimmer:
					dimmer = e
					break
			if dimmer:
				var dimmed := [false]
				GameState.dim_applied.connect(func(_d): dimmed[0] = true, CONNECT_ONE_SHOT)
				dimmer._strike_effect()
				print("COMBAT_TEST dimmer blinds=", dimmed[0])
				if not dimmed[0]:
					_fail("Dimmer did not emit dim_applied")
			else:
				_fail("no Dimmer spawned in the pack")
			# Verify dodge i-frames block incoming damage.
			var pl3 = _first("player")
			if pl3:
				pl3._dodge()
				var hp_b = GameState.health
				GameState.damage_player(20.0)
				var blocked = is_equal_approx(GameState.health, hp_b)
				print("COMBAT_TEST dodge invuln=", GameState.player_invuln, " blocked=", blocked)
				if not GameState.player_invuln or not blocked:
					_fail("dodge i-frames did not block damage")
			# Verify the wrong-tree secret dissolves into Essence.
			var wt = null
			for e in get_tree().get_nodes_in_group("enemy"):
				if e is WrongTree:
					wt = e
					break
			if wt:
				var ess0 = GameState.forest_essence
				wt.take_damage(999.0, _first("player"))
				print("COMBAT_TEST wrongtree essence +", GameState.forest_essence - ess0)
				if GameState.forest_essence <= ess0:
					_fail("wrong-tree gave no essence")
			else:
				_fail("no WrongTree in the world")
			# Kill a wisp outright to exercise the death pop + spark + essence.
			var wisp = _first_wisp()
			if wisp:
				var ess = GameState.forest_essence
				wisp.take_damage(999.0, _first("player"))
				if GameState.forest_essence <= ess:
					_fail("essence did not increase on kill")
			_step = 4
			_t = 0.0
		4:
			if _t < 0.8:
				return
			print("COMBAT_TEST ", "PASS" if _ok else "FAIL")
			_finish()

func _fail(msg: String) -> void:
	_ok = false
	push_error("COMBAT_TEST fail: " + msg)
	print("COMBAT_TEST fail: ", msg)

func _finish() -> void:
	get_tree().quit()

func _first(g: String) -> Node:
	var n := get_tree().get_nodes_in_group(g)
	return n[0] if n.size() > 0 else null

func _first_wisp() -> Node:
	for e in get_tree().get_nodes_in_group("enemy"):
		if e is CorruptedWisp:   # excludes the StaticBody WrongTree
			return e
	return null
