# AI Assistant Documentation Index

**READ THIS FIRST** when starting work on the ReloadUI mod.

## 📚 Documentation Structure

This project has **6 AI documentation files**, each serving a specific purpose:

### 1. **AI_CONTEXT.md** (This File)

- **Purpose**: Quick orientation, scope boundaries, workflows
- **When to read**: Every session start (use check-in prompt below)
- **Contents**: Repository scope, file structure, development rules

### 2. **AI_GODOT_REFERENCE.md**

- **Purpose**: Godot 3.6.2 & GDScript syntax reference
- **When to read**: When writing code, checking APIs, syntax questions
- **Contents**: Complete GDScript language guide, node system, common patterns
- **⚠️ CRITICAL**: This project uses Godot 3.6.2, NOT 4.x!

### 3. **GAME_SYSTEMS.md** ⭐

- **Purpose**: High-level Brotato game mechanics documentation (living document)
- **When to read**: Working with ANY game system (stats, waves, shop, economy, etc.)
- **Contents**: How core game systems work, where they live, how to interact with them
- **Update this**: When discovering new game mechanics, patterns, or system behaviors

### 4. **WEAPON_ARCHITECTURE.md**

- **Purpose**: Brotato weapon system deep-dive (living document)
- **When to read**: Working with weapons, cooldowns, icons, RunData
- **Contents**: Weapon Node2D vs WeaponData, icon access, extension strategies, performance patterns
- **Update this**: When discovering new weapon-specific patterns or architectural details

### 5. **THIRD_PARTY_ANALYSIS_WORKFLOW.md** ⭐ NEW

- **Purpose**: Process for analyzing other developers' mods (READ-ONLY)
- **When to read**: Before importing or studying third-party mods
- **Contents**: Analysis workflow, documentation templates, learning patterns, attribution rules
- **⚠️ CRITICAL**: NEVER modify third-party code, only analyze and document learnings

### 6. **README.md**

- **Purpose**: User-facing documentation
- **When to read**: Understanding features from user perspective
- **Contents**: Installation, features, settings, compatibility

---

## 🚀 Session Check-In Prompt

**Copy-paste this at the start of each session:**

```
I'm starting work on the ReloadUI mod for Brotato. Please confirm you've reviewed:

1. AI_CONTEXT.md - Repository scope and development rules
2. AI_GODOT_REFERENCE.md - Godot 3.6.2 syntax (NOT 4.x)
3. GAME_SYSTEMS.md - Core game mechanics and systems
4. WEAPON_ARCHITECTURE.md - Weapon system deep-dive

Key reminders:
- This repo ONLY tracks mods-unpacked/Calico-ReloadUI/ (never edit base game files)
- Use Godot 3.6.2 docs (https://docs.godotengine.org/en/3.6/)
- Test via Godot editor (F5), not Steam launch
- Weapon Node2D has NO icon property - must match with RunData WeaponData

Please summarize what this mod does and confirm you understand the scope boundaries.
```

**Expected assistant response should include:**

- ✅ Mod purpose: Weapon cooldown/reload UI display
- ✅ Scope: Only modify files in `mods-unpacked/Calico-ReloadUI/`
- ✅ Godot version: 3.6.2 (not 4.x)
- ✅ Testing: Launch via Godot editor (F5), not Steam
- ✅ Architecture: Weapon Node2D vs WeaponData distinction

---

## 📂 Repository Scope - CRITICAL

**This repository ONLY tracks the ReloadUI mod itself.**

### ✅ Allowed Files (`.gitignore` whitelist):

```
mods-unpacked/Calico-ReloadUI/
mods-unpacked/Calico-ReloadUI/**
.gitignore
```

### ❌ Forbidden Modifications:

- **DO NOT** modify any files outside `mods-unpacked/Calico-ReloadUI/`
- **DO NOT** edit base game files (`main.gd`, `pause.gd`, etc.)
- **DO NOT** edit other mods' files
- **DO NOT** edit game resources (weapons, items, challenges, etc.)
- **DO NOT** track `.pck`, `.exe`, `.import`, `.tscn` files

