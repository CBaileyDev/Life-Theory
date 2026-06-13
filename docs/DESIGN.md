# The First Layer — design notes

## Fantasy
An explorer lost in a quiet, realistic forest discovers a glowing mushroom on an
ancient shrine. Touching it reveals the *first layer*: a hidden magical/simulation
stratum where spirits, runes, and creatures become visible. The guide Auralis
hints that reality is constructed, and the player gathers Fragments of Truth to
begin understanding it.

Tone references (atmosphere & systems only, never assets/IP): the open
exploration & light RPG progression of large fantasy RPGs; the wilderness tension
& discovery of survival games; the cinematic magical wonder of magic-school
fantasy.

## The two world states
| | **Natural Forest** | **First Layer** |
|---|---|---|
| Lighting | warm, neutral sun | cool violet/blue, dimmer |
| Fog | light grey-green, thin | violet-blue, denser |
| Glow/bloom | subtle | stronger |
| Runes on trees | hidden | glowing (shader) |
| Luminous trail | hidden | revealed, animated |
| Auralis | hidden | present & interactable |
| Corrupted Wisps | inactive/invisible | active & hostile |
| Luminous Stag | hidden | roaming |
| Fragments | inactive | collectible |
| Objective | *find the glowing mushroom* | *gather truth, choose a path* |

Transition: screen distortion + colour flash (`screen_transition.gdshader`),
particle burst at the shrine, camera FOV punch, audio cue, and a 1s palette tween
of light/fog/ambient.

## Quest — "The First Layer"
`GameState.Step`: FIND_MUSHROOM → FOLLOW_TRAIL → MEET_GUIDE → COLLECT_FRAGMENTS
→ RETURN_SHRINE → CHOOSE_UPGRADE → COMPLETE. The HUD always shows the current
objective; the fragment counter appears once collection begins.

## Level layout (top-down, +Z is "behind" the spawn)
```
        (-X)                                   (+X)
          .   trees / foliage ring (boundary walls)   .
                       [stag ~ (11,-11)]
     [wisp home ~ (-8,-7)]        [fragment ~ (7.5,-5.5)]
                 \                 /
   [fragment (-7,-6)]   ( SHRINE 0,-2 )   [Auralis (6,3)]
                 \         |  mushroom    /
                  [fragment (-1,-12)]
                           |
                        clearing (r≈9.5)
                           |
        ===================|=================== mossy path
                           |
                      SPAWN (0, 18)   ← player faces -Z (toward clearing)
```

## Combat & progression
- **Ancient Rootblade** (melee): Left-Click, ~0.45s cadence, cone hit detection,
  34 dmg (kills a 100-HP wisp in 3 hits).
- **Corrupted Wisp**: floating AI — patrols, detects within 14 m, chases, attacks
  for 12 dmg on a ~1.1 s cadence within 2.2 m, dies with a particle burst.
- **Upgrades** (choose one): Heart of Bark (+60 max HP), Fleet of the Hidden Path
  (1.6× sprint), Rootblade Strength (+40 melee), Simulation Pulse (unlocks the
  Right-Click magic projectile, 45 dmg).

## UI
Dark-fantasy, minimal, glowing accents (`UITheme`): Main Menu, Settings, Pause,
Quest HUD, Fragment counter, Health bar, Interaction prompt, Dialogue box,
Upgrade selection, transient toasts.
