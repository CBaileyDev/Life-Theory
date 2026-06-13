extends Node
## GameState
## The single source of truth for the run: world state, quest progress,
## inventory/flags, player health, and chosen upgrade. UI and gameplay systems
## observe it through signals. Persisted via SaveManager.

# ---------------------------------------------------------------- enumerations
enum World { NATURAL, FIRST_LAYER }
enum Biome { QUIETWOOD, LOOMSTRATA }   # the forest, and the layer beneath it

enum Step {
	FIND_MUSHROOM,     # 0 - locate & interact with the glowing mushroom
	FOLLOW_TRAIL,      # 1 - follow the luminous trail
	MEET_GUIDE,        # 2 - speak with Auralis
	COLLECT_FRAGMENTS, # 3 - gather 3 Fragments of Truth
	RETURN_SHRINE,     # 4 - return to the shrine
	CHOOSE_UPGRADE,    # 5 - pick a first upgrade
	COMPLETE,          # 6 - quest done
}

const STEP_TEXT := {
	Step.FIND_MUSHROOM: "Find the glowing mushroom near the ancient shrine.",
	Step.FOLLOW_TRAIL: "Follow the luminous trail deeper into the clearing.",
	Step.MEET_GUIDE: "Approach the forest guide, Auralis.",
	Step.COLLECT_FRAGMENTS: "Collect 3 Fragments of Truth from the clearing.",
	Step.RETURN_SHRINE: "Return to the mushroom shrine.",
	Step.CHOOSE_UPGRADE: "Choose what kind of seeker you will become.",
	Step.COMPLETE: "The first layer is revealed. (Prototype complete.)",
}

# --------------------------------------------------------------------- signals
signal world_state_changed(state: int)
signal quest_step_changed(step: int, text: String)
signal fragments_changed(collected: int, total: int)
signal health_changed(health: float, max_health: float)
signal player_damaged(amount: float)
signal player_died
# The Sight (perceive the simulation). Fictional/mystical mechanic.
signal sight_toggled(active: bool)
signal lucidity_changed(lucidity: float, maxv: float)
signal desync_changed(desync: float, maxv: float)
signal reagents_changed(count: int)
signal dialogue_requested(speaker: String, lines: Array)
signal upgrade_menu_requested
signal shop_requested
signal toast(text: String)

# ----------------------------------------------------------------------- state
const FRAGMENT_TOTAL := 3

var world: int = World.NATURAL
var current_biome: int = Biome.QUIETWOOD
var quest_step: int = Step.FIND_MUSHROOM
var fragments: int = 0
var mushroom_activated: bool = false
var guide_met: bool = false
var quest_complete: bool = false
var selected_upgrade: String = ""
var acquired_upgrades: Array = []
const UPGRADE_COST := 60

# Player stats (live here so they survive scene transitions / saves).
var max_health: float = 100.0
var health: float = 100.0
var sprint_multiplier: float = 1.0
var melee_damage: float = 34.0          # 3 hits to kill a 100hp wisp
var magic_unlocked: bool = false
var magic_damage_mult: float = 1.0
var damage_reduction: float = 0.0
var forest_essence: int = 0             # optional resource
var collected_ids: Array = []           # which fragment indices recovered

# Set by the main menu: tells the Forest scene whether to load a save on start.
var pending_load: bool = false

# ---- The Sight: a fictional, mystical way to perceive the simulation. ----
# Lucidity is spent to hold the Sight; Desync rises while it is open and the
# world "frays" if it maxes out. Lucid Caps (mushroom reagents) restore Lucidity.
const MAX_LUCIDITY := 100.0
const MAX_DESYNC := 100.0
var sight_unlocked: bool = false
var sight_active: bool = false
var lucidity: float = 45.0
var desync: float = 0.0
var sight_reagents: int = 1

func reset_run() -> void:
	world = World.NATURAL
	current_biome = Biome.QUIETWOOD
	quest_step = Step.FIND_MUSHROOM
	fragments = 0
	mushroom_activated = false
	guide_met = false
	quest_complete = false
	selected_upgrade = ""
	acquired_upgrades = []
	max_health = 100.0
	health = 100.0
	sprint_multiplier = 1.0
	melee_damage = 34.0
	magic_unlocked = false
	magic_damage_mult = 1.0
	damage_reduction = 0.0
	forest_essence = 0
	collected_ids = []
	sight_unlocked = false
	sight_active = false
	lucidity = 45.0
	desync = 0.0
	sight_reagents = 1

