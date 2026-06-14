class_name Content
extends RefCounted
## Content
## All player-facing narrative strings in one place (easy to localise/edit).
## Tone: calm, poetic, slightly unsettling — the forest is the "first layer"
## of a constructed reality. No third-party IP; the mushroom is purely mystical.

const FRAGMENT_LINES := [
	["The dew does not fall. It is placed.", "Someone decided where each drop would rest."],
	["Listen. The birdsong repeats.", "A loop, seven seconds long. You were meant to forget."],
	["Beneath the soil runs a seam of light.", "The roots drink from it. This world has a wire."],
]

const AURALIS_FIRST := [
	"You can see it now.",
	"The forest is not the world. It is the first layer.",
	"Gather three Fragments of Truth and carry them to the shrine.",
	"What you uncover will shape the seeker you become.",
]

const AURALIS_HINTS := [
	["Three truths sleep among the trees.", "Begin where the light feels too perfect."],
	["Two remain. The forest grows uneasy.", "Follow the things that repeat."],
	["One last truth. It hides where the world thins.", "You are close to the seam now."],
]

const AURALIS_RETURN := [
	"You carry all three truths now.",
	"Take them to the shrine. Let the first layer answer for itself.",
]

const AURALIS_DONE := [
	"You held the truth, and the layer trembled.",
	"This forest was only the surface.",
	"Below it wait deeper layers, and quieter lies.",
]

# Spoken on arriving in the second biome (the Loomstrata), after the descent.
const LOOMSTRATA_ARRIVAL := [
	"You felt the forest thin, and let yourself fall through.",
	"This is the Loomstrata — where the world stops pretending to be nature.",
	"The light here is wrong on purpose. Trust your Sight, not your eyes.",
	"Somewhere below, a memory is waiting to be remembered. Keep descending.",
]

const SHRINE_FIRST_TOUCH := [
	"The mushroom glows, and the world exhales.",
	"Edges soften. The first layer begins to peel away.",
]

# Beat-specific Auralis lines, wired into triggers as those systems are built.
const SIGHT_FIRST := [
	"The world holds its breath. You are seeing the wire beneath the root.",
	"Everything you loved just became a pattern — do not blink, or you will forget what you saw.",
	"You cannot unsee this. I do not know if I should say that is a mercy.",
]
const DESYNC_WARNING := [
	"The world grows uncertain beneath you. The render strains.",
	"You have asked too much of your borrowed sight — or the forest is running out of kindness.",
	"Rest. Let the fraying settle, and the layer remember how to hold you.",
]
const VISTA_REVEAL := [
	"The canopy breaks here. Below it, something that is not forest.",
	"You were not meant to see this far.",
	"Keep the sight of it tender — the moment you name it, the world will correct the error.",
]
const POND_MUSING := [
	"Still water. Listen — no birdsong here. The loop is broken.",
	"You have found a place the world forgot to edit.",
	"Let your reflection ask the questions yours does not dare.",
]
const WRONG_TREE := [
	"The tree was never a tree.",
	"Something the world dressed in bark, hoping you would not strike it.",
]

const UPGRADE_INTRO := "Choose how you will see the layers beneath."
const TITLE_CARD_SUB := "Every world begins with a single, beautiful lie."

# In-world loading-screen tips (canon: The Verdancy / the Strata / Sight).
const LORE_TIPS := [
	"The dew does not fall. It is placed.",
	"The forest is the gentlest edit. Be wary of the kinder layers.",
	"Birdsong loops every seven seconds. You were meant to forget.",
	"Grief does not vanish here. It is made into landscape.",
	"A Residual is one who arrived already grieving — and so cannot be smoothed.",
	"Auralis is the world's apology, made tender.",
	"The Forgetting is not cruelty. It is compassion with the edges filed off.",
	"Wisps were witnesses once, before their memories were stripped.",
	"To hold a Fragment of Truth is to remember what the world spent itself hiding.",
	"Sight is borrowed clarity. Spend it before the world frays.",
	"Beneath the Quietwood, the resolution thins.",
	"The Rootblade is your grief, crystallised. Swing it gently.",
	"Some seekers reach the Seed and choose to forget again.",
	"Do not trust a path that is too perfectly lit.",
	"In the Loomstrata, the ground forgets it was ever solid.",
	"A wisp that swells is a wisp about to strike. Read it, then step back.",
	"Essence is grief, refined. Spend it to become, not to forget.",
	"Every layer you descend, the world apologises a little less.",
	"The stag remembers something the engine could not bear to delete.",
	"The Quietwood breathes with your fear. Every time you notice it, the editing deepens.",
	"Sight shows the seams, but looking too long teaches you the structure is all there ever was.",
	"The Rootblade does not cut through grief. It cuts the memory of grief, which is sharper.",
	"The Forgetting is the world's own immune system, trying to protect itself from the thing it hid.",
	"Every fragment you carry sharpens the Sight and pulls you deeper.",
	"Desync is not malfunction. It is clarity — and clarity costs the world its ability to hold you.",
	"When the Sight fades, it is because you have seen enough to hurt. That is all the Forgetting asks.",
	"Forest Essence is the Verdancy's sorrow, refined down to something you can spend.",
	"A Residual arrives too full of their own grief to be smoothed into something else.",
	"In the Wireframe Stratum the geometry shows itself bare — the truth was always simpler than the leaves made it seem.",
	"The Seed is not a treasure. It is a question that cannot be answered, only chosen.",
	"The depths love you enough to tell. The forest only loved you enough to lie.",
	"Strike a tree that is too still. Some of them were never trees.",
]

