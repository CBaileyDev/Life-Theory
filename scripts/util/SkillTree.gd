class_name SkillTree
extends RefCounted
## SkillTree
## Four "Seeker Paths", each a 3-node chain rooted at one of the original
## keystone upgrades. This table is the SINGLE SOURCE OF TRUTH for every
## upgrade: its id, name, description, cost (Forest Essence), prerequisite, and
## — crucially — its gameplay effect, expressed as data so GameState applies it
## generically. Adding or rebalancing an upgrade is a pure data edit here; no
## other file needs to change.
##
## node fields:
##   id     unique string id (used by saves and prerequisites)
##   name   display name
##   desc   short description (shown in the Sanctum grid)
##   flavor (roots only) richer copy for the first free keystone choice
##   cost   Forest Essence price (root keystones are granted free at the shrine)
##   req    prerequisite node id ("" for a root)
##   effect what it does, as data applied by GameState._apply_effect:
##            "add"   {field: delta}    additive (e.g. +40 melee_damage)
##            "set"   {field: value}    absolute (e.g. sprint_multiplier = 2.2 — does NOT stack)
##            "flag"  {field: bool}     boolean unlock (e.g. magic_unlocked)
##            "clamp" {field: [lo, hi]} clamp after add/set
##            "heal_full": true         set health to max_health afterward

const PATHS := [
	{
		"name": "Warden of Bark",
		"nodes": [
			{"id": "heart_of_bark", "name": "Heart of Bark", "desc": "+60 max vitality.",
				"flavor": "Roots run deep. Increase your maximum vitality (+60).",
				"cost": 60, "req": "", "effect": {"add": {"max_health": 60.0}, "heal_full": true}},
			{"id": "bark_skin", "name": "Bark Skin", "desc": "+40 max vitality.",
				"cost": 60, "req": "heart_of_bark", "effect": {"add": {"max_health": 40.0}, "heal_full": true}},
			{"id": "ironwood", "name": "Ironwood Heart", "desc": "+40 vitality; take 15% less damage.",
				"cost": 90, "req": "bark_skin",
				"effect": {"add": {"max_health": 40.0, "damage_reduction": 0.15},
					"clamp": {"damage_reduction": [0.0, 0.8]}, "heal_full": true}},
		],
	},
	{
		"name": "Hidden Path",
		"nodes": [
			{"id": "fleet_hidden_path", "name": "Fleet of the Hidden Path", "desc": "Sprint faster (x1.6).",
				"flavor": "The trail carries you. Sprint noticeably faster.",
				"cost": 60, "req": "", "effect": {"set": {"sprint_multiplier": 1.6}}},
			{"id": "fleetfoot", "name": "Fleetfoot", "desc": "Sprint faster still (x1.9).",
				"cost": 60, "req": "fleet_hidden_path", "effect": {"set": {"sprint_multiplier": 1.9}}},
			{"id": "windstep", "name": "Windstep", "desc": "Sprint like the wind (x2.2).",
				"cost": 90, "req": "fleetfoot", "effect": {"set": {"sprint_multiplier": 2.2}}},
		],
	},
	{
		"name": "Rootblade",
		"nodes": [
			{"id": "rootblade_strength", "name": "Rootblade Strength", "desc": "+40 melee damage.",
				"flavor": "The Ancient Rootblade strikes harder (+40 melee damage).",
				"cost": 60, "req": "", "effect": {"add": {"melee_damage": 40.0}}},
			{"id": "keen_edge", "name": "Keen Edge", "desc": "+40 melee damage.",
				"cost": 60, "req": "rootblade_strength", "effect": {"add": {"melee_damage": 40.0}}},
			{"id": "grovecleaver", "name": "Grovecleaver", "desc": "+80 melee damage.",
				"cost": 90, "req": "keen_edge", "effect": {"add": {"melee_damage": 80.0}}},
		],
	},
	{
		"name": "Simulation",
		"nodes": [
			{"id": "simulation_pulse", "name": "Simulation Pulse", "desc": "Unlock the magic pulse (RMB).",
				"flavor": "Glimpse the code beneath. Unlock a magic pulse — Right-Click to cast.",
				"cost": 60, "req": "", "effect": {"flag": {"magic_unlocked": true}}},
			{"id": "pulse_power", "name": "Pulse Resonance", "desc": "Pulse hits 60% harder.",
				"cost": 60, "req": "simulation_pulse", "effect": {"set": {"magic_damage_mult": 1.6}}},
			{"id": "pulse_storm", "name": "Pulse Storm", "desc": "Pulse hits 120% harder.",
				"cost": 90, "req": "pulse_power", "effect": {"set": {"magic_damage_mult": 2.2}}},
		],
	},
	{
		"name": "Seer",
		"nodes": [
			{"id": "seers_eye", "name": "Seer's Eye", "desc": "Weak-seam strikes (Sight open) cut far deeper (x2.4).",
				"flavor": "See the seam in everything. Striking a wisp's weak-seam with the Sight open cuts far deeper.",
				"cost": 60, "req": "", "effect": {"set": {"sight_weakpoint_mult": 2.4}}},
			{"id": "truths_edge", "name": "Truth's Edge", "desc": "Weak-seam strikes devastate (x3.2).",
				"cost": 60, "req": "seers_eye", "effect": {"set": {"sight_weakpoint_mult": 3.2}}},
			{"id": "grief_made_edge", "name": "Grief Made Edge", "desc": "Weak-seam strikes shatter (x4.2); +20 vitality.",
				"cost": 90, "req": "truths_edge",
				"effect": {"set": {"sight_weakpoint_mult": 4.2}, "add": {"max_health": 20.0}, "heal_full": true}},
		],
	},
]

## Look up a node by id across all paths. Returns {} if not found.
static func find_node(id: String) -> Dictionary:
	for path in PATHS:
		for node in path["nodes"]:
			if node["id"] == id:
				return node
	return {}

## The four root keystones (one per path) — offered as the first free choice.
static func roots() -> Array:
	var out: Array = []
	for path in PATHS:
		for node in path["nodes"]:
			if node["req"] == "":
				out.append(node)
				break
	return out
