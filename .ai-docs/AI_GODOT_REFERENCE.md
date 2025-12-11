# AI Assistant Reference: Godot 3.6.2 & GDScript for Brotato Modding

## Critical Information for AI Assistants

**ALWAYS refer to the official Godot 3.6.2 documentation when working on this project:**

- **Official Docs**: https://docs.godotengine.org/en/3.6/
- **GDScript Basics**: https://docs.godotengine.org/en/3.6/tutorials/scripting/gdscript/gdscript_basics.html
- **Class Reference**: https://docs.godotengine.org/en/3.6/classes/index.html

This project uses **Godot 3.6.2** (NOT Godot 4.x). Syntax, APIs, and features differ significantly between versions.

---

## Project Context

### What This Project Is

- **Game**: Brotato (commercial roguelike game by Blobfish)
- **Mod**: ReloadUI - Weapon cooldown/reload display mod
- **Engine**: Godot 3.6.2 (Steam uses v3.6.1.stable.custom_build)
- **Language**: GDScript (Python-like scripting language for Godot)
- **Mod Framework**: Brotato ModLoader with extension system

### Directory Structure

```
mods-unpacked/Calico-ReloadUI/
├── manifest.json          # Mod metadata
├── mod_main.gd           # Entry point (extends Node)
├── extensions/           # Script extensions (patches base game files)
│   ├── main_extension.gd         # Extends main.gd (UI injection)
│   └── singletons/
│       └── challenge_service.gd  # Extends ChallengeService.gd
├── translations/         # i18n files
└── AI_CONTEXT.md        # Project documentation
```

---

## GDScript Language Reference (Godot 3.6.2)

### 1. Basic Syntax

#### Variables

```gdscript
# Untyped (dynamic)
var health = 100
var name = "Player"
var items = []

# Typed (static) - ALWAYS preferred for clarity
var health: int = 100
var name: String = "Player"
var items: Array = []

# Type inference with := operator
var speed := 5.0  # Inferred as float
var node := get_node("Player")  # Inferred as Node

# Constants
const MAX_HEALTH = 100
const PLAYER_SPEED: float = 5.0

# Enums
enum Tier {COMMON, UNCOMMON, RARE, LEGENDARY}
enum {TILE_BRICK, TILE_FLOOR, TILE_SPIKE}
```

#### Functions

```gdscript
# Basic function
func take_damage(amount):
    health -= amount

# Typed parameters and return value
func calculate_damage(base: int, multiplier: float) -> int:
    return int(base * multiplier)

# Optional parameters with defaults
func spawn_enemy(type: String = "basic", level: int = 1):
    pass

# Void function (no return value)
func print_message(msg: String) -> void:
    print(msg)
    # Can use 'return' without value to exit early
```

#### Static Functions

```gdscript
# No access to instance variables or self
static func add(a: int, b: int) -> int:
    return a + b

# Call static functions without instance
var result = MyClass.add(5, 3)
```

### 2. Control Flow

#### Signals (Events) - ALWAYS Prefer Over Polling

**Signals are Godot's event system - use them for performance.**

```gdscript
# Define signal
signal entity_died(entity, args)
signal wave_completed()

# Emit signal
emit_signal("entity_died", self, die_args)

# Connect to signal (target, method_name)
entity.connect("died", self, "_on_entity_died")

# Disconnect
if entity.is_connected("died", self, "_on_entity_died"):
    entity.disconnect("died", self, "_on_entity_died")

# Check if connected
if not signal_source.is_connected("signal_name", target, "method_name"):
    signal_source.connect("signal_name", target, "method_name")
```

**✅ Signal-Based Pattern (BEST PRACTICE - Zero Overhead)**:

```gdscript
# Extension pattern: Hook into game events
extends "res://main.gd"

func _on_EntitySpawner_entity_spawned(entity) -> void:
    ._on_EntitySpawner_entity_spawned(entity)

    # Connect to entity death signal
    if not entity.is_connected("died", self, "_on_entity_died"):
        entity.connect("died", self, "_on_entity_died")

func _on_entity_died(entity, die_args) -> void:
    # React to death event - Code ONLY runs when entity dies
    process_entity_death(entity)
```

**❌ Polling Pattern (AVOID - Expensive CPU Cost)**:

