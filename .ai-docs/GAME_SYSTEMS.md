# Brotato Game Systems Documentation

**Living Document**: Update this as we discover and understand core game mechanics.

This document captures high-level observations about Brotato's internal systems, mechanics, and architecture that we encounter while developing mods. Each section should explain **how the system works**, **where it lives**, and **how to interact with it**.

---

## Table of Contents

1. [Weapon System](#weapon-system)
2. [Stats & Effects System](#stats--effects-system)
3. [Wave & Combat System](#wave--combat-system)
4. [Shop & Economy System](#shop--economy-system)
5. [Player Data & Persistence](#player-data--persistence)
6. [UI & HUD System](#ui--hud-system)
7. [Multiplayer & Player Management](#multiplayer--player-management)

---

## Weapon System

### Architecture Overview

Brotato separates weapon **data** (configuration) from weapon **instances** (runtime objects).

#### Weapon Node2D (Runtime Instance)

- **Type**: `Node2D` extending Weapon class
- **Location**: `player.current_weapons` array
- **Lifecycle**: Created when player picks up weapon, destroyed when sold/replaced
- **Key Properties**:
  - `weapon_id`: String - Base weapon identifier (e.g., "weapon_stick")
  - `tier`: int (0-3) - Rarity tier
  - `stats`: WeaponStats - **Runtime** calculated stats after all modifiers
  - `_current_cooldown`: float - Active cooldown timer (counts DOWN from max to 0)
  - `_is_shooting`: bool - True during brief firing animation
  - `player_index`: int - Which player owns this weapon (0-3)
  - `index`: int - Weapon slot in player's inventory
  - ❌ **Does NOT have**: `weapon_data`, `icon`, `name` (metadata properties)

#### WeaponData Resource (Configuration)

- **Type**: `Resource` extending ItemParentData
- **Location**: `RunData.players_data[player_index].weapons` array
- **Lifecycle**: Persists across waves, tracks weapon ownership
- **Key Properties**:
  - `my_id`: String - Unique instance ID (e.g., "weapon_stick_1")
  - `weapon_id`: String - Base weapon identifier
  - `icon`: Texture - **The icon texture lives here**
  - `name`: String - Display name
  - `tier`: int (0-3) - Rarity tier
  - `stats`: WeaponStats - **Base** stats before calculations
  - `scene`: PackedScene - Weapon scene to instantiate
  - `upgrades_into`: WeaponData - Next tier upgrade
  - `dmg_dealt_last_wave`: int - Damage tracking for stats

### The Data/Instance Gap

**Critical Pattern**: Weapon Node2D instances don't have metadata (icon, name), and WeaponData doesn't have runtime state (cooldown, shooting). Must bridge via matching:

```gdscript
# Build lookup cache
var cache = {}
for weapon_data in RunData.players_data[player_index].weapons:
    var key = "%s_t%d" % [weapon_data.weapon_id, weapon_data.tier]
    cache[key] = weapon_data

# Match runtime instance to data
for weapon_node in player.current_weapons:
    var key = "%s_t%d" % [weapon_node.weapon_id, weapon_node.tier]
    if cache.has(key):
        var weapon_data = cache[key]
        var icon = weapon_data.icon  # Now we have the icon!
        var cooldown = weapon_node._current_cooldown  # And the runtime state!
```

### Cooldown Mechanics

- Cooldown timer **counts DOWN** (not up)
- When weapon fires: `_current_cooldown` set to `stats.cooldown` (max value)
- Each frame: `_current_cooldown -= delta`
- When `_current_cooldown <= 0`: Weapon ready to fire
- `_is_shooting` briefly true during firing animation

**Progress Calculation**:

```gdscript
var progress = 1.0 - (weapon_node._current_cooldown / weapon_node.stats.cooldown)
# progress = 0.0 → just fired
# progress = 1.0 → ready to fire
```

### Weapon Creation & Lifecycle

1. Player picks up weapon in shop
2. `WeaponData` added to `RunData.players_data[player_index].weapons`
3. Game instantiates `Weapon Node2D` from `weapon_data.scene`
4. Node added to `player.current_weapons` array
5. During combat: Node updates cooldown, fires, applies damage
6. If sold: Node destroyed, WeaponData removed from RunData
7. If upgraded: Old WeaponData removed, new tier WeaponData added, Node respawned

---

## Stats & Effects System

### Stats Architecture

Stats are calculated dynamically based on base values + items + effects + weapon sets.

#### StatType Categories

Located in `global/stat_type.gd`:

- **Primary**: Max HP, Armor, Dodge, etc.
- **Damage**: Melee Damage, Ranged Damage, Elemental, etc.
- **Speed**: Speed, Attack Speed
- **Economic**: Harvesting, Pickup Range
- **Special**: Luck, Crit Chance, Lifesteal, etc.

#### Stats Calculation Flow

1. **Base Stats**: Character starting values
2. **+ Item Effects**: All equipped items apply stat modifiers
3. **+ Temporary Effects**: Buffs/debuffs from consumables, wave events
4. **+ Weapon Set Bonuses**: Synergy bonuses when holding multiple weapons of same type
5. **= Final Stats**: Used for combat calculations

### Effect System

Effects are modular stat modifiers with conditions.

#### Effect Structure

```gdscript
class Effect:
    var key: String            # Effect identifier
    var text_key: String       # Translation key for description
    var value: int             # Effect magnitude
    var stat_name: String      # Which stat to modify
    var custom_key: String     # For special effects
```

#### Effect Sources

- **Items**: Permanent effects while equipped
- **Consumables**: Temporary duration-based effects
- **Wave Modifiers**: Challenge/difficulty effects
- **Character Abilities**: Innate character bonuses

#### Effect Application

Accessed via `RunData.players_data[player_index].effects`:

```gdscript
var effects = RunData.players_data[player_index].effects  # Dictionary
for effect_key in effects:
    var effect_value = effects[effect_key]
    # Apply to stat calculations
```

---

## Wave & Combat System

### Wave Lifecycle

#### Wave States

1. **Combat Phase**: Enemies spawn, player fights
2. **Shop Phase**: Wave ends, shop opens
3. **Levelup Phase**: (if applicable) Choose level-up reward
4. **Next Wave**: Combat resumes

#### Key Signals (from EntitySpawner)

- `wave_started` - Combat begins
- `wave_ended` - All enemies defeated
- `players_spawned(players)` - Player nodes created/reset

#### Wave Management

- **Wave Number**: `RunData.current_wave` (int)
- **Difficulty Scaling**: Enemies get stronger each wave
- **Shop Availability**: Only open between waves

### Combat Mechanics

#### Damage Calculation

Base damage modified by:

- Weapon stats (melee/ranged damage)
- Character stats (strength, etc.)
- Crit chance/damage multipliers
- Enemy armor/resistances
- Effects (damage boost, lifesteal, etc.)

#### Enemy Management

**Entities** (enemies, neutrals, structures):

- Managed by `EntitySpawner` node
- Each entity emits `"died"` signal on death
- Located in `_entity_spawner.enemies` array

**Signal-Based Tracking Pattern:**

```gdscript
# Hook entity spawning in main_extension.gd
func _on_EntitySpawner_entity_spawned(entity) -> void:
    ._on_EntitySpawner_entity_spawned(entity)

    # Connect to death signal for tracking
    entity.connect("died", self, "_on_entity_died")

func _on_entity_died(entity, die_args) -> void:
    # Zero-overhead event-driven tracking
    var enemy_type = entity.enemy_id
    analytics_tracker.on_enemy_killed(enemy_type)
```

**Key Signals:**

- `entity.died(entity, args)` - Emitted when entity dies
- `EntitySpawner.entity_spawned(entity)` - New entity created
- `EntitySpawner.wave_started()` - Combat begins
- `EntitySpawner.wave_ended()` - Combat ends

**❌ Avoid Polling Entities:**
Scanning `entity_spawner.enemies` array every frame/timer is expensive. Use signals instead.

- Spawned by `EntitySpawner` node
- Managed in pools for performance
- Different types: Basic, Elite, Boss
- Drop loot on death (materials, consumables)

---

## Shop & Economy System

### Shop Lifecycle

Opens between waves, managed by shop UI.

#### Shop Contents

- **Weapons**: Filtered by available weapon types
- **Items**: Filtered by rarity, tier, bans
- **Reroll**: Costs gold, refreshes shop contents
- **Lock Items**: Prevent reroll for specific slots

#### Economy Sources

- **Gold Gained**:

  - Killing enemies (varies by enemy type)
  - Starting gold (character-dependent)
  - Gold generation items (piggy bank, etc.)
  - Harvesting (if character has harvesting stat)

- **Gold Spent**:
  - Buying weapons/items
  - Rerolling shop
  - Upgrading weapons (tier up)

#### Pricing System

- Base prices defined in ItemParentData
- Modified by character traits (e.g., discount effects)
- Tier affects price (higher tier = more expensive)

---

## Player Data & Persistence

### RunData Structure

Central game state manager at `/root/RunData` singleton.

#### Core Properties

```gdscript
RunData.players_data: Array[PlayerRunData]  # 1-4 players
RunData.current_wave: int
RunData.current_level: int
RunData.difficulty: int
```

#### PlayerRunData Structure

Each player has:

```gdscript
{
    player_index: int (0-3)
    current_character: CharacterData
    current_health: int
    current_level: int
    current_xp: float
    gold: int
    weapons: Array[WeaponData]           # Owned weapons (has icons!)
    items: Array[ItemData]               # Owned items
    selected_weapon: WeaponData          # Currently selected in shop
    banned_items: Array[String]          # Item IDs player can't get
    effects: Dictionary                  # All active effects
    active_sets: Dictionary              # Weapon set bonuses
    appearances: Array[ItemAppearanceData]  # Cosmetics
    uses_ban: bool
    remaining_ban_token: int
}
```

### Save System

Saves stored at `user://user/save_v3_0.json`.

#### Save Data Contents

- Unlocked characters
- Unlocked items/weapons
- Difficulty progress
- Statistics (runs completed, wins, etc.)
- Challenge completion
- **NOT SAVED**: Current run progress (runs are single-session)

---

## UI & HUD System

### HUD Hierarchy

```
Main (Node)
└─ UI (CanvasLayer)
   └─ HUD (Control)
      ├─ LifeContainerP1 (HBoxContainer) ← Player 1 health/UI
      ├─ LifeContainerP2 (HBoxContainer) ← Player 2 health/UI
      ├─ LifeContainerP3 (HBoxContainer) ← Player 3 health/UI
      ├─ LifeContainerP4 (HBoxContainer) ← Player 4 health/UI
      ├─ StatsContainer (VBoxContainer)   ← Top-right stats display
      ├─ WaveTimer (Control)              ← Wave countdown
      └─ ... (other HUD elements)
```

### UI Best Practices

See [WEAPON_ARCHITECTURE.md - UI Architecture section] for detailed patterns.

#### Key Principles

- Use `Control` for transparent containers, not `PanelContainer`
- Use anchors instead of `rect_size` for child sizing
- Use `ItemService.change_inventory_element_stylebox_from_tier()` for tier colors
- Update at appropriate frame rates (60 FPS for smooth animations, 10 FPS for static info)

---

## Multiplayer & Player Management

### Player Count

- **Singleplayer**: 1 player (default)
- **Local Co-op**: 2-4 players
- **No Online**: Local only

### Player Nodes

Created by `EntitySpawner`, stored in `Main._players` array.

#### Player Node Properties

```gdscript
class Player extends KinematicBody2D:
    var player_index: int (0-3)
    var current_weapons: Array  # Weapon Node2D instances
    var stats: Dictionary       # Calculated runtime stats
    var current_health: int
    var invulnerability_timer: float
```

### Player Spawning

- Signal: `EntitySpawner.players_spawned(players)`
- Fired at: Game start, wave reset
- Use to initialize player-specific UI/systems

---

## Discovered Patterns & Gotchas

### Pattern: Cache-Based Matching

When you need to connect runtime instances to data resources, build a cache:

```gdscript
var cache = {}
for data in data_array:
    var key = generate_unique_key(data)
    cache[key] = data

# Later: O(1) lookup instead of O(n) search
if cache.has(key):
    var matched_data = cache[key]
```

### Pattern: Tier-Based Styling

Always use `ItemService` for consistent tier colors:

```gdscript
var stylebox = StyleBoxFlat.new()
ItemService.change_inventory_element_stylebox_from_tier(stylebox, tier, alpha)
node.add_stylebox_override("panel", stylebox)
```

### Gotcha: Save Data Null Safety

Save data may not exist in editor mode. Always check:

```gdscript
var max_difficulty = 0
if Progress.data and "max_difficulty_beaten" in Progress.data:
    max_difficulty = Progress.data.max_difficulty_beaten
```

### Gotcha: Node Lifecycle Timing

- Use `call_deferred()` when modifying scene tree in `_enter_tree()`
- Use `onready` for node references that won't exist in `_init()`
- Check `is_instance_valid()` before accessing nodes that may be freed

---

## How to Update This Document

When you discover a new game system or pattern:

1. **Identify the System**: What mechanic/feature is it?
2. **Find the Code**: Where does it live? (scripts, resources, nodes)
3. **Document the Flow**: How does data move through the system?
4. **Add Example Code**: Show how to interact with it
5. **Note Gotchas**: What surprised you? What failed?
6. **Update Existing Sections**: If it relates to documented systems

**Keep it high-level**: Focus on **what** the system does and **how** to use it, not line-by-line code details. Save implementation details for WEAPON_ARCHITECTURE.md or code comments.

---

## References

- **Official Brotato**: https://store.steampowered.com/app/1942280/Brotato/
- **ModLoader Docs**: https://github.com/GodotModding/godot-mod-loader
- **Project Docs**:
  - AI_CONTEXT.md - Project scope and rules
  - AI_GODOT_REFERENCE.md - Godot 3.6.2 syntax
  - WEAPON_ARCHITECTURE.md - Weapon system deep-dive
  - This file - Game systems overview

---

**Last Updated**: December 11, 2025
**Contributors**: Calico (zckramer)