func record_fragment(id: int) -> void:
	if not collected_ids.has(id):
		collected_ids.append(id)

# Emit current state so freshly-spawned UI shows the right thing.
func broadcast() -> void:
	world_state_changed.emit(world)
	quest_step_changed.emit(quest_step, STEP_TEXT[quest_step])
	fragments_changed.emit(fragments, FRAGMENT_TOTAL)
	health_changed.emit(health, max_health)
	lucidity_changed.emit(lucidity, MAX_LUCIDITY)
	desync_changed.emit(desync, MAX_DESYNC)
	reagents_changed.emit(sight_reagents)

# -------------------------------------------------------------- quest control
func set_step(step: int) -> void:
	if step == quest_step:
		return
	quest_step = step
	quest_step_changed.emit(quest_step, STEP_TEXT[quest_step])
	AudioManager.play("quest_update")

func activate_mushroom() -> void:
	if mushroom_activated:
		return
	mushroom_activated = true
	set_world(World.FIRST_LAYER)
	set_step(Step.FOLLOW_TRAIL)
	unlock_sight()
	grant_reagents(2)

func set_world(state: int) -> void:
	world = state
	world_state_changed.emit(world)

func meet_guide() -> void:
	if not guide_met:
		guide_met = true
	if quest_step == Step.FOLLOW_TRAIL or quest_step == Step.MEET_GUIDE:
		set_step(Step.COLLECT_FRAGMENTS)

func collect_fragment() -> void:
	fragments = mini(fragments + 1, FRAGMENT_TOTAL)
	fragments_changed.emit(fragments, FRAGMENT_TOTAL)
	AudioManager.play("fragment_pickup")
	forest_essence += 10
	grant_reagents(1)
	add_lucidity(20.0)
	if fragments >= FRAGMENT_TOTAL and quest_step == Step.COLLECT_FRAGMENTS:
		set_step(Step.RETURN_SHRINE)
		toast.emit("All fragments gathered. Return to the shrine.")

func reach_shrine() -> bool:
	## Called when the player interacts with the shrine. Returns true if this
	## opens the upgrade choice.
	if quest_step == Step.RETURN_SHRINE:
		set_step(Step.CHOOSE_UPGRADE)
		upgrade_menu_requested.emit()
		return true
	return false

func _apply_upgrade(id: String) -> void:
	match id:
		"heart_of_bark":
			max_health += 60.0
			health = max_health
		"fleet_hidden_path":
			sprint_multiplier = 1.6
		"rootblade_strength":
			melee_damage += 40.0
		"simulation_pulse":
			magic_unlocked = true
		"bark_skin":
			max_health += 40.0
			health = max_health
		"ironwood":
			max_health += 40.0
			health = max_health
			damage_reduction = clampf(damage_reduction + 0.15, 0.0, 0.8)
		"fleetfoot":
			sprint_multiplier = 1.9
		"windstep":
			sprint_multiplier = 2.2
		"keen_edge":
			melee_damage += 40.0
		"grovecleaver":
			melee_damage += 80.0
		"pulse_power":
			magic_damage_mult = 1.6
		"pulse_storm":
			magic_damage_mult = 2.2
	health_changed.emit(health, max_health)

func _grant_upgrade(id: String) -> void:
	if acquired_upgrades.has(id):
		return
	acquired_upgrades.append(id)
	_apply_upgrade(id)

func has_upgrade(id: String) -> bool:
	return acquired_upgrades.has(id)

func choose_upgrade(id: String) -> void:
	selected_upgrade = id
	_grant_upgrade(id)
	quest_complete = true
	set_step(Step.COMPLETE)
	AudioManager.play("upgrade_select")

## Spend Forest Essence to acquire another upgrade. Returns true on success.
func buy_upgrade(id: String) -> bool:
	if has_upgrade(id) or forest_essence < UPGRADE_COST:
		return false
	forest_essence -= UPGRADE_COST
	_grant_upgrade(id)
	AudioManager.play("upgrade_select")
	return true

## Buy a Seeker-Path node (honours prerequisite + cost). Returns true on success.
func buy_node(id: String, cost: int, req: String) -> bool:
	if has_upgrade(id):
		return false
	if req != "" and not has_upgrade(req):
		return false
	if forest_essence < cost:
		return false
	forest_essence -= cost
	_grant_upgrade(id)
	AudioManager.play("upgrade_select")
	return true

