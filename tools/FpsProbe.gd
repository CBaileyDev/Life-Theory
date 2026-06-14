extends Node
## FpsProbe (dev tool — not shipped)
## Loads the Forest level on the real GPU, warms up past the world-build hitch
## and shader compile, then samples Engine.get_frames_per_second() and prints a
## single FPS_RESULT line before quitting. Drive the preset via env vars:
##   TOL_QUALITY = 0 (Low) | 1 (Medium) | 2 (High)
##   TOL_RS      = render scale 0.5..1.0 (optional)
## Used to validate the >=30fps target across presets, then removed.

var _t := 0.0
var _samples: Array[float] = []
var _gpu_ms: Array[float] = []
var _cpu_ms: Array[float] = []

func _ready() -> void:
	# Uncapped so we measure true GPU headroom, not the display's refresh cap.
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var q := SettingsManager.graphics_quality
	if OS.has_environment("TOL_QUALITY"):
		q = int(OS.get_environment("TOL_QUALITY"))
	SettingsManager.set_quality(q)
	if OS.has_environment("TOL_RS"):
		SettingsManager.set_render_scale(float(OS.get_environment("TOL_RS")))
	GameState.reset_run()
	var forest: Node = load("res://scenes/Forest.tscn").instantiate()
	get_tree().root.add_child.call_deferred(forest)
	# Measure true GPU/CPU frame time (independent of the display vsync cap).
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)

func _process(delta: float) -> void:
	_t += delta
	if _t < 2.5:
		return  # warmup: world build + shader compilation + render-scale settle
	var vp := get_viewport().get_viewport_rid()
	_samples.append(Engine.get_frames_per_second())
	_gpu_ms.append(RenderingServer.viewport_get_measured_render_time_gpu(vp))
	_cpu_ms.append(RenderingServer.viewport_get_measured_render_time_cpu(vp))
	if _t > 7.0:
		var gpu := _avg(_gpu_ms)
		var cpu := _avg(_cpu_ms)
		var implied := (1000.0 / gpu) if gpu > 0.01 else 0.0
		print("FPS_RESULT quality=%d render_scale=%.2f present_fps=%.0f gpu_ms=%.2f cpu_ms=%.2f implied_fps=%.0f window=%s gpu=%s"
			% [SettingsManager.graphics_quality, SettingsManager.render_scale, _avg(_samples),
				gpu, cpu, implied, str(DisplayServer.window_get_size()), RenderingServer.get_video_adapter_name()])
		var img := get_viewport().get_texture().get_image()
		var shot := "/tmp/tol_shot_q%d.png" % SettingsManager.graphics_quality
		img.save_png(shot)
		print("SHOT %s" % shot)
		get_tree().quit()

func _avg(a: Array[float]) -> float:
	var sum := 0.0
	for v in a:
		sum += v
	return sum / maxf(a.size(), 1)
