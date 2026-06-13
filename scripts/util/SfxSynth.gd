class_name SfxSynth
extends RefCounted
## SfxSynth
## Generates all sound effects and ambience procedurally as 16-bit PCM
## (AudioStreamWAV) at runtime. This gives the prototype real, royalty-free
## audio feedback with zero shipped audio files and no third-party IP.
## AudioManager uses these as a fallback whenever a matching file in audio/
## is not present, so dropping in real assets transparently overrides them.

const RATE := 22050

# ----------------------------------------------------------------- encoding
static func _encode(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	return bytes

static func _wav(samples: PackedFloat32Array, loop := false) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = _encode(samples)
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = maxi(samples.size() - 1, 1)
	return w

# ------------------------------------------------------------- synthesis core
## A single voice: optional frequency glide, additive sine partials (or square),
## a noise component, and a linear attack/release envelope.
static func tone(dur: float, freq: float, freq_end := -1.0, partials := [1.0],
		square := false, noise := 0.0, attack := 0.01, release := 0.12,
		vol := 0.6) -> PackedFloat32Array:
	var n := maxi(int(dur * RATE), 1)
	var out := PackedFloat32Array()
	out.resize(n)
	var fend := freq_end if freq_end > 0.0 else freq
	var phase := 0.0
	var a := maxf(attack * RATE, 1.0)
	var r := maxf(release * RATE, 1.0)
	for i in n:
		var t := float(i) / n
		var f: float = lerpf(freq, fend, t)
		phase += TAU * f / RATE
		var s := 0.0
		if square:
			s = 1.0 if sin(phase) >= 0.0 else -1.0
		else:
			for h in partials.size():
				s += sin(phase * (h + 1)) * partials[h]
		if noise > 0.0:
			s += (randf() * 2.0 - 1.0) * noise
		# Envelope
		var env := 1.0
		if i < a:
			env = i / a
		elif i > n - r:
			env = (n - i) / r
		out[i] = s * env * vol
	return out

static func silence(dur: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(maxi(int(dur * RATE), 1))
	return out

static func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var n := maxi(a.size(), b.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var va := a[i] if i < a.size() else 0.0
		var vb := b[i] if i < b.size() else 0.0
		out[i] = va + vb
	return out

static func _seq(notes: Array, note_dur := 0.09, square := false, vol := 0.5) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for fr in notes:
		out.append_array(tone(note_dur, fr, -1.0, [1.0, 0.4], square, 0.0, 0.004, note_dur * 0.6, vol))
	return out

static func _chord(dur: float, freqs: Array, vol := 0.4) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for fr in freqs:
		out = _mix(out, tone(dur, fr, -1.0, [1.0, 0.3], false, 0.0, 0.02, dur * 0.5, vol))
	return out

# ------------------------------------------------------------------- cues
static func sfx(name: String) -> AudioStreamWAV:
	match name:
		"fragment_pickup":
			return _wav(_seq([784.0, 988.0, 1319.0], 0.08, false, 0.45))
		"ui_click":
			return _wav(tone(0.05, 660.0, -1.0, [1.0], true, 0.0, 0.002, 0.04, 0.3))
		"quest_update":
			return _wav(_seq([659.0, 880.0], 0.12, false, 0.4))
		"player_attack":
			return _wav(tone(0.18, 220.0, 90.0, [1.0, 0.5], false, 0.25, 0.005, 0.14, 0.5))
		"magic_cast":
			return _wav(tone(0.35, 330.0, 990.0, [1.0, 0.5, 0.25], false, 0.0, 0.01, 0.2, 0.45))
		"wisp_alert":
			return _wav(tone(0.4, 700.0, 300.0, [1.0, 0.6], false, 0.05, 0.01, 0.25, 0.4))
		"wisp_damage":
			return _wav(tone(0.1, 400.0, 260.0, [1.0], true, 0.15, 0.002, 0.08, 0.45))
		"wisp_death":
			return _wav(tone(0.5, 300.0, 60.0, [1.0, 0.5], false, 0.5, 0.005, 0.45, 0.5))
		"player_hurt":
			return _wav(tone(0.22, 160.0, 80.0, [1.0, 0.6], true, 0.3, 0.003, 0.18, 0.5))
		"upgrade_select":
			return _wav(_chord(0.7, [392.0, 494.0, 587.0, 784.0], 0.32))
		"guide_appear":
			return _wav(_chord(1.0, [523.0, 659.0, 784.0], 0.28))
		"magic_hum":
			return _wav(tone(0.9, 110.0, -1.0, [1.0, 0.4, 0.2], false, 0.02, 0.1, 0.5, 0.3))
		"mushroom_transform":
			var base := _chord(1.6, [196.0, 294.0, 392.0, 587.0], 0.3)
			var shimmer := tone(1.6, 880.0, 1760.0, [1.0, 0.5], false, 0.08, 0.2, 1.0, 0.18)
			return _wav(_mix(base, shimmer))
		"footstep":
			return _wav(tone(0.07, 120.0, 70.0, [1.0], false, 0.5, 0.002, 0.05, 0.28))
		"bird":
			# A short high warble.
			return _wav(_seq([2200.0, 2900.0, 2500.0, 3100.0], 0.05, false, 0.3))
		"wind":
			# A soft noise swell.
			return _wav(tone(1.2, 200.0, 140.0, [1.0], false, 0.6, 0.5, 0.6, 0.18))
		_:
			# Generic soft blip for any unlisted cue.
			return _wav(tone(0.08, 440.0, -1.0, [1.0], false, 0.0, 0.06, 0.3))

## An ~8s looping music theme: detuned drone pad + a slow sparse melody.
## "calm" (major-ish, the natural forest) vs "layer" (darker minor, the First
## Layer). Procedural — a placeholder score; drop real music in audio/ to override.
static func music(name: String) -> AudioStreamWAV:
	var dur := 8.0
	var minor := name == "layer"
	var root := 110.0 if minor else 130.81
	var pad := _mix(
		tone(dur, root, -1.0, [1.0, 0.3], false, 0.0, 1.4, 1.4, 0.13),
		tone(dur, root * 1.498, -1.0, [1.0, 0.25], false, 0.0, 1.4, 1.4, 0.09))
	var scale := [0, 3, 5, 7, 10, 12] if minor else [0, 2, 4, 7, 9, 12]
	var melroot := root * 2.0
	var mel := PackedFloat32Array()
	for i in 8:
		var semi: int = scale[(i * 2) % scale.size()]
		var f := melroot * pow(2.0, semi / 12.0)
		mel.append_array(tone(1.0, f, -1.0, [1.0, 0.5, 0.25], false, 0.0, 0.02, 0.85, 0.10))
	return _wav(_mix(pad, mel), true)

## A gentle ~4s looping forest pad: low detuned drones + a slow airy noise bed.
static func ambience() -> AudioStreamWAV:
	var dur := 4.0
	var pad := _mix(
		tone(dur, 98.0, -1.0, [1.0, 0.3], false, 0.0, 0.6, 0.6, 0.18),
		tone(dur, 99.6, -1.0, [1.0, 0.25], false, 0.0, 0.6, 0.6, 0.15))
	pad = _mix(pad, tone(dur, 147.0, -1.0, [1.0, 0.2], false, 0.0, 0.8, 0.8, 0.10))
	# Soft wind: low-level noise modulated by a slow sine.
	var n := pad.size()
	var wind := PackedFloat32Array()
	wind.resize(n)
	for i in n:
		var m := 0.5 + 0.5 * sin(TAU * 0.25 * float(i) / RATE)
		wind[i] = (randf() * 2.0 - 1.0) * 0.05 * m
	return _wav(_mix(pad, wind), true)
