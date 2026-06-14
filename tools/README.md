# Dev tools

Editor/CI utilities for developing *The First Layer*. **Not shipped** — both
export presets exclude `tools/*`.

## FPS probe — `FpsProbe.tscn`

Loads the Forest level on the real GPU, warms up past the world-build hitch,
then prints a `FPS_RESULT` line (present FPS, GPU/CPU frame time, window size,
adapter) and saves a screenshot to `/tmp/tol_shot_q<quality>.png`.

```bash
# Low preset at 70% render scale (the M5 default)
TOL_QUALITY=0 TOL_RS=0.7 godot res://tools/FpsProbe.tscn
# Medium / High
TOL_QUALITY=1 TOL_RS=0.85 godot res://tools/FpsProbe.tscn
TOL_QUALITY=2 TOL_RS=1.0  godot res://tools/FpsProbe.tscn
```

`TOL_QUALITY` = 0 Low / 1 Medium / 2 High. `TOL_RS` = render scale 0.5–1.0.
(macOS caps windowed presentation to the display refresh, so `present_fps` tops
out at the monitor's Hz; watch GPU frame time for true headroom on platforms
that report it.)

## Upgrade effects regression test — `UpgradeTest.tscn`

Asserts that the data-driven upgrade effects (`SkillTree.PATHS` +
`GameState._apply_effect`) produce the exact stats expected for all 12 nodes,
and that an unknown id is refused without spending essence. Run after editing
the upgrade table:

```bash
godot --headless res://tools/UpgradeTest.tscn   # prints OK/FAIL per node, then UPGRADE_TEST PASS
```