```gdscript
# BAD: Constantly checking state with Timer
var _poll_timer: Timer
func _ready():
    _poll_timer = Timer.new()
    _poll_timer.wait_time = 0.5
    _poll_timer.connect("timeout", self, "_poll_entities")
    add_child(_poll_timer)

func _poll_entities():
    # Runs every 0.5s even when nothing happens
    for entity in get_all_entities():  # Scans 100+ entities repeatedly
        if entity_is_dead(entity):
            process_death()  # Wasteful check
```

**Performance Comparison:**

- **Signals**: O(1) per event - Runs ONLY when event fires
- **Polling**: O(N × frequency) - Runs constantly, scans all objects
- **Example**: 100 enemies, 0.5s polling = 200 checks/second
- **vs Signals**: 100 total calls (one per actual death)

**When to Use Each:**

- **Signals**: Entity deaths, spawns, state changes (✅ Always prefer)
- **Polling**: External APIs, file watching (only when signals unavailable)

#### If/Else/Elif

```gdscript
if health <= 0:
    die()
elif health < 20:
    play_low_health_sound()
else:
    continue_playing()

# Ternary operator
var status = "alive" if health > 0 else "dead"

# Checking membership with 'in'
if "fire" in element_types:
    deal_fire_damage()

if weapon in player.inventory:
    equip(weapon)
```

#### Loops

```gdscript
# For loop - iterate array
for item in inventory:
    print(item.name)

# For loop - iterate dictionary
var stats = {"str": 10, "dex": 15}
for stat_name in stats:
    print(stat_name + ": " + str(stats[stat_name]))

# For loop - range
for i in range(5):  # 0, 1, 2, 3, 4
    print(i)

for i in range(2, 10, 2):  # 2, 4, 6, 8
    print(i)

# While loop
while enemies_alive > 0:
    fight()

# Break and continue
for i in range(10):
    if i == 5:
        break  # Exit loop
    if i % 2 == 0:
        continue  # Skip to next iteration
    print(i)
```

#### Match Statement (like switch)

```gdscript
match weapon_type:
    "sword":
        print("Melee weapon")
    "bow":
        print("Ranged weapon")
    "staff":
        print("Magic weapon")
    _:  # Default case (wildcard)
        print("Unknown weapon")

# Pattern matching with variables
match value:
    1:
        print("One")
    2, 3:  # Multiple patterns
        print("Two or three")
    var x:  # Binding pattern
        print("Something else: ", x)

# Array pattern matching
match input:
    [1, 2]:
        print("Exactly [1, 2]")
    [var first, var second]:
        print("Two elements: ", first, ", ", second)
    [42, ..]:  # Open-ended array
        print("Starts with 42")
```

### 3. Classes and Inheritance

#### Class Structure

```gdscript
# Every .gd file is implicitly a class
extends Node  # Inherit from Node

# Optional: Give class a name (registers in editor)
class_name WeaponDisplay

# Member variables
var health: int = 100
var _private_var: int = 0  # Convention: _ prefix for private

# Constants
const MAX_AMMO: int = 30

# Signals (custom events)
signal health_changed(old_value, new_value)
signal died

# Called when node enters scene tree
func _ready():
    print("Ready!")

# Called every frame (delta = time since last frame)
func _process(delta: float):
    pass

# Called every physics frame (fixed timestep)
func _physics_process(delta: float):
    pass
```

#### Inheritance

```gdscript
# Inherit from built-in class
extends Control

# Inherit from custom class file
extends "res://scripts/base_enemy.gd"

# Call parent class method
func _ready():
    ._ready()  # Call parent's _ready()
    print("Child ready")

# Check inheritance
if player is KinematicBody2D:
    player.move()
```

#### Inner Classes

```gdscript
extends Node

class WeaponData:
    var damage: int
    var cooldown: float

    func _init(dmg: int, cd: float):
        damage = dmg
        cooldown = cd

func _ready():
    var sword = WeaponData.new(10, 1.5)
    print(sword.damage)
```

### 4. Signals (Event System)

```gdscript
# Define signal
signal player_died
signal health_changed(old_value, new_value)

# Emit signal
func take_damage(amount: int):
    var old_health = health
    health -= amount
    emit_signal("health_changed", old_health, health)

    if health <= 0:
        emit_signal("player_died")

# Connect signal to method (in _ready or similar)
func _ready():
    $Player.connect("died", self, "_on_Player_died")
    $Enemy.connect("spotted_player", self, "_on_Enemy_spotted_player", [enemy_id])

# Signal handler
func _on_Player_died():
    game_over()

func _on_Enemy_spotted_player(enemy_id: int):
    alert_guards(enemy_id)
```

### 5. Node Access

