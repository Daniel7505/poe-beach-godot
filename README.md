# The Coast — PoE Beach (Godot 4)

A small **top-down beach zone** inspired by *Path of Exile* Act 1’s **The Coast**, built in **Godot 4**.

You play a scrappy exile on warm sand and shallow water: fight crabs, zombies, spitters, and chargers; pick up life flasks and gold XP orbs; level up for real skill unlocks; and clear the shoreline.

This is a **fan-inspired learning / prototype project** — not affiliated with Grinding Gear Games.

---

## Features

- **64×64 hand-painted-style beach tiles** (sand variants, wet sand, dunes, rocks, shore foam)
- **Calm animated water** (GPU swell shader + soft foam)
- **Swaying palm trees** with layered shadows
- **Combat**: slash, fireball, frost nova, dash, and **Lightning Arc** (unlocked at level 4)
- **Enemy variety**: flankers, tanks, kite-spitters, charge rushers
- **Loot**: magnet life flasks, XP orbs, kill drops
- **Progression**: XP bar, levels, skill unlocks (Vitality, Embers, Arc, Swift, Cold Snap, …)
- **Polish**: particles, procedural SFX, camera shake, level-up celebration, light day/evening tint
- **No external art pack required** — tiles/sprites/SFX generate at runtime (atlas also saved to `assets/tiles/`)

---

## Requirements

| Item | Version / notes |
|------|------------------|
| **Godot** | **4.3+** (developed on **4.7**) |
| **OS** | Windows / macOS / Linux |
| **GPU** | Any that runs Godot 2D Forward+ |

Download Godot: [https://godotengine.org/download](https://godotengine.org/download)

---

## How to run

### Option A — Godot Editor (recommended)

1. Install **Godot 4.x**.
2. Open Godot → **Import**.
3. Select this project folder (the one containing `project.godot`).
4. Click **Import & Edit**.
5. Press **F5** (or the **Play** button).

Main scene is already set to `scenes/main.tscn`.

### Option B — From the command line

```bash
# Example (adjust the path to your Godot executable)
godot --path "/path/to/this/project"
```

On Windows, that may look like:

```powershell
& "C:\Path\To\Godot_v4.x_win64.exe" --path "C:\Path\To\poe-beach-godot"
```

---

## Controls

| Input | Action |
|--------|--------|
| **W A S D** | Move |
| **Mouse** | Aim |
| **Left click** | Basic attack (slash) |
| **Right click** | Fireball |
| **Q** | Frost Nova |
| **Space** | Dash (brief i-frames) |
| **E** | Lightning Arc *(unlocked at Level 4)* |
| **R** | Restart after death |

---

## Gameplay tips

- **Shallow water** slows you — fight on sand when you can.
- **Gold orbs** = XP (and a bit of score). Magnet toward you when close.
- **Red flasks** heal; some drop from kills.
- **Spit crawlers** kite and spit — don’t stand still.
- **Sand chargers** telegraph, then rush — sidestep the charge.
- **Level up** grants permanent upgrades (see below). Clear packs, pick up orbs, get stronger.

---

## Level rewards

| Level | Unlock |
|------:|--------|
| 2 | **Vitality** — +25 max life |
| 3 | **Embers** — stronger fireball (+damage, +pierce) |
| 4 | **Lightning Arc** — press **E** to chain-zap nearby foes |
| 5 | **Swift Exile** — move faster, better dash |
| 6 | **Cold Snap** — bigger, harder frost nova |
| 7 | **Sharp Edge** — stronger / faster basic attack |
| 8 | **Power** — +all damage, +max life |
| 9+ | **Ascendancy** — soft scaling (damage / life, occasional multi-fireball) |

---

## Project layout

```
.
├── project.godot          # Godot project config (open this folder)
├── README.md
├── assets/tiles/          # Generated coast atlas PNG (64×64 tiles)
├── scenes/                # Packed scenes (player, enemies, loot, UI)
├── scripts/               # GDScript gameplay / map / VFX / audio
└── shaders/               # Water wave shader
```

### Design highlights

- **`GameManager`** autoload — health, score, XP, level  
- **`Sfx`** autoload — procedural sound effects (no external audio files)  
- **Multi-layer TileMap** — sand base, water + shader, rocks with collision  
- **Skill progression** — `scripts/player/skill_progression.gd`  

---

## Performance notes

- Ground is **TileMapLayer** (not thousands of loose sprites)
- Water uses a **cheap canvas shader** (low-frequency swell, not heavy caustics)
- Particles and SFX use small pools / one-shot bursts
- Map size is balanced for 64×64 tiles (`36×24` cells)

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Project won’t open | Use **Godot 4.x**, not Godot 3 |
| Black screen / no main scene | Project → Project Settings → Application → Run → Main Scene = `res://scenes/main.tscn` |
| Script errors after pull | Open once in the editor so `.uid` / import files refresh |
| No sound | Check system volume; SFX are procedural and play on Master bus |
| Water looks wrong | Ensure `shaders/water_wave.gdshader` is present; re-open the project |

---

## Expanding the project

Ideas that fit this codebase:

- Hand-paint / replace `assets/tiles/coast_atlas.png` (load-only pipeline)
- Real audio packs instead of procedural SFX  
- More skill tree choices on level-up  
- A tiny “Lioneye’s Watch” hub / zone transition  
- Save/load run progress  

---

## License & credits

- **Code & prototype assets**: personal / learning project — use freely with attribution appreciated.  
- **Path of Exile** is a trademark of **Grinding Gear Games**. This is an unofficial fan-inspired prototype only.  
- Built with **[Godot Engine](https://godotengine.org/)**.

---

## Credits

Made as a collaborative Godot 4 prototype (“PoE Beach / The Coast”).  
Thanks for playing — exile safe out there.
