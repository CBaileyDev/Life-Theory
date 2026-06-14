extends Node
## Headless verification that the data-driven upgrade effects (SkillTree.PATHS +
## GameState._apply_effect) produce the exact same stats as the old hardcoded
## match. Run: godot --headless res://tools/UpgradeTest.tscn

func _ready() -> void:
	var ok := true
	var cases := [
		[["heart_of_bark"], "max_health", 160.0],
		[["heart_of_bark", "bark_skin"], "max_health", 200.0],
		[["heart_of_bark", "bark_skin", "ironwood"], "max_health", 240.0],
		[["heart_of_bark", "bark_skin", "ironwood"], "damage_reduction", 0.15],
		[["fleet_hidden_path"], "sprint_multiplier", 1.6],
		[["fleet_hidden_path", "fleetfoot"], "sprint_multiplier", 1.9],
		[["fleet_hidden_path", "fleetfoot", "windstep"], "sprint_multiplier", 2.2],
		[["rootblade_strength"], "melee_damage", 74.0],
		[["rootblade_strength", "keen_edge"], "melee_damage", 114.0],
		[["rootblade_strength", "keen_edge", "grovecleaver"], "melee_damage", 194.0],
		[["simulation_pulse"], "magic_unlocked", true],
		[["simulation_pulse", "pulse_power"], "magic_damage_mult", 1.6],
		[["simulation_pulse", "pulse_power", "pulse_storm"], "magic_damage_mult", 2.2],
	]
	for row in cases:
		GameState.reset_run()
		for id in row[0]:
			GameState._grant_upgrade(id)
		var got = GameState.get(row[1])
		var want = row[2]
		var passed: bool = (got == want) if (want is bool) else is_equal_approx(float(got), float(want))
		if not passed:
			ok = false
		print("%s  %-16s after %s = %s (want %s)"
			% ["OK  " if passed else "FAIL", row[1], str(row[0]), str(got), str(want)])
	# Unknown id must NOT charge or crash — push_error + no-op (expect one error line).
	GameState.reset_run()
	GameState.forest_essence = 1000
	var before := GameState.forest_essence
	var bought := GameState.buy_upgrade("does_not_exist")
	var guarded := (not bought) and GameState.forest_essence == before
	if not guarded:
		ok = false
	print("%s  unknown-id guard: bought=%s essence=%d (want false / %d)"
		% ["OK  " if guarded else "FAIL", str(bought), GameState.forest_essence, before])
	print("UPGRADE_TEST %s" % ("PASS" if ok else "FAIL"))
	get_tree().quit()
