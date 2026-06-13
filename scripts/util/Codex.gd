class_name Codex
extends RefCounted
## Codex
## Static lore content for the Journal's tabs, drawn from the design bible
## (docs/design/). Each entry is {"t": title, "b": body}. Kept terse and in
## the established voice — no filler.

const STORY := [
	{"t": "The Verdancy", "b": "The world you woke in is not a world. It is a grief-engine: a constructed reality that metabolises unbearable memory into landscape. The forest is its gentlest edit — the first layer."},
	{"t": "The Strata", "b": "Beneath the Quietwood lie coarser layers — the Loomstrata, the Hollow Census, Anhedron, the Unrendered — each a heavier compression of the truth, descending toward the Seed."},
	{"t": "The Seed", "b": "At the centre is one ordinary memory the entire world was built to avoid. To reach it is to remember. To remember is to choose."},
	{"t": "The Forgetting", "b": "Not a villain — a mercy that overstayed. The engine's instinct to smooth away pain, sharpened into censorship. It edits whatever hurts. Including you."},
	{"t": "Residuals", "b": "Most who arrive are gently rewritten and forget they ever grieved. A Residual arrives already grieving, and cannot be smoothed. You are one. The Sight is your inheritance."},
]

const CHARACTERS := [
	{"t": "Auralis", "b": "A luminous spirit of light, mist and geometric pattern — the world's apology, made tender. She guides you kindly, and quietly hopes you will stop before you remember."},
	{"t": "The Seeker (you)", "b": "An explorer who would not be smoothed. Your Ancient Rootblade is your grief, crystallised. Swing it gently."},
	{"t": "The Cartographer", "b": "A Residual who maps the seams between layers and trades in coordinates of doubt. Trusts no path that is too well lit. (You have not met them yet.)"},
]

const BESTIARY := [
	{"t": "Corrupted Wisp", "b": "An antibody of the Forgetting. Patrols, detects, then strikes with a telegraphed swell — step back as it swells. Once a witness; now only an alarm. Vulnerable to the Rootblade and the Simulation Pulse."},
	{"t": "Luminous Stag", "b": "A passive remnant that watches and flees. Proof the engine sometimes preserves what it loved — not everything here is a lie."},
	{"t": "True-forms", "b": "Under the Sight, edited things reveal their structure: glyphs, seams, the wire beneath the root."},
]

const SIGHT_ITEMS := [
	{"t": "The Sight", "b": "Borrowed clarity. Hold [Q] to perceive the layer: the world desaturates to its underlying code and hidden truth-glyphs appear. Costs Lucidity and raises Desync — if Desync peaks, the world frays and the Sight collapses."},
	{"t": "Lucid Cap", "b": "A mystical mushroom-reagent. Press [R] to dissolve one, restoring Lucidity and easing Desync. A fictional artifact — a key, not a habit."},
	{"t": "Fragment of Truth", "b": "A memory the world hid. Collected, it sharpens the Sight and feeds the shrine."},
	{"t": "Ancient Rootblade", "b": "A blade of root and stone — your grief given an edge. Your starting weapon."},
	{"t": "Forest Essence", "b": "Residue of dissolved corruption. Spent at the shrine's Essence Sanctum to walk new Seeker paths."},
]
