# AI Context for ReloadUI Mod

## Repository Scope - CRITICAL
**This repository ONLY tracks the ReloadUI mod itself.**

### Allowed Files (`.gitignore` whitelist):
```
mods-unpacked/Calico-ReloadUI/
mods-unpacked/Calico-ReloadUI/**
.gitignore
```

### Forbidden Modifications:
❌ **DO NOT** modify any files outside `mods-unpacked/Calico-ReloadUI/`
❌ **DO NOT** edit base game files (`main.gd`, `pause.gd`, etc.)
❌ **DO NOT** edit other mods' files
❌ **DO NOT** edit game resources (weapons, items, challenges, etc.)
❌ **DO NOT** track `.pck`, `.exe`, `.import`, `.tscn` files

### Why This Matters:
- This is a **mod repository**, not the full game
- We extend/inject, never replace base game files
- Clean separation prevents accidental game file commits
- Other developers only need mod files to use/contribute

## Mod File Structure

```
mods-unpacked/Calico-ReloadUI/
├── manifest.json              # Mod metadata, version, dependencies
├── mod_main.gd                # Entry point, registers ModOptions
├── README.md                  # User documentation
├── WEAPON_ARCHITECTURE.md     # Technical reference (living doc)
├── AI_CONTEXT.md             # This file - orientation for AI agents
├── extensions/
│   ├── main_extension.gd     # Extends main.gd, injects UI
│   └── singletons/
│       └── challenge_service.gd  # Dev-only bugfix (editor mode)
└── translations/
    └── ReloadUI.csv          # Translation strings for UI

```

## What This Mod Does

**ReloadUI** displays weapon cooldown indicators for each player's weapons during Brotato runs.

### Features:
- Individual weapon icons (from `RunData.players_data[].weapons`)
- Tier-colored semi-transparent backgrounds (gray/blue/purple/red)
- Cooldown status dots (green=ready, orange=firing, yellow=cooling)
- Wave visibility management (hide during shop by default)
- 4-player multiplayer support
- ModOptions integration (4 toggleable settings)

### How It Works:
1. **Extension Pattern**: Extends `res://main.gd` via ModLoader
2. **UI Injection**: Adds displays to `LifeContainerP1-P4` nodes
3. **Update Loop**: 60 FPS via `_physics_process()` for smooth cooldowns
4. **Data Matching**: Bridges `Weapon Node2D` (runtime) ↔ `WeaponData` (icons) via cache

## Development Guidelines

### File Modification Rules:
✅ **ALLOWED**:
- Any file in `mods-unpacked/Calico-ReloadUI/`
- `.gitignore` (root level, already whitelisted)

❌ **FORBIDDEN**:
- Base game scripts (they live in repo root but aren't tracked)
- Other mods in `mods-unpacked/`
- Compiled files (`.pck`, `.gdc`)
- Scene files (`.tscn`)
- Import metadata (`.import`)

### Code Modification Pattern:
```gdscript
# ❌ WRONG - Don't overwrite base game files
# File: res://main.gd (DO NOT EDIT DIRECTLY)

# ✅ CORRECT - Extend via ModLoader
# File: mods-unpacked/Calico-ReloadUI/extensions/main_extension.gd
extends "res://main.gd"

func _enter_tree() -> void:
    call_deferred("_inject_reload_ui")
```

### When Adding Features:
1. **Check scope**: Does it fit ReloadUI's purpose? (weapon cooldown display)
2. **Use extensions**: Never modify base game files
3. **Document patterns**: Update `WEAPON_ARCHITECTURE.md` with discoveries
4. **Test multiplayer**: Always verify 4-player scenarios
5. **Commit only mod files**: Verify with `git status` before pushing

## Key Technical References

### See `WEAPON_ARCHITECTURE.md` for:
- Weapon Node2D vs WeaponData distinction
- Icon access patterns (cache-based matching)
- Extension strategies (why main.gd works, PlayerUIElements doesn't)
- RunData architecture
- ModOptions integration patterns
- UI best practices (transparent panels, anchors, tier colors)

### Dependencies:
- **ModLoader**: Core modding framework (required)
- **Oudstand-ModOptions**: Settings UI (dependency in manifest.json)

### No Dependencies On:
- ~~DamageMeter~~ (removed, was only for reference)
- Any other mods

## Common Pitfalls for AI Agents

### ❌ Scope Violations:
```
Agent: "I'll update main.gd to add the cooldown display"
WRONG: main.gd is base game file, use extensions/main_extension.gd
```

### ❌ File Tracking:
```
Agent: "I'll commit these changes to weapons/ranged/stick.tres"
WRONG: That's a game file, not part of mod repository
```

### ❌ Testing Without Context:
```
Agent: "The UI isn't showing up, let me check main.gd"
WRONG: Check extensions/main_extension.gd (our extension)
```

### ✅ Correct Workflow:
1. Read this file + `WEAPON_ARCHITECTURE.md` for context
2. Only modify files in `mods-unpacked/Calico-ReloadUI/`
3. Test by running Brotato with mod installed
4. Commit only whitelisted files
5. Document new patterns in `WEAPON_ARCHITECTURE.md`

## Quick Start for New Agents

1. **Orientation**: Read this file first
2. **Technical Details**: Read `WEAPON_ARCHITECTURE.md`
3. **User Docs**: Read `README.md` to understand user-facing features
4. **Current State**: Check `manifest.json` for version and dependencies
5. **Code Entry**: Start at `mod_main.gd` → `extensions/main_extension.gd`

## Repository Commands

```bash
# Check what's tracked (should only be mod files)
git status

# Verify .gitignore is working
git ls-files  # Should show ONLY Calico-ReloadUI/* and .gitignore

# Before committing
git diff  # Ensure only mod files changed

# Commit pattern
git add mods-unpacked/Calico-ReloadUI/
git commit -m "feat: descriptive change in mod scope"
git push
```

## Version History

- **v1.0.0**: Initial release - Basic cooldown display
- **v1.1.0**: ModOptions integration (4 toggleable features)
- **Current**: Stable, clean scope, dev-only extensions conditional

## Contact & Links

- **Repository**: github.com/zckramer/brotato-mods
- **Mod Author**: Calico (zckramer)
- **Base Game**: Brotato (Blobfish)
- **ModLoader**: github.com/GodotModding/godot-mod-loader

---

**Remember**: This repository is a **mod**, not the game. Keep scope tight, extend don't replace, document discoveries.
