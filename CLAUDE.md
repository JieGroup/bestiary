# bestiary

A personal RL playground for legged creatures. Forked from
[apirrone/Open_Duck_Playground](https://github.com/apirrone/Open_Duck_Playground).
Starts with the Open Duck Mini v2 (42 cm biped), will later hold a custom quadruped
("unicorn").

The goal is not to reproduce upstream. It is to run behavior experiments — reward
shaping, new skills (handstand, kicking, self-play) — and eventually move the whole
pipeline onto a new robot.

Training runs on a rented RunPod GPU. Policy visualization runs locally on the
MacBook Pro.

## Conventions

- Git author is `Jie <jie@morphmind.ai>`. Never add Claude co-author trailers or any
  AI attribution to commits, PRs, or issues.
- Commit subjects: short, imperative, no emoji.
- Every experiment gets a config in `experiments/configs/` and a one-line row in
  `experiments/LOG.md`.
- Results live in `checkpoints/` and are gitignored. Never commit `.onnx` files.

## Layout

Upstream's layout, unchanged, plus:

```
experiments/LOG.md        one row per run
experiments/configs/      one yaml per variant; baseline.yaml is upstream verbatim
Makefile                  view / train / smoke / tb / push / pull
scripts/sync_runpod.sh    rsync code up, checkpoints down
scripts/view.sh           mjpython wrapper for mujoco_infer.py
```

## Remotes

- `origin` — JieGroup/bestiary (this fork)
- `upstream` — apirrone/Open_Duck_Playground. `make sync-upstream` to pull their
  improvements, especially in `playground/common/`.

The hardware repo is cloned read-only alongside this one at `../Open_Duck_Mini`
(branch `v2`) for MJCF assets and docs.

## Environment

Upstream uses **uv**. Do not substitute conda or pip.

```bash
uv sync
uv run python -c "import jax; print(jax.default_backend())"   # must print: gpu on the pod
```

Two gotchas, both already bitten:

1. **TF32 on RTX 40-series.** JAX defaults to TF32 matmuls on Ampere/Ada, and the
   reduced precision destabilizes RL training and breaks reproducibility. On the pod,
   put this in `~/.bashrc`:
   ```bash
   export JAX_DEFAULT_MATMUL_PRECISION=highest
   ```
2. **macOS MuJoCo viewer needs `mjpython`, not `python`.** The Makefile and
   `scripts/view.sh` both switch on `uname` so this should not resurface.

## Running things

```bash
make view POLICY=BEST_WALK_ONNX_2.onnx        # local, macOS
make smoke                                     # 10M steps, on the pod
make train TASK=flat_terrain_backlash STEPS=150000000
make tb                                        # tensorboard on checkpoints/
make push / make pull                          # rsync
```

Set `RUNPOD_HOST`, `RUNPOD_PORT`, `RUNPOD_DIR` in the shell before push/pull.

Full runs are 300M steps (upstream's current best); `runner.py` defaults to 150M.
10–20M is enough to see a policy's character — reserve full runs for variants worth
polishing.

## Where the knobs are

- `playground/open_duck_mini_v2/joystick.py` — `default_config()` holds every reward
  scale, noise scale, push config, and command range. `USE_IMITATION_REWARD` and
  `USE_MOTOR_SPEED_LIMITS` are module-level flags above it.
- `playground/open_duck_mini_v2/custom_rewards.py` — currently only
  `reward_imitation`. New task-specific reward terms go here.
- `playground/common/rewards.py` — the generic library. Already has
  `cost_orientation`, `cost_base_height`, `cost_feet_height`, `cost_feet_clearance`,
  `reward_feet_air_time`, `reward_feet_phase` and more. Check here before writing a
  new term.
- `playground/open_duck_mini_v2/base.py` — observation accessors:
  `get_gravity` (gravity vector in body frame), `get_feet_pos`, `get_local_linvel`,
  `get_gyro`, `get_actuator_joints_qpos/qvel`.
- `playground/open_duck_mini_v2/constants.py` — site, geom, sensor, joint names.
  `FEET_SITES = ["left_foot", "right_foot"]`, `ROOT_BODY = "trunk_assembly"`.

Tasks: `flat_terrain`, `rough_terrain`, `flat_terrain_backlash`,
`rough_terrain_backlash`. Envs: `joystick`, `standing`.

## Known gap: configs are not wired up yet

`runner.py` exposes only `--env`, `--task`, `--num_timesteps`, `--output_dir`,
`--restore_checkpoint_path`. Everything else is hardcoded in `default_config()`.
`experiments/configs/*.yaml` currently document intent but nothing reads them. First
code task: add a `--config path.yaml` flag that overlays the YAML onto the
`ConfigDict` before the env is constructed, and have the runner copy the resolved
config into the output dir so a checkpoint is self-describing.

## Reading results

Every reward term is logged separately: `reward/<name>` and `cost/<name>` in
TensorBoard (see `joystick.py` around line 474). **Read the per-term curves, not just
total reward.** `alive=20.0` dominating produces a robot that stands still and
collects the survival bonus — total reward looks excellent and nothing moves.

## Reference

| | |
|---|---|
| Upstream training repo | https://github.com/apirrone/Open_Duck_Playground |
| Hardware repo | https://github.com/apirrone/Open_Duck_Mini |
| On-robot runtime | https://github.com/apirrone/Open_Duck_Mini_Runtime |
| Reference motion generator | https://github.com/apirrone/Open_Duck_reference_motion_generator |
| MuJoCo Playground | https://github.com/google-deepmind/mujoco_playground |
| BD-X imitation reward paper | https://la.disneyresearch.com/wp-content/uploads/BD_X_paper.pdf |
| OP3 Soccer | https://arxiv.org/html/2304.13653 |
| Motor identification (BAM) | https://github.com/Rhoban/bam |
| Discord | https://discord.gg/UtJZsgfQGe |