### Why This Matters:

- This is a **mod repository**, not the full game
- We extend/inject, never replace base game files
- Clean separation prevents accidental game file commits
- Other developers only need mod files to use/contribute

---

## 📂 Mod File Structure

```
mods-unpacked/Calico-ReloadUI/
├── manifest.json                      # Mod metadata, version, dependencies
├── mod_main.gd                        # Entry point, registers ModOptions
├── README.md                          # User documentation
├── AI_CONTEXT.md                      # THIS FILE - Quick orientation & check-in
├── AI_CHECKIN_PROMPT.md               # Quick session start reference
├── AI_GODOT_REFERENCE.md              # Godot 3.6.2 & GDScript complete reference
├── GAME_SYSTEMS.md                    # Core game mechanics documentation (living doc)
├── WEAPON_ARCHITECTURE.md             # Brotato weapon system deep-dive (living doc)
├── THIRD_PARTY_ANALYSIS_WORKFLOW.md   # Process for analyzing other mods (READ-ONLY)
├── ANALYSIS_*.md                      # Third-party mod analysis documents (optional)
├── extensions/
│   ├── main_extension.gd              # Extends main.gd, injects UI
│   └── singletons/
│       └── challenge_service.gd       # Dev-only bugfix (editor mode)
└── translations/
    └── ReloadUI.csv                   # Translation strings for UI
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
3. **Check game systems**: Review `GAME_SYSTEMS.md` for relevant mechanics
4. **Document patterns**: Update `WEAPON_ARCHITECTURE.md` or `GAME_SYSTEMS.md` with discoveries
5. **Test multiplayer**: Always verify 4-player scenarios
6. **Commit only mod files**: Verify with `git status` before pushing

---

## 🔍 Where to Find Information

### Code Syntax & APIs

→ **AI_GODOT_REFERENCE.md** - Complete Godot 3.6.2 & GDScript reference

- Variable declarations, functions, control flow
- Signals, node access, lifecycle methods
- UI nodes (Control, TextureRect, Containers)
- Memory management, exports, coroutines
- **ALWAYS** use Godot 3.6 docs: https://docs.godotengine.org/en/3.6/

### Game Mechanics & Systems

→ **GAME_SYSTEMS.md** - Core game mechanics documentation (NEW!)

- Weapon system overview
- Stats & effects system
- Wave & combat system
- Shop & economy mechanics
- Player data & persistence
- UI & HUD architecture
- Multiplayer & player management
- **UPDATE THIS** when discovering new game mechanics

### Weapon System Deep-Dive

→ **WEAPON_ARCHITECTURE.md** - Weapon-specific technical details

- Weapon Node2D vs WeaponData distinction (CRITICAL)
- Icon access patterns (cache-based matching)
- Extension strategies (why main.gd works, PlayerUIElements doesn't)
- RunData architecture
- ModOptions integration patterns
- UI best practices (transparent panels, anchors, tier colors)
- **UPDATE THIS** when discovering new patterns

### User Features & Settings

→ **README.md** - User-facing documentation

- Installation instructions
- Feature descriptions
- ModOptions settings
- Compatibility notes

### Quick Scope Check

→ **This file (AI_CONTEXT.md)** - Boundaries and workflows

- What files can be modified
- Git commands
- Development guidelines
- Common pitfalls

---

## 🎯 What This Mod Does

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

### Dependencies:

- **ModLoader**: Core modding framework (required)
- **Oudstand-ModOptions**: Settings UI (dependency in manifest.json)

---

## ⚠️ Critical Technical Points

### 1. Godot Version

- **Uses**: Godot 3.6.2 (Steam version: 3.6.1.stable.custom_build)
- **NOT**: Godot 4.x (syntax differs significantly)
- **Docs**: https://docs.godotengine.org/en/3.6/

### 2. Weapon Icons Are NOT on Weapon Node2D

```gdscript
❌ var icon = weapon_node.icon  # DOESN'T EXIST
❌ var icon = weapon_node.weapon_data.icon  # weapon_data DOESN'T EXIST
✅ # Must match via RunData using weapon_id + tier (see WEAPON_ARCHITECTURE.md)
```

### 3. Testing Requires Godot Editor

```
Steam Launch → Uses Steam profile → Loads from Workshop/packed mods (WRONG)
Editor Launch (F5) → Uses editor profile → Loads from mods-unpacked/ (CORRECT)
```

### 4. Extension Pattern

```gdscript
# ❌ WRONG - Don't overwrite base game files
# File: res://main.gd (DO NOT EDIT DIRECTLY)

