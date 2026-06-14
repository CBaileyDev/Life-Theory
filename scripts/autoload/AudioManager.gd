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
var _music: AudioStreamPlayer
var _music_name := ""
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
	_ensure_buses()
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = "Ambience"
	_ambience.volume_db = -6.0
	add_child(_ambience)
	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	_music.volume_db = -40.0
	add_child(_music)

## Build a Master -> {Music, Ambience, SFX, UI} mix hierarchy at runtime (the
## project ships only the default Master bus). Sub-buses send to Master, so the
## existing master-volume setting still governs everything, and we can now duck
## individual layers (e.g. music under dialogue) without touching player volumes.
func _ensure_buses() -> void:
	for bus_name in ["Music", "Ambience", "SFX", "UI"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			var idx := AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, bus_name)
			AudioServer.set_bus_send(idx, "Master")

## Smoothly fade a bus toward target_db (negative = quieter). Used for ducking.
func duck(bus_name: String, target_db: float, time := 0.3) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	var from := AudioServer.get_bus_volume_db(idx)
	var t := create_tween()
	t.tween_method(func(v: float): AudioServer.set_bus_volume_db(idx, v), from, target_db, time)

## Duck the music + ambience under dialogue/important readouts, then restore.
func dialogue_duck(active: bool) -> void:
	duck("Music", -14.0 if active else 0.0, 0.35)
	duck("Ambience", -8.0 if active else 0.0, 0.35)

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

const UI_CUES := ["ui_click", "upgrade_select", "quest_update"]

func play(cue: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	var stream := _find(SFX_DIRS, cue)
	if stream == null:
		stream = _synth_cue(cue)  # Procedural fallback (royalty-free).
	if stream == null:
		return
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = stream
	p.bus = "UI" if cue in UI_CUES else "SFX"
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()

func play_ambience(name: String) -> void:
	var stream := _find(AMB_DIRS, name)
	if stream == null:
		stream = _synth_ambience(name)  # Procedural fallback (per biome).
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_ambience.stream = stream
	_ambience.play()

# ------------------------------------------------------- procedural fallback
var _synth_cache: Dictionary = {}

func _synth_cue(cue: String) -> AudioStream:
	if not _synth_cache.has(cue):
		_synth_cache[cue] = SfxSynth.sfx(cue)
	return _synth_cache[cue]

func _synth_ambience(name := "forest_day") -> AudioStream:
	var key := "__amb_" + name
	if not _synth_cache.has(key):
		_synth_cache[key] = SfxSynth.ambience(name)
	return _synth_cache[key]

func stop_ambience() -> void:
	_ambience.stop()

# ------------------------------------------------------------- adaptive music
## Crossfade to a procedural (or installed) music theme by name ("calm"/"layer").
func play_music(name: String) -> void:
	if name == _music_name:
		return
	_music_name = name
	var stream := _find(AMB_DIRS, "music_" + name)
	if stream == null and not _synth_cache.has("mus_" + name):
		_synth_cache["mus_" + name] = SfxSynth.music(name)
	if stream == null:
		stream = _synth_cache["mus_" + name]
	var swap := func():
		_music.stream = stream
		_music.play()
	var t := create_tween()
	if _music.playing:
		t.tween_property(_music, "volume_db", -40.0, 1.0)
		t.tween_callback(swap)
		t.tween_property(_music, "volume_db", -13.0, 1.6)
	else:
		swap.call()
		_music.volume_db = -40.0
		t.tween_property(_music, "volume_db", -13.0, 1.6)
