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
	{"t": "The Loomstrata", "b": "The second layer, directly beneath the Quietwood. Here the engine stops dressing itself as nature: the light runs cold and violet, geometry frays at the edges, and the ground sometimes forgets it was ever solid. The first place the lie shows its seams."},
	{"t": "Descending the Strata", "b": "L0 Verdant Skin (this forest, the gentlest edit) · L1 Glitched Understory (the seams first show) · L2 Mourning Marsh (grief made liquid) · L3 Hollow Library (truths losing the file) · L4 Wireframe Stratum (the art is gone, only bones) · L5 Drowned Data-Grotto (flooded servers, ghost-light) · L6 Cathedral of Loops (causality bends) · L7 Architect's Core (the thing that dreams the forest). Each layer apologises a little less."},
	{"t": "The Seed", "b": "At the centre is one ordinary memory the whole world was built to avoid. To reach it is to remember; to remember is to choose. It is not a treasure waiting for a seeker — it is a question that cannot be answered, only chosen."},
]

const CHARACTERS := [
	{"t": "Auralis", "b": "A luminous spirit of light, mist and geometric pattern — the world's apology, made tender. She guides you kindly, and quietly hopes you will stop before you remember."},
	{"t": "The Seeker (you)", "b": "An explorer who would not be smoothed. Your Ancient Rootblade is your grief, crystallised. Swing it gently."},
	{"t": "The Cartographer", "b": "A Residual who maps the seams between layers and trades in coordinates of doubt. Trusts no path that is too well lit. (You have not met them yet.)"},
	{"t": "Hale", "b": "A Seeker from before, who descended, saw everything, and chose to stay. Looks fully human in a world of light and lattice — mud on the boots, the only real-seeming thing here, which is why it unnerves. Weighed truth against peace and picked peace, eyes open."},
	{"t": "Emberwright", "b": "A hunched figure of woven embers and cooled glass, pockets full of small kilns. Trades Fragments and rumours, shaping molten Essence in bare hands. Some Fragments it sells are forgeries — and the fakes hold truths the real ones buried. It can no longer tell which are which."},
]

const BESTIARY := [
	{"t": "Corrupted Wisp", "b": "An antibody of the Forgetting. Patrols, detects, then strikes with a telegraphed swell — step back as it swells. Once a witness; now only an alarm. Vulnerable to the Rootblade and the Simulation Pulse. Open the Sight and its weak-seam shows — strike it there for far heavier damage."},
	{"t": "Dimmer", "b": "A cold violet-blue wisp that clouds the eye. Its strike does little harm but smears the world dark for a few seconds — kill it first, before it blinds you in the middle of a fight. The Forgetting's way of making you doubt what you saw."},
	{"t": "Luminous Stag", "b": "A passive remnant that watches and flees. Proof the engine sometimes preserves what it loved — not everything here is a lie."},
	{"t": "True-forms", "b": "Under the Sight, edited things reveal their structure: glyphs, seams, the wire beneath the root. A wisp seen truly shows a weak-seam — strike it there and the lie comes apart faster."},
	{"t": "Clipped Deer", "b": "Luminous Stags rendered with missing limbs that phase through trees — something the system could not quite finish. They move as if the absent parts still guide them. In the Understory, incompleteness is its own kind of grace."},
	{"t": "Echo-Wisps", "b": "Corrupted Wisps wearing the shapes of people the simulation once held. They move like memories of motion. To see one is to learn the Forgetting does not erase — it keeps the shape and deletes the meaning."},
	{"t": "The Choir", "b": "Synchronised Wisps of the Cathedral of Loops, moving as one thought. They mirror your last action against you — a perfect opponent built from your own grammar. To fight them is to argue with your reflection."},
]

const SIGHT_ITEMS := [
	{"t": "The Sight", "b": "Borrowed clarity. Hold [Q] to perceive the layer: the world desaturates to its underlying code and hidden truth-glyphs appear. Costs Lucidity and raises Desync — if Desync peaks, the world frays and the Sight collapses."},
	{"t": "Lucid Cap", "b": "A mystical mushroom-reagent. Press [R] to dissolve one, restoring Lucidity and easing Desync. A fictional artifact — a key, not a habit."},
	{"t": "Fragment of Truth", "b": "A memory the world hid. Collected, it sharpens the Sight and feeds the shrine."},
	{"t": "Ancient Rootblade", "b": "A blade of root and stone — your grief given an edge. Your starting weapon."},
	{"t": "Forest Essence", "b": "Residue of dissolved corruption. Spent at the shrine's Essence Sanctum to walk new Seeker paths."},
	{"t": "Stillwater Lily", "b": "A white lily floating on quiet pools, untouched by Desync. Not a Sight reagent — instead it purges what the Sight costs. The world's apology, bloomed. Seek the quiet places."},
	{"t": "Vertex Dust", "b": "Fine sediment from the seams between layers, glowing at angles the eye was not meant to perceive. The forest paid for this in quiet places; spend it to sharpen what you carry."},
	{"t": "Bound Fragment", "b": "A shard of un-edited memory, crystalline and aching with the weight of what it recalls. Three fed to the shrine open the next layer's gate. The Verdancy does not part with them easily."},
]