# ✅ CORRECT - Extend via ModLoader
# File: mods-unpacked/Calico-ReloadUI/extensions/main_extension.gd
extends "res://main.gd"

func _enter_tree() -> void:
    call_deferred("_inject_reload_ui")
```

---

## ⚠️ Common Pitfalls for AI Agents

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

### ❌ Wrong Godot Version:

```
Agent: "I'll use await instead of yield"
WRONG: await is Godot 4.x, use yield (Godot 3.6)
```

### ❌ Testing Without Context:

```
Agent: "The UI isn't showing up, let me check main.gd"
WRONG: Check extensions/main_extension.gd (our extension)
```

### ❌ Icon Access:

```
Agent: "I'll get the icon from weapon.icon"
WRONG: Weapon Node2D has no icon, must use RunData matching
```

### ✅ Correct Workflow:

1. **Start session**: Use check-in prompt (top of this file)
2. **Read context**: AI_CONTEXT.md (this file) + AI_GODOT_REFERENCE.md
3. **Check architecture**: WEAPON_ARCHITECTURE.md for weapon-specific work
4. **Write code**: Only modify files in `mods-unpacked/Calico-ReloadUI/`
5. **Test**: Launch via Godot editor (F5), not Steam
6. **Verify**: `git status` before committing
7. **Document**: Update WEAPON_ARCHITECTURE.md with new discoveries

---

## 🛠️ Development Guidelines

### File Modification Rules:

✅ **ALLOWED**:

- Any file in `mods-unpacked/Calico-ReloadUI/`
- `.gitignore` (root level, already whitelisted)
- Documentation files (this one, WEAPON_ARCHITECTURE.md, README.md)

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
3. **Check Godot version**: Use 3.6 docs, not 4.x
4. **Document patterns**: Update `WEAPON_ARCHITECTURE.md` with discoveries
5. **Test in editor**: Press F5 in Godot, don't launch via Steam
6. **Commit only mod files**: Verify with `git status` before pushing

---

## 📝 Repository Commands

```powershell
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

---

## 📜 Version History

- **v1.0.0**: Initial release - Basic cooldown display
- **v1.0.1**: Bug fixes, null safety
- **v1.0.2**: Performance improvements
- **v1.0.3**: ModOptions integration prep
- **v1.0.4**: ModOptions integration (4 toggleable features)
- **Current (v1.0.4)**: Stable, clean scope, comprehensive AI documentation

---

## 🔗 Links & Contact

- **Repository**: https://github.com/zckramer/brotato-mods
- **Mod Author**: Calico (zckramer)
- **Base Game**: Brotato by Blobfish (https://store.steampowered.com/app/1942280/Brotato/)
- **ModLoader**: https://github.com/GodotModding/godot-mod-loader
- **Godot 3.6 Docs**: https://docs.godotengine.org/en/3.6/

---

## 🎯 Quick Checklist Before Coding

- [ ] Used check-in prompt at session start
- [ ] Confirmed Godot 3.6.2 (not 4.x)
- [ ] Reviewed AI_GODOT_REFERENCE.md for syntax
- [ ] Checked WEAPON_ARCHITECTURE.md for weapon patterns
- [ ] Will only modify files in `mods-unpacked/Calico-ReloadUI/`
- [ ] Will test via Godot editor (F5), not Steam
- [ ] Will document new discoveries in WEAPON_ARCHITECTURE.md

---

**Remember**: This repository is a **mod**, not the game. Keep scope tight, extend don't replace, document discoveries, always use Godot 3.6.2 syntax.
