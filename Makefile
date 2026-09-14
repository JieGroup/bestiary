# bestiary — RL playground for legged creatures
#
# Local (macOS)  : view, tb, push, pull
# RunPod (Linux) : train, smoke
#
# RunPod connection is configured by env vars, e.g. in ~/.zshrc:
#   export RUNPOD_HOST=root@213.x.x.x
#   export RUNPOD_PORT=22
#   export RUNPOD_DIR=/workspace/bestiary

SHELL := /bin/bash

POLICY ?= BEST_WALK_ONNX_2.onnx
TASK   ?= flat_terrain_backlash
ENV    ?= joystick
STEPS  ?= 150000000
OUT    ?= checkpoints

RUNPOD_HOST ?= root@CHANGE_ME
RUNPOD_PORT ?= 22
RUNPOD_DIR  ?= /workspace/bestiary

# macOS needs mjpython for the passive MuJoCo viewer; Linux uses plain python.
UNAME := $(shell uname -s)
ifeq ($(UNAME),Darwin)
PYVIEW := mjpython
else
PYVIEW := python
endif

.PHONY: help view train smoke tb push pull sync-upstream

help:
	@grep -E '^[a-z-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN{FS=":.*?## "}{printf "  %-14s %s\n", $$1, $$2}'

view: ## Local MuJoCo viewer. make view POLICY=checkpoints/x.onnx
	uv run $(PYVIEW) playground/open_duck_mini_v2/mujoco_infer.py -o $(POLICY)

train: ## Training run. make train TASK=flat_terrain_backlash STEPS=150000000
	uv run playground/open_duck_mini_v2/runner.py \
		--env $(ENV) --task $(TASK) --num_timesteps $(STEPS) --output_dir $(OUT)

smoke: ## 10M-step run to validate the pipeline end to end
	$(MAKE) train STEPS=10000000 OUT=checkpoints/smoke

tb: ## TensorBoard on the checkpoint dir
	uv run tensorboard --logdir $(OUT) --port 6006

push: ## rsync code up to RunPod
	bash scripts/sync_runpod.sh push

pull: ## rsync checkpoints down from RunPod
	bash scripts/sync_runpod.sh pull

sync-upstream: ## Fetch and merge apirrone/Open_Duck_Playground into main
	git fetch upstream && git merge upstream/main