# ------------------------------------------------------------------- health
func damage_player(amount: float) -> void:
	if health <= 0.0:
		return
	amount *= (1.0 - damage_reduction)
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	player_damaged.emit(amount)
	AudioManager.play("player_hurt")
	if health <= 0.0:
		player_died.emit()

func heal_player(amount: float) -> void:
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)

func revive_full() -> void:
	health = max_health
	health_changed.emit(health, max_health)

# --------------------------------------------------------------------- sight
func unlock_sight() -> void:
	if sight_unlocked:
		return
	sight_unlocked = true
	toast.emit("The Sight stirs.  [Q] to perceive the layer  ·  [R] Lucid Cap")

func can_open_sight() -> bool:
	return sight_unlocked and lucidity > 5.0 and desync < MAX_DESYNC

func set_sight(active: bool) -> void:
	if active and not can_open_sight():
		return
	if active == sight_active:
		return
	sight_active = active
	sight_toggled.emit(sight_active)
	AudioManager.play("magic_hum" if active else "ui_click", -8.0)

func add_lucidity(amount: float) -> void:
	lucidity = clampf(lucidity + amount, 0.0, MAX_LUCIDITY)
	lucidity_changed.emit(lucidity, MAX_LUCIDITY)

func add_desync(amount: float) -> void:
	desync = clampf(desync + amount, 0.0, MAX_DESYNC)
	desync_changed.emit(desync, MAX_DESYNC)

func use_reagent() -> bool:
	if sight_reagents <= 0:
		return false
	sight_reagents -= 1
	reagents_changed.emit(sight_reagents)
	add_lucidity(45.0)
	add_desync(-20.0)
	AudioManager.play("fragment_pickup", -4.0)
	toast.emit("A Lucid Cap dissolves. Clarity returns.")
	return true

func grant_reagents(n: int) -> void:
	sight_reagents += n
	reagents_changed.emit(sight_reagents)

# ------------------------------------------------------------------ dialogue
func request_dialogue(speaker: String, lines: Array) -> void:
	dialogue_requested.emit(speaker, lines)

# ----------------------------------------------------------- save/load bridge
func to_dict() -> Dictionary:
	return {
		"world": world,
		"current_biome": current_biome,
		"quest_step": quest_step,
		"fragments": fragments,
		"mushroom_activated": mushroom_activated,
		"guide_met": guide_met,
		"quest_complete": quest_complete,
		"selected_upgrade": selected_upgrade,
		"acquired_upgrades": acquired_upgrades,
		"max_health": max_health,
		"health": health,
		"sprint_multiplier": sprint_multiplier,
		"melee_damage": melee_damage,
		"magic_unlocked": magic_unlocked,
		"magic_damage_mult": magic_damage_mult,
		"damage_reduction": damage_reduction,
		"forest_essence": forest_essence,
		"collected_ids": collected_ids,
		"sight_unlocked": sight_unlocked,
		"lucidity": lucidity,
		"desync": desync,
		"sight_reagents": sight_reagents,
	}

func from_dict(d: Dictionary) -> void:
	if d.is_empty():
		return
	world = d.get("world", world)
	current_biome = d.get("current_biome", current_biome)
	quest_step = d.get("quest_step", quest_step)
	fragments = d.get("fragments", fragments)
	mushroom_activated = d.get("mushroom_activated", mushroom_activated)
	guide_met = d.get("guide_met", guide_met)
	quest_complete = d.get("quest_complete", quest_complete)
	selected_upgrade = d.get("selected_upgrade", selected_upgrade)
	acquired_upgrades = d.get("acquired_upgrades", acquired_upgrades)
	max_health = d.get("max_health", max_health)
	health = d.get("health", health)
	sprint_multiplier = d.get("sprint_multiplier", sprint_multiplier)
	melee_damage = d.get("melee_damage", melee_damage)
	magic_unlocked = d.get("magic_unlocked", magic_unlocked)
	magic_damage_mult = d.get("magic_damage_mult", magic_damage_mult)
	damage_reduction = d.get("damage_reduction", damage_reduction)
	forest_essence = d.get("forest_essence", forest_essence)
	collected_ids = d.get("collected_ids", collected_ids)
	sight_unlocked = d.get("sight_unlocked", sight_unlocked)
	lucidity = d.get("lucidity", lucidity)
	desync = d.get("desync", desync)
	sight_reagents = d.get("sight_reagents", sight_reagents)
