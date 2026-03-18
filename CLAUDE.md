# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

A tower defense game built with **Godot 4.6** using GDScript. Targets web (Emscripten/WebAssembly) and mobile platforms with landscape orientation and touch support.

## Build & Export

There is no CLI build system, Makefile, or CI pipeline. The game is exported manually via the Godot editor:

- **Run locally:** Open `project.godot` in Godot 4.6 and press F5
- **Web export:** Editor > Project > Export > Web (HTML5) — outputs to `export/web/`
- **Main scene:** `res://scenes/Main.tscn`

## Architecture

### Central Controller Pattern

`Main.gd` is the single game controller — it manages all game state (gold, lives, waves), spawns enemies, handles input, builds the UI programmatically, and orchestrates tower placement. There are no autoloads/singletons.

### Input State Machine

`_unhandled_input()` in Main.gd implements three states:
1. **Placing Tower** — ghost tower follows cursor; left-click confirms, right-click/ESC cancels
2. **Menu Open** — tower selection menu visible; any click or ESC closes it
3. **Normal** — left-click/touch opens the tower selection menu at click position

### Tower System

- `Tower.gd` is the base class with targeting logic, damage, fire rate, and range
- Towers target the enemy **furthest along the path** within range (group-based query on "enemies" each frame)
- Four variants inherit from Tower.gd: `Archer.gd`, `Magic.gd`, `Boom.gd`, `SwordGirl.gd` — each overrides `_ready()` to set stats, SwordGirl also overrides `fire()` for attack animations
- Tower scenes: `Sprite2D` + `RangeArea` (Area2D with CircleShape2D)

### Enemy System

- `Enemy.gd` extends `PathFollow2D` — enemies follow `Path2D` defined in Main.tscn
- Enemies self-register to the "enemies" group in `_ready()`
- Health scales incrementally (+5 per spawn via `current_wave_health`)
- On death: grants gold reward. On path completion: deducts a life

### Tower Placement Flow

1. Player clicks → selection menu appears at click position (built in `_build_selection_menu()`)
2. Player picks a tower type → ghost tower (50% transparent, disabled collision) follows cursor
3. Confirm click → ghost becomes real tower (full opacity, collision enabled), gold deducted
4. `SummonEffect` plays cherry-blossom-themed CPUParticles at placement site

### UI

All UI is built programmatically in Main.gd (not from scene files):
- HUD: gold (`💰`), lives (`❤️`), speed toggle button (`▶ 1x` / `⏩ 2x`)
- Selection menu: dark panel with emoji-labeled buttons for each tower type plus cancel

### Tower Stats Reference

| Tower  | Cost | Damage | Fire Rate | Range | DPS  |
|--------|------|--------|-----------|-------|------|
| Sword  | 50g  | 25     | 1.5/s     | 150   | 37.5 |
| Archer | 75g  | 15     | 2.0/s     | 300   | 30.0 |
| Magic  | 100g | 40     | 0.5/s     | 200   | 20.0 |
| Boom   | 150g | 80     | 0.3/s     | 150   | 24.0 |

## Key Patterns

- **Group-based targeting:** Towers find enemies via `get_tree().get_nodes_in_group("enemies")` — no direct references between towers and enemies
- **Signal connections** are made in `_ready()` methods, often with lambdas
- **Tweens** are used for enemy hit flash (red modulation) and SwordGirl attack animations
- **Scene preloading:** Tower scenes are preloaded in Main.gd's `tower_scenes` dictionary
