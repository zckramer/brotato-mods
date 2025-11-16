# Brotato Weapon Architecture Reference

## Overview
This document contains hard-learned lessons about Brotato's weapon system, UI architecture, and mod development patterns. Update this as we discover new truths to prevent repeating dead-ends.

## Critical: Two Different Weapon Objects

### 1. Weapon Node2D (Runtime Instance)
- **Type**: `Node2D` (extends Weapon class)
- **Location**: `player.current_weapons` array
- **Purpose**: Active weapon instances in the game world
- **Properties**:
  - `weapon_id`: String - base weapon ID
  - `stats`: WeaponStats (MeleeWeaponStats/RangedWeaponStats) - RUNTIME stats after calculations
  - `current_stats`: WeaponStats - alias/same as stats
  - `tier`: int (0-3)
  - `is_cursed`: bool
  - `player_index`: int
  - `index`: int - weapon slot index
  - `effects`: Array
  - `weapon_pos`: Vector2
  - `weapon_sets`: Array
  - `_current_cooldown`: float - counts DOWN from max to 0
  - `_is_shooting`: bool
  - `sprite`: Sprite
  - `curse_particles`: Node
  - `custom_hit_sounds`: Array
  - ❌ **NO `weapon_data` property**
  - ❌ **NO `icon` property**

**CRITICAL**: 
- The `stats` property is WeaponStats (runtime calculations), NOT WeaponData!
- Weapon Node2D does NOT contain icon or WeaponData reference
- To get icon, must cross-reference with `RunData.players_data[player_index].weapons` using `weapon_id` + `tier`

### 2. WeaponData Resource (Data Definition)
- **Type**: `Resource` (extends ItemParentData)
- **Location**: `RunData.players_data[player_index].weapons` array OR `weapon_node.weapon_data`
- **Purpose**: Weapon configuration/metadata  
- **Properties**:
  - `my_id`: String - unique weapon ID (e.g. "weapon_stick_1")
  - `weapon_id`: String - base weapon ID
  - `name`: String - display name
  - `icon`: Texture - **THE ICON IS HERE**
  - `tier`: int (0-3)
  - `is_cursed`: bool
  - `value`: int - shop price
  - `scene`: PackedScene - weapon scene
  - `stats`: WeaponStats - BASE stats before calculations
  - `effects`: Array[Effect]
  - `upgrades_into`: WeaponData
  - `dmg_dealt_last_wave`: int - damage tracking

## How to Access Icon

### ❌ WRONG - Weapon Node2D doesn't have icon:
```gdscript
var weapon_node = player.current_weapons[0]  # Node2D
var icon_texture = weapon_node.icon  # DOESN'T EXIST
var icon_texture = weapon_node.weapon_data.icon  # weapon_data DOESN'T EXIST
```

### ✅ CORRECT - Must use RunData and match by weapon_id:
```gdscript
# Get Weapon Node2D from player
var weapon_node = player.current_weapons[0]  # Node2D with weapon_id, tier, etc.

# Find matching WeaponData in RunData
var weapon_data_array = RunData.players_data[player_index].weapons
for weapon_data in weapon_data_array:
    if weapon_data.weapon_id == weapon_node.weapon_id and weapon_data.tier == weapon_node.tier:
        icon_texture = weapon_data.icon  # Found it!
        break
```

### Direct access if you already have WeaponData:
```gdscript
var weapon_data = RunData.players_data[player_index].weapons[0]  # WeaponData Resource
var icon_texture = weapon_data.icon  # Direct access
```

## Common Mistakes
❌ `weapon.icon` - Weapon Node2D doesn't have icon property
❌ `weapon.weapon_data` - Weapon Node2D doesn't have weapon_data property
❌ `weapon.stats.icon` - WeaponStats doesn't have icon (it has cooldown, damage, etc.)
✅ Match `weapon_node.weapon_id` with `RunData.players_data[player_index].weapons` to find WeaponData
✅ `weapon_data.icon` - Icon is on WeaponData Resource only

## DamageMeter vs ReloadUI

### DamageMeter:
- Uses `RunData.players_data[player_index].weapons` (WeaponData objects)
- Groups by `my_id + tier`
- Accesses icon as `source.icon` (because source IS WeaponData)
- Updates at 10 FPS

### ReloadUI:
- Uses `player.current_weapons` (Weapon Node2D objects)  
- Shows individual instances (no grouping)
- Must access icon as `weapon.weapon_data.icon`
- Updates at 60 FPS (_physics_process)

## Code Fix