```gdscript
# Get child node by name
var sprite = get_node("Sprite")
var sprite = $Sprite  # Shorthand (compile-time only)
var sprite = $"Sprite With Spaces"

# Get node by path
var player = get_node("/root/Main/Player")
var hud = get_node("../HUD")

# Get parent
var parent = get_parent()

# Get children
var children = get_children()
for child in children:
    print(child.name)

# Find node by name (searches children recursively)
var label = find_node("HealthLabel", true, false)

# Check if node has a child
if has_node("Weapon"):
    var weapon = get_node("Weapon")

# Get tree root
var root = get_tree().get_root()
```

### 6. Common Built-in Types

#### Vector2 (2D coordinates)

```gdscript
var pos = Vector2(10, 20)
var velocity = Vector2(5.0, 0.0)

# Access components
print(pos.x)  # 10
print(pos.y)  # 20

# Common operations
var length = velocity.length()
var normalized = velocity.normalized()
var distance = pos.distance_to(Vector2(0, 0))
```

#### Color

```gdscript
var red = Color(1.0, 0.0, 0.0)  # RGB
var blue = Color(0.0, 0.0, 1.0, 0.5)  # RGBA with alpha
var green = Color.green  # Named colors

# Access components
print(red.r, red.g, red.b, red.a)
```

#### Array

```gdscript
var items = []
var items: Array = []  # Typed

# Add elements
items.append("sword")
items.push_back("shield")  # Same as append
items.insert(1, "potion")  # Insert at index

# Access
var first = items[0]
var last = items[-1]  # Negative index from end
var size = items.size()

# Remove
items.erase("sword")  # Remove by value
items.remove(0)  # Remove by index
items.pop_back()  # Remove last
items.clear()  # Remove all

# Iteration
for item in items:
    print(item)

for i in range(items.size()):
    print(i, items[i])
```

#### Dictionary

```gdscript
var stats = {}
var stats: Dictionary = {}  # Typed

# Add/modify entries
stats["health"] = 100
stats["mana"] = 50

# Lua-style syntax
var player_data = {
    name = "Hero",
    level = 5,
    health = 100
}

# Access
var hp = stats["health"]
var hp = stats.get("health", 0)  # With default

# Check key existence
if "mana" in stats:
    print(stats["mana"])

if stats.has("strength"):
    print("Has strength")

# Iteration
for key in stats:
    print(key, " = ", stats[key])

# Keys and values
var keys = stats.keys()
var values = stats.values()
```

### 7. Memory Management

```gdscript
# Most classes inherit Reference (auto memory management)
var obj = Reference.new()  # Freed when no references

# Node classes require manual free
var node = Node.new()
node.queue_free()  # Deferred deletion (safe)
# node.free()  # Immediate deletion (use with caution)

# Weak references (don't prevent garbage collection)
var weak_ref = weakref(node)
var node_again = weak_ref.get_ref()
if node_again:
    print("Node still exists")

# Check if object is valid
if is_instance_valid(node):
    node.process()
```

### 8. Exports (Editor Properties)

```gdscript
extends Node

# Expose variable to editor
export var speed = 10
export var health: int = 100

# With type hints
export(int) var damage = 5
export(float, 0.0, 1.0) var opacity = 1.0
export(String, "Fire", "Ice", "Lightning") var element = "Fire"

# Node path
export(NodePath) var target_path
export(PackedScene) var enemy_scene

# Resource
export(Texture) var icon
export(AudioStream) var sound_effect

# Color picker
export(Color) var tint = Color.white

# Access exported NodePath
onready var target = get_node(target_path)
```

### 9. Onready Keyword

```gdscript
extends Node

# Variable initialized when node enters tree (_ready called)
onready var sprite = $Sprite
onready var health_label = get_node("UI/HealthLabel")

# Equivalent to:
var sprite
var health_label

func _ready():
    sprite = $Sprite
    health_label = get_node("UI/HealthLabel")
```

### 10. Tool Mode

```gdscript
tool  # Must be first line
extends EditorPlugin

# Script runs in editor (not just at runtime)
func _ready():
    if Engine.editor_hint:  # Check if in editor
        print("Running in editor")
    else:
        print("Running in game")
```

### 11. Yield (Coroutines)

