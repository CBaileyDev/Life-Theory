extends Node
## AudioManager
## Engine-native audio hooks. The prototype ships without copyrighted audio,
## so every cue is wired here and will play automatically the moment a matching
## file is dropped into res://audio/ (see audio/README.md). Missing files are a
## silent no-op, so the game runs fine with no audio installed.
##
## Naming convention: AudioManager.play("fragment_pickup") looks for
##   res://audio/sfx/fragment_pickup.ogg  (or .wav)
## Ambience uses a dedicated looping player via play_ambience("forest_day").

const SFX_DIRS := ["res://audio/sfx/", "res://audio/"]
const AMB_DIRS := ["res://audio/ambience/", "res://audio/"]
const EXTS := [".ogg", ".wav", ".mp3"]
const POOL_SIZE := 12

var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _ambience: AudioStreamPlayer
var _cache: Dictionary = {}

# Catalogue of every cue the game references. Keeps the design contract in one
# place and lets us warn (once) about cues with no asset yet.
const CUES := [
	"footstep", "mushroom_transform", "magic_hum", "guide_appear",
	"fragment_pickup", "wisp_alert", "wisp_damage", "wisp_death",
	"player_attack", "magic_cast", "upgrade_select", "ui_click",
	"player_hurt", "quest_update",
]

func _ready() -> void:
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_pool.append(p)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = "Master"
	_ambience.volume_db = -6.0
	add_child(_ambience)

func _find(dirs: Array, name: String) -> AudioStream:
	if _cache.has(name):
		return _cache[name]
	for d in dirs:
		for ext in EXTS:
			var path: String = d + name + ext
			if ResourceLoader.exists(path):
				var stream: AudioStream = load(path)
				_cache[name] = stream
				return stream
	_cache[name] = null
	return null

func play(cue: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream := _find(SFX_DIRS, cue)
	if stream == null:
		return  # No asset installed for this cue yet; silent.
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

func play_ambience(name: String) -> void:
	var stream := _find(AMB_DIRS, name)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_ambience.stream = stream
	_ambience.play()

func stop_ambience() -> void:
	_ambience.stop()