```gdscript
# Cache WeaponData array at class level
var _weapon_data_cache = {}  # weapon_id -> WeaponData

func _update_weapon_display(display: HBoxContainer, player: Player) -> void:
	# Build cache of WeaponData by weapon_id for fast lookups
	_weapon_data_cache.clear()
	var weapon_data_array = RunData.players_data[player.player_index].weapons
	for weapon_data in weapon_data_array:
		var key = "%s_t%d" % [weapon_data.weapon_id, weapon_data.tier]
		_weapon_data_cache[key] = weapon_data
	
	# Update panels
	for i in range(player.current_weapons.size()):
		_update_weapon_panel(display.get_child(i), player.current_weapons[i])

func _update_weapon_panel(panel: Control, weapon_node) -> void:
	var icon = panel.get_node_or_null("VBox/IconContainer/Icon")
	
	if icon and is_instance_valid(weapon_node):
		# Match weapon_node (Node2D) to weapon_data (Resource) via cache
		var key = "%s_t%d" % [weapon_node.weapon_id, weapon_node.tier]
		if _weapon_data_cache.has(key):
			var weapon_data = _weapon_data_cache[key]
			icon.texture = weapon_data.icon
```

## Extension Strategies (Lessons Learned)

### ❌ FAILED: PlayerUIElements Extension
**Attempt**: Extend `res://ui/hud/player_ui_elements.gd`
```gdscript
extends 'res://ui/hud/player_ui_elements.gd'
```

**Why it failed**: 
- PlayerUIElements is a **Reference class**, not a Node
- Extensions only apply to script instances created by the game
- PlayerUIElements instances are created internally and our extension never gets instantiated
- Result: Code runs but UI never appears

### ✅ SUCCESS: Main.gd Extension
**Approach**: Extend `res://main.gd` and inject UI during scene setup
```gdscript
extends "res://main.gd"

func _enter_tree() -> void:
	call_deferred("_inject_reload_ui")

func _inject_reload_ui() -> void:
	# Access LifeContainerP1-P4 nodes and inject custom UI
	var parent_node = get_node_or_null("UI/HUD/LifeContainerP1")
	parent_node.add_child(weapon_display)
```

**Why it works**:
- Main is a Node with full scene tree access
- Can inject UI into existing containers
- Runs once per game session
- Has access to players via `_players` array and signals

**Key Signals**:
- `_on_EntitySpawner_players_spawned(players)` - When players spawn
- `_on_EntitySpawner_wave_ended()` - Hide UI during shop/levelup
- `_on_EntitySpawner_wave_started()` - Show UI when wave starts

## UI Architecture

### Scene Tree Structure
```
Main (Node)
└─ UI (CanvasLayer)
   └─ HUD (Control)
      ├─ LifeContainerP1 (HBoxContainer) ← Inject here for Player 1
      ├─ LifeContainerP2 (HBoxContainer) ← Inject here for Player 2
      ├─ LifeContainerP3 (HBoxContainer) ← Inject here for Player 3
      └─ LifeContainerP4 (HBoxContainer) ← Inject here for Player 4
```

### UI Node Best Practices

#### Transparent Panels
❌ **PanelContainer**: Always has opaque background
✅ **Control**: No background, full transparency control

```gdscript
# DON'T: PanelContainer adds opaque background
var panel = PanelContainer.new()

# DO: Control with Panel child for semi-transparent background
var container = Control.new()
var bg = Panel.new()
bg.anchor_right = 1.0
bg.anchor_bottom = 1.0
container.add_child(bg)
```

#### Child Node Sizing
❌ **Setting rect_size**: Gets overridden by parent layout
✅ **Anchors**: Let parent control sizing

```gdscript
# DON'T: rect_size gets reset
icon.rect_size = Vector2(48, 48)

# DO: Use anchors to fill parent
icon.anchor_right = 1.0
icon.anchor_bottom = 1.0
```

### Tier Colors & Styling
Use ItemService for consistent tier-based styling:

```gdscript
var stylebox = StyleBoxFlat.new()
ItemService.change_inventory_element_stylebox_from_tier(stylebox, tier, alpha)
panel.add_stylebox_override("panel", stylebox)
```

**Tier Values**:
- 0 = Common (Gray)
- 1 = Uncommon (Blue)  
- 2 = Rare (Purple)
- 3 = Legendary (Red)

**Alpha**: 0.5 recommended for semi-transparent backgrounds (like DamageMeter)

## Performance Patterns

### Update Frequencies
- **DamageMeter**: 10 FPS (Timer.wait_time = 0.1)
- **ReloadUI**: 60 FPS (_physics_process for smooth cooldown animation)

### Weapon Panel Syncing
Only rebuild UI when weapon count changes, not every frame:

```gdscript
func _update_weapon_display(display: HBoxContainer, player: Player) -> void:
	var weapon_count = player.current_weapons.size()
	var panel_count = display.get_child_count()
	
	# Only sync when count changes
	if panel_count != weapon_count:
		_sync_panels(display, weapon_count)
	
	# Always update visuals (every frame for smooth animation)
	for i in range(weapon_count):
		_update_weapon_panel(display.get_child(i), player.current_weapons[i])
```

## Cooldown State Management

### Cooldown Direction
⚠️ **CRITICAL**: `_current_cooldown` counts **DOWN**, not up!

```gdscript
# Weapon fires → _current_cooldown set to max value
# Each frame → _current_cooldown decreases
# When _current_cooldown reaches 0 → weapon ready to fire again

var progress = 1.0 - (cur_cd / max_cd)  # 0.0 = just fired, 1.0 = ready
```

