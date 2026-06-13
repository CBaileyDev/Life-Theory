extends Node
## SettingsManager
## Central, cross-platform settings store. Persists to user:// via ConfigFile
## (resolves to the correct per-OS location on macOS and Windows). Emits
## signals so the active scene can react to graphics / camera changes live.

signal graphics_changed(quality: int)
signal camera_mode_changed(third_person: bool)

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

func _ready() -> void:
	load_settings()
	apply_window_settings()
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
	mouse_sensitivity = cfg.get_value("input", "mouse_sensitivity", mouse_sensitivity)
	third_person = cfg.get_value("input", "third_person", third_person)
	master_volume = cfg.get_value("audio", "master_volume", master_volume)

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "quality", graphics_quality)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "resolution_index", resolution_index)
	cfg.set_value("input", "mouse_sensitivity", mouse_sensitivity)
	cfg.set_value("input", "third_person", third_person)
	cfg.set_value("audio", "master_volume", master_volume)
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
