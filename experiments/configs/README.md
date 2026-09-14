# Experiment configs

One YAML per variant. `baseline.yaml` is the upstream `joystick.default_config()`
written out verbatim — diff against it to see what a variant actually changes.

Nothing reads these yet. `runner.py` only exposes `--env`, `--task`,
`--num_timesteps`, `--output_dir`; every other knob is hardcoded in
`joystick.default_config()`. Wiring a `--config` flag that overlays a YAML onto the
ConfigDict is the first code task — see CLAUDE.md.
