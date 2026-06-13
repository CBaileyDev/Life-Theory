extends Node
## GameState
## The single source of truth for the run: world state, quest progress,
## inventory/flags, player health, and chosen upgrade. UI and gameplay systems
## observe it through signals. Persisted via SaveManager.

# ---------------------------------------------------------------- enumerations
enum World { NATURAL, FIRST_LAYER }

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
signal player_died
signal dialogue_requested(speaker: String, lines: Array)
signal upgrade_menu_requested
signal toast(text: String)

# ----------------------------------------------------------------------- state
const FRAGMENT_TOTAL := 3

var world: int = World.NATURAL
var quest_step: int = Step.FIND_MUSHROOM
var fragments: int = 0
var mushroom_activated: bool = false
var guide_met: bool = false
var quest_complete: bool = false
var selected_upgrade: String = ""

# Player stats (live here so they survive scene transitions / saves).
var max_health: float = 100.0
var health: float = 100.0
var sprint_multiplier: float = 1.0
var melee_damage: float = 34.0          # 3 hits to kill a 100hp wisp
var magic_unlocked: bool = false
var forest_essence: int = 0             # optional resource

# Set by the main menu: tells the Forest scene whether to load a save on start.
var pending_load: bool = false

func reset_run() -> void:
	world = World.NATURAL
	quest_step = Step.FIND_MUSHROOM
	fragments = 0
	mushroom_activated = false
	guide_met = false
	quest_complete = false
	selected_upgrade = ""
	max_health = 100.0
	health = 100.0
	sprint_multiplier = 1.0
	melee_damage = 34.0
	magic_unlocked = false
	forest_essence = 0

# Emit current state so freshly-spawned UI shows the right thing.
func broadcast() -> void:
	world_state_changed.emit(world)
	quest_step_changed.emit(quest_step, STEP_TEXT[quest_step])
	fragments_changed.emit(fragments, FRAGMENT_TOTAL)
	health_changed.emit(health, max_health)

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

func choose_upgrade(id: String) -> void:
	selected_upgrade = id
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
	health_changed.emit(health, max_health)
	quest_complete = true
	set_step(Step.COMPLETE)
	AudioManager.play("upgrade_select")

# ------------------------------------------------------------------- health
func damage_player(amount: float) -> void:
	if health <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	AudioManager.play("player_hurt")
	if health <= 0.0:
		player_died.emit()

func heal_player(amount: float) -> void:
	health = minf(health + amount, max_health)
	health_changed.emit(health, max_health)

func revive_full() -> void:
	health = max_health
	health_changed.emit(health, max_health)

# ------------------------------------------------------------------ dialogue
func request_dialogue(speaker: String, lines: Array) -> void:
	dialogue_requested.emit(speaker, lines)

# ----------------------------------------------------------- save/load bridge
func to_dict() -> Dictionary:
	return {
		"world": world,
		"quest_step": quest_step,
		"fragments": fragments,
		"mushroom_activated": mushroom_activated,
		"guide_met": guide_met,
		"quest_complete": quest_complete,
		"selected_upgrade": selected_upgrade,
		"max_health": max_health,
		"health": health,
		"sprint_multiplier": sprint_multiplier,
		"melee_damage": melee_damage,
		"magic_unlocked": magic_unlocked,
		"forest_essence": forest_essence,
	}

func from_dict(d: Dictionary) -> void:
	if d.is_empty():
		return
	world = d.get("world", world)
	quest_step = d.get("quest_step", quest_step)
	fragments = d.get("fragments", fragments)
	mushroom_activated = d.get("mushroom_activated", mushroom_activated)
	guide_met = d.get("guide_met", guide_met)
	quest_complete = d.get("quest_complete", quest_complete)
	selected_upgrade = d.get("selected_upgrade", selected_upgrade)
	max_health = d.get("max_health", max_health)
	health = d.get("health", health)
	sprint_multiplier = d.get("sprint_multiplier", sprint_multiplier)
	melee_damage = d.get("melee_damage", melee_damage)
	magic_unlocked = d.get("magic_unlocked", magic_unlocked)
	forest_essence = d.get("forest_essence", forest_essence)
