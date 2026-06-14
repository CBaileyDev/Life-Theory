class_name Dimmer
extends CorruptedWisp
## Dimmer — a second corrupted archetype.
## A cold violet-blue wisp that deals less raw damage than a Corrupted Wisp but,
## on a hit, CLOUDS your sight (the HUD darkens for a few seconds), making it the
## target you want to kill first. Reuses the whole CorruptedWisp state machine,
## telegraph, weak-seam and death — only the palette and the strike change.

func _ready() -> void:
	core_color = Color(0.34, 0.46, 1.0)
	shard_color = Color(0.28, 0.36, 0.85)
	light_col = Color(0.42, 0.56, 1.0)
	aura_color = Color(0.30, 0.40, 0.92)
	super._ready()

func _strike_effect() -> void:
	# Half the damage of a wisp, but it blinds — a priority threat.
	GameState.damage_player(ATTACK_DAMAGE * 0.5 * SettingsManager.enemy_damage_mult())
	GameState.dim_applied.emit(3.2)