```gdscript
# Wait for signal
func attack():
    print("Attacking...")
    yield(get_tree().create_timer(1.0), "timeout")
    print("Attack finished!")

# Wait for next frame
func process_data():
    print("Start processing")
    yield(get_tree(), "idle_frame")
    print("Next frame")

# Wait for animation
func play_death_animation():
    $AnimationPlayer.play("death")
    yield($AnimationPlayer, "animation_finished")
    queue_free()

# Call coroutine
func _ready():
    attack()  # Starts but doesn't wait
    yield(attack(), "completed")  # Wait for completion
```

---

## Common Godot Nodes for UI

### Control Nodes (UI Base)

#### Control (Base Class)

```gdscript
var control = Control.new()

# Anchors (0.0 to 1.0, relative to parent)
control.anchor_left = 0.0
control.anchor_top = 0.0
control.anchor_right = 1.0
control.anchor_bottom = 1.0

# Margins (pixels from anchor position)
control.margin_left = 10
control.margin_top = 10
control.margin_right = -10
control.margin_bottom = -10

# Size and position
control.rect_position = Vector2(100, 50)
control.rect_size = Vector2(200, 100)
control.rect_min_size = Vector2(50, 50)

# Visibility
control.visible = true
control.modulate = Color(1, 1, 1, 0.5)  # Semi-transparent
```

#### TextureRect (Display Images)

```gdscript
var texture_rect = TextureRect.new()
texture_rect.texture = preload("res://icon.png")

# Stretch modes
texture_rect.expand = true
texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
# STRETCH_SCALE, STRETCH_TILE, STRETCH_KEEP, etc.
```

#### Label (Display Text)

```gdscript
var label = Label.new()
label.text = "Hello World"
label.align = Label.ALIGN_CENTER
label.valign = Label.VALIGN_CENTER
```

#### Panel (Background Container)

```gdscript
var panel = Panel.new()
# Appearance controlled by Theme/StyleBox
```

### Container Nodes (Layout)

#### HBoxContainer (Horizontal Layout)

```gdscript
var hbox = HBoxContainer.new()
hbox.add_child(Label.new())
hbox.add_child(TextureRect.new())
# Children arranged left-to-right

# Separation between children
hbox.add_constant_override("separation", 10)
```

#### VBoxContainer (Vertical Layout)

```gdscript
var vbox = VBoxContainer.new()
vbox.add_child(Label.new())
vbox.add_child(Button.new())
# Children arranged top-to-bottom
```

#### MarginContainer (Padding)

```gdscript
var margin = MarginContainer.new()
margin.add_constant_override("margin_left", 10)
margin.add_constant_override("margin_top", 10)
margin.add_constant_override("margin_right", 10)
margin.add_constant_override("margin_bottom", 10)
```

---

## Node Lifecycle Methods

```gdscript
extends Node

# Called when node is initialized (constructor)
func _init():
    print("Constructor")

# Called when node enters scene tree
func _ready():
    print("Ready - node is in tree")

# Called when node is about to be removed
func _exit_tree():
    print("Exiting tree")

# Called when node enters tree (before _ready, can be called multiple times)
func _enter_tree():
    print("Entered tree")

# Called every frame (variable timestep)
func _process(delta: float):
    pass

# Called every physics frame (fixed timestep, default 60 FPS)
func _physics_process(delta: float):
    pass

# Called when receiving input events
func _input(event: InputEvent):
    if event is InputEventKey:
        print("Key pressed")

func _unhandled_input(event: InputEvent):
    # Only called if input wasn't handled by UI
    pass
```

---

## Brotato ModLoader Extension Pattern

### How Extensions Work

Extensions **patch** base game scripts by injecting code at specific points.

```gdscript
# extensions/main_extension.gd
extends "res://main.gd"  # Extend base game script

# Called when node enters tree
func _enter_tree():
    # YOUR CODE HERE - runs before base game's _enter_tree
    print("Extension loaded!")

# Override base game method
func _ready():
    ._ready()  # Call original implementation
    # YOUR CODE HERE - runs after base game's _ready
    inject_custom_ui()

# Add new methods
func inject_custom_ui():
    var custom_ui = preload("res://mods-unpacked/MyMod/ui/custom_panel.tscn").instance()
    $UI.add_child(custom_ui)
```

### Installation Pattern (mod_main.gd)

```gdscript
extends Node

const MOD_DIR = "res://mods-unpacked/Calico-ReloadUI/"

func _init():
    # Install extensions
    ModLoaderMod.install_script_extension(MOD_DIR + "extensions/main_extension.gd")

    # Conditional loading (editor-only features)
    if OS.has_feature("editor"):
        ModLoaderMod.install_script_extension(MOD_DIR + "extensions/singletons/challenge_service.gd")

func _ready():
    # Register mod options, etc.
    pass
```

