extends Node
## SettingsManager
## Central, cross-platform settings store. Persists to user:// via ConfigFile
## (resolves to the correct per-OS location on macOS and Windows). Emits
## signals so the active scene can react to graphics / camera changes live.

signal graphics_changed(quality: int)
signal camera_mode_changed(third_person: bool)
signal fov_changed(fov: float)

enum Quality { LOW, MEDIUM, HIGH }

const CONFIG_PATH := "user://settings.cfg"

# Common 16:9 resolutions offered in the settings menu.
const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

var graphics_quality: int = Quality.MEDIUM
var mouse_sensitivity: float = 0.30      # degrees-ish multiplier, see Player
var fullscreen: bool = false
var resolution_index: int = 0
var third_person: bool = false
var master_volume: float = 0.9
var fov: float = 75.0
var invert_y: bool = false
var render_scale: float = 1.0   # 3D resolution scale (perf lever for weak HW)

# Accessibility / gameplay
enum Difficulty { STORY, SEEKER, TRIAL }
var difficulty: int = Difficulty.SEEKER
var screen_shake: float = 1.0   # 0 disables camera shake
var reduce_motion: bool = false # disables view-bob + shake
var sprint_toggle: bool = false # toggle vs hold to sprint
var subtitles: bool = true

func enemy_damage_mult() -> float:
	match difficulty:
		Difficulty.STORY: return 0.6
		Difficulty.TRIAL: return 1.5
		_: return 1.0

func difficulty_name(i := -1) -> String:
	match (i if i >= 0 else difficulty):
		Difficulty.STORY: return "Story"
		Difficulty.TRIAL: return "Trial"
		_: return "Seeker"

func _ready() -> void:
	load_settings()
	apply_window_settings()
	get_viewport().scaling_3d_scale = render_scale
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))

# ---------------------------------------------------------------- persistence
func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		return
	graphics_quality = cfg.get_value("video", "quality", graphics_quality)
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	resolution_index = cfg.get_value("video", "resolution_index", resolution_index)
	render_scale = cfg.get_value("video", "render_scale", render_scale)
	mouse_sensitivity = cfg.get_value("input", "mouse_sensitivity", mouse_sensitivity)
	third_person = cfg.get_value("input", "third_person", third_person)
	invert_y = cfg.get_value("input", "invert_y", invert_y)
	sprint_toggle = cfg.get_value("input", "sprint_toggle", sprint_toggle)
	fov = cfg.get_value("video", "fov", fov)
	master_volume = cfg.get_value("audio", "master_volume", master_volume)
	difficulty = cfg.get_value("game", "difficulty", difficulty)
	screen_shake = cfg.get_value("access", "screen_shake", screen_shake)
	reduce_motion = cfg.get_value("access", "reduce_motion", reduce_motion)
	subtitles = cfg.get_value("access", "subtitles", subtitles)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "quality", graphics_quality)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "resolution_index", resolution_index)
	cfg.set_value("video", "render_scale", render_scale)
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("input", "third_person", third_person)
	cfg.set_value("input", "invert_y", invert_y)
	cfg.set_value("input", "sprint_toggle", sprint_toggle)
	cfg.set_value("video", "fov", fov)
	cfg.set_value("audio", "master_volume", master_volume)
	cfg.set_value("game", "difficulty", difficulty)
	cfg.set_value("access", "screen_shake", screen_shake)
	cfg.set_value("access", "reduce_motion", reduce_motion)
	cfg.set_value("access", "subtitles", subtitles)
	cfg.save(CONFIG_PATH)

# ------------------------------------------------------------------- setters
func set_quality(q: int) -> void:
	graphics_quality = clampi(q, Quality.LOW, Quality.HIGH)
	graphics_changed.emit(graphics_quality)
	save_settings()

func set_mouse_sensitivity(v: float) -> void:
	mouse_sensitivity = clampf(v, 0.02, 1.5)
	save_settings()

func set_fullscreen(on: bool) -> void:
	fullscreen = on
	apply_window_settings()
	save_settings()

func set_resolution_index(i: int) -> void:
	resolution_index = clampi(i, 0, RESOLUTIONS.size() - 1)
	apply_window_settings()
	save_settings()

func set_third_person(on: bool) -> void:
	third_person = on
	camera_mode_changed.emit(third_person)
	save_settings()

func set_fov(v: float) -> void:
	fov = clampf(v, 60.0, 110.0)
	fov_changed.emit(fov)
	save_settings()

func set_invert_y(on: bool) -> void:
	invert_y = on
	save_settings()

func set_render_scale(v: float) -> void:
	render_scale = clampf(v, 0.5, 1.0)
	get_viewport().scaling_3d_scale = render_scale
	save_settings()

func set_difficulty(i: int) -> void:
	difficulty = clampi(i, Difficulty.STORY, Difficulty.TRIAL)
	save_settings()

func set_screen_shake(v: float) -> void:
	screen_shake = clampf(v, 0.0, 1.0)
	save_settings()

func set_reduce_motion(on: bool) -> void:
	reduce_motion = on
	save_settings()

func set_sprint_toggle(on: bool) -> void:
	sprint_toggle = on
	save_settings()

func set_subtitles(on: bool) -> void:
	subtitles = on
	save_settings()

func set_master_volume(v: float) -> void:
	master_volume = clampf(v, 0.0, 1.0)
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(master_volume, 0.0001)))
	save_settings()

# --------------------------------------------------------------------- apply
func apply_window_settings() -> void:
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var res: Vector2i = RESOLUTIONS[clampi(resolution_index, 0, RESOLUTIONS.size() - 1)]
		DisplayServer.window_set_size(res)
		# Re-center on the current screen.
		var screen := DisplayServer.window_get_current_screen()
		var screen_rect := DisplayServer.screen_get_usable_rect(screen)
		DisplayServer.window_set_position(
			screen_rect.position + (screen_rect.size - res) / 2)

func quality_name(q: int = -1) -> String:
	var v := q if q >= 0 else graphics_quality
	match v:
		Quality.LOW: return "Low"
		Quality.HIGH: return "High"
		_: return "Medium"