### State Priority
1. **READY**: `_current_cooldown <= 0`
2. **FIRING**: `_is_shooting == true` (brief flash during shot)
3. **COOLING**: `_current_cooldown > 0` (counting down)

## Debugging Tips

### Property Inspection
Use `get_property_list()` to discover object structure:

```gdscript
for prop in weapon.get_property_list():
	if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
		print("  - ", prop.name)
```

### Common Debug Patterns
```gdscript
# Check object type
print("Type: ", weapon.get_class())

# Check property existence  
print("Has property: ", "weapon_data" in weapon)

# Validate references
print("Is valid: ", is_instance_valid(weapon.weapon_data))
```

## Known Gotchas

### Old .pck Files
If changes don't appear, check for old exported `.pck` files in `_EXPORT/` that may be loading instead of source files.

### GDScript Limitations
- No function-level `static var` - use class variables instead
- Reference classes can't be extended effectively
- `call_deferred()` needed for scene tree modifications during `_enter_tree()`

### Multiplayer Support
Always create UI for 4 players even if fewer are active:
```gdscript
for i in range(4):  # Not RunData.get_player_count()!
	var display = create_weapon_display()
	_weapon_displays.append(display)
```

Then control visibility based on actual player count.

## RunData Architecture (Critical Reference)

### Players Data Structure
```gdscript
RunData.players_data: Array[PlayerRunData]  # Size = player count (1-4)
```

Each `PlayerRunData` contains:
- `current_character`: CharacterData
- `current_health`: int
- `current_level`: int
- `current_xp`: float
- `gold`: int
- `weapons`: Array[WeaponData] - **THE ICONS ARE HERE**
- `items`: Array[ItemData]
- `selected_weapon`: WeaponData
- `banned_items`: Array[String]
- `effects`: Dictionary - all active effects
- `active_sets`: Dictionary - weapon sets bonuses
- `appearances`: Array[ItemAppearanceData]
- `player_index`: int (0-3)
- `uses_ban`: bool
- `remaining_ban_token`: int

### Weapon Data Access Patterns

**For UI Display (Icons, Names, Metadata)**:
```gdscript
# Access WeaponData from RunData (has icon)
var weapon_data_array = RunData.players_data[player_index].weapons  # Array[WeaponData]
var weapon_data = weapon_data_array[0]  # WeaponData Resource
var icon = weapon_data.icon  # Texture
var name = weapon_data.name  # String
var tier = weapon_data.tier  # int (0-3)
```

**For Runtime State (Cooldowns, Shooting)**:
```gdscript
# Access Weapon Node2D from player
var weapon_node = player.current_weapons[0]  # Node2D
var cooldown = weapon_node._current_cooldown  # float
var is_shooting = weapon_node._is_shooting  # bool
var weapon_id = weapon_node.weapon_id  # String
```

**Matching Node2D to WeaponData**:
```gdscript
# Build cache for O(1) lookups
var cache = {}
for weapon_data in RunData.players_data[player_index].weapons:
	var key = "%s_t%d" % [weapon_data.weapon_id, weapon_data.tier]
	cache[key] = weapon_data

# Match at runtime
for weapon_node in player.current_weapons:
	var key = "%s_t%d" % [weapon_node.weapon_id, weapon_node.tier]
	if cache.has(key):
		var weapon_data = cache[key]
		icon.texture = weapon_data.icon  # Now we have the icon!
```

### Why This Matters
- **Weapon Node2D**: Lives in game world, has position/sprite/physics, NO icon/name metadata
- **WeaponData**: Lives in RunData, has icon/name/value/effects, NO position/cooldown
- **The Gap**: Must bridge via `weapon_id` + `tier` matching
- **Performance**: Cache WeaponData lookups per frame (60 FPS updates)

### RunData Key Functions
```gdscript
RunData.get_player_count() -> int  # 1-4 players
RunData.get_player_weapons(player_index) -> Array  # Returns .duplicate() of weapons
RunData.get_player_items(player_index) -> Array  # Returns .duplicate() of items
RunData.get_player_effects(player_index) -> Dictionary  # Effects dict reference
RunData.get_player_character(player_index) -> CharacterData
RunData.get_player_gold(player_index) -> int
```

**CRITICAL**: `get_player_weapons()` returns `.duplicate()` - use `RunData.players_data[idx].weapons` for direct reference when building cache.

### Player Access Patterns
```gdscript
# From Main.gd (our extension)
_players: Array  # Array of Player Node2D instances

# Each Player has:
player.current_weapons: Array  # Array of Weapon Node2D instances (runtime)
player.player_index: int  # 0-3, matches RunData.players_data index
player.stats: Dictionary  # Runtime calculated stats

# Bridge pattern:
var weapon_nodes = _players[i].current_weapons  # Node2D instances
var weapon_datas = RunData.players_data[i].weapons  # WeaponData resources
# Match by weapon_id + tier
```

### Cache Invalidation
Rebuild WeaponData cache when:
- Player acquires new weapon
- Player removes weapon
- Weapon upgrades (tier changes)
- Wave transitions (weapons may change)

Safe to cache per `_physics_process()` frame - weapons don't change mid-wave.