---

## Critical Godot 3.6 vs 4.x Differences

| Feature           | Godot 3.6                                        | Godot 4.x                                    |
| ----------------- | ------------------------------------------------ | -------------------------------------------- |
| **get_node()**    | `$NodeName`                                      | Same                                         |
| **Node children** | `get_children()`                                 | Same                                         |
| **Timer**         | `yield(get_tree().create_timer(1.0), "timeout")` | `await get_tree().create_timer(1.0).timeout` |
| **Signals**       | `connect("signal", self, "method")`              | `signal.connect(method)`                     |
| **Async**         | `yield(...)`                                     | `await ...`                                  |
| **Type suffix**   | `int`, `float`                                   | Same                                         |
| **Preload**       | `preload("res://...")`                           | Same                                         |

**ALWAYS check version 3.6 docs when unsure!**

---

## Testing Workflow (CRITICAL)

### Launch Methods

```
Steam Launch → Uses Steam profile → Loads from Workshop/packed mods
Editor Launch (F5) → Uses editor profile → Loads from mods-unpacked/
```

**To test unpacked mods:**

1. Open `project.godot` in Godot 3.6.2 editor
2. Press **F5** or click **Play** button
3. Mod loads from `mods-unpacked/` directory

**Steam launch will NOT load unpacked mods!**

---

## Where to Find Information

### When writing GDScript:

1. **Syntax questions**: https://docs.godotengine.org/en/3.6/tutorials/scripting/gdscript/gdscript_basics.html
2. **Class/method questions**: https://docs.godotengine.org/en/3.6/classes/index.html
3. **Node hierarchy**: Search specific node (e.g., "Control", "TextureRect")

### Common lookups:

- **Control node properties**: https://docs.godotengine.org/en/3.6/classes/class_control.html
- **Node methods**: https://docs.godotengine.org/en/3.6/classes/class_node.html
- **Signals**: https://docs.godotengine.org/en/3.6/classes/class_object.html#signals
- **Vector2**: https://docs.godotengine.org/en/3.6/classes/class_vector2.html
- **Color**: https://docs.godotengine.org/en/3.6/classes/class_color.html

---

## AI Assistant Best Practices

### ✅ DO:

- Always check Godot 3.6 docs before suggesting code
- Use explicit type hints (`var x: int = 5`)
- Use `._method()` when calling parent class methods
- Use `onready var` for node references
- Check node validity before accessing (`if node:`)
- Use `queue_free()` instead of `free()` for nodes
- Follow GDScript style guide (snake_case, 1 tab = 4 spaces)

### ❌ DON'T:

- Use Godot 4.x syntax (`await`, new signal connection syntax)
- Mix tabs and spaces (Godot uses **tabs**)
- Use `free()` on nodes (use `queue_free()`)
- Forget to call parent implementations (`._ready()`)
- Use string concatenation for paths (use `+` or format strings)
- Create nodes in `_init()` (use `_ready()` or `_enter_tree()`)

---

## Quick Reference Card

```gdscript
# Type hints
var health: int = 100
var speed: float = 5.0
var items: Array = []
var data: Dictionary = {}

# Node access
var node = $NodeName
var node = get_node("NodeName")
var parent = get_parent()
var children = get_children()

# Signals
signal died(cause)
emit_signal("died", "fall_damage")
connect("died", self, "_on_died")

# Inheritance
extends Node
._ready()  # Call parent

# Control flow
if condition:
    pass
elif other:
    pass
else:
    pass

for item in array:
    print(item)

match value:
    1:
        pass
    _:
        pass

# Memory
node.queue_free()
var weak = weakref(node)

# Yield/Coroutines
yield(get_tree().create_timer(1.0), "timeout")
yield(get_tree(), "idle_frame")

# Export
export var damage: int = 10
export(NodePath) var target_path

# Onready
onready var sprite = $Sprite
```

---

## Additional Resources

- **Godot 3.6 Documentation**: https://docs.godotengine.org/en/3.6/
- **GDScript Style Guide**: https://docs.godotengine.org/en/3.6/tutorials/scripting/gdscript/gdscript_styleguide.html
- **Class Reference (searchable)**: https://docs.godotengine.org/en/3.6/classes/index.html
- **Brotato ModLoader**: See `addons/mod_loader/` in project root

---

**REMEMBER: This project uses Godot 3.6.2. Always verify syntax and APIs against version 3.6 documentation!**
