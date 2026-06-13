class_name SkillTree
extends RefCounted
## SkillTree
## Four "Seeker Paths", each a 3-node chain rooted at one of the original
## keystone upgrades. Nodes: id, name, desc, cost (Forest Essence), req (the
## prerequisite node id, "" for a root). Effects are applied in
## GameState._apply_upgrade(). The first keystone is granted free at the shrine;
## everything else is bought at the Essence Sanctum.

const PATHS := [
	{
		"name": "Warden of Bark",
		"nodes": [
			{"id": "heart_of_bark", "name": "Heart of Bark", "desc": "+60 max vitality.", "cost": 60, "req": ""},
			{"id": "bark_skin", "name": "Bark Skin", "desc": "+40 max vitality.", "cost": 60, "req": "heart_of_bark"},
			{"id": "ironwood", "name": "Ironwood Heart", "desc": "+40 vitality; take 15% less damage.", "cost": 90, "req": "bark_skin"},
		],
	},
	{
		"name": "Hidden Path",
		"nodes": [
			{"id": "fleet_hidden_path", "name": "Fleet of the Hidden Path", "desc": "Sprint faster (x1.6).", "cost": 60, "req": ""},
			{"id": "fleetfoot", "name": "Fleetfoot", "desc": "Sprint faster still (x1.9).", "cost": 60, "req": "fleet_hidden_path"},
			{"id": "windstep", "name": "Windstep", "desc": "Sprint like the wind (x2.2).", "cost": 90, "req": "fleetfoot"},
		],
	},
	{
		"name": "Rootblade",
		"nodes": [
			{"id": "rootblade_strength", "name": "Rootblade Strength", "desc": "+40 melee damage.", "cost": 60, "req": ""},
			{"id": "keen_edge", "name": "Keen Edge", "desc": "+40 melee damage.", "cost": 60, "req": "rootblade_strength"},
			{"id": "grovecleaver", "name": "Grovecleaver", "desc": "+80 melee damage.", "cost": 90, "req": "keen_edge"},
		],
	},
	{
		"name": "Simulation",
		"nodes": [
			{"id": "simulation_pulse", "name": "Simulation Pulse", "desc": "Unlock the magic pulse (RMB).", "cost": 60, "req": ""},
			{"id": "pulse_power", "name": "Pulse Resonance", "desc": "Pulse hits 60% harder.", "cost": 60, "req": "simulation_pulse"},
			{"id": "pulse_storm", "name": "Pulse Storm", "desc": "Pulse hits 120% harder.", "cost": 90, "req": "pulse_power"},
		],
	},
]
