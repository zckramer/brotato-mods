## res://mods-unpacked/Calico-ReloadUI/extensions/ui/hud/player_ui_elements.gd
extends 'res://ui/hud/player_ui_elements.gd'

# Mod state
var _mod_initialized: bool = false
var _debug_frame_counter: int = 0
var _current_player: Player = null
var _update_timer: Timer = null
var _weapons_container: HBoxContainer = null
var _weapon_panels: Array = []  # Pre-cached panel references

# Constants for weapon panel sizing
const WEAPON_PANEL_SIZE = Vector2(64, 64)
const WEAPON_ICON_SIZE = Vector2(48, 48)
const MAX_NAME_LENGTH = 12
const COOLDOWN_OVERLAY_COLOR = Color(1.0, 0.0, 0.0, 0.6)  # Red overlay during cooldown
const READY_OVERLAY_COLOR = Color(0.0, 1.0, 0.0, 0.4)      # Green overlay when ready
const FLASH_OVERLAY_COLOR = Color(1.0, 1.0, 0.0, 0.8)      # Bright yellow flash when firing
const READY_THRESHOLD = 0.05  # Show as ready when cooldown < 5%


func update_hud(player: Player) -> void:
	# Cache player reference for timer updates
	_current_player = player
	
	# Call parent's update_hud implementation (with safety checks)
	if RunData.is_coop_run:
		if life_bar:
			life_bar.self_modulate.a = 0.75
		if xp_bar:
			xp_bar.self_modulate.a = 0.75
		var player_color = CoopService.get_player_color(player_index)
		if gold and gold.gold_label:
			gold.gold_label.add_color_override("font_color", player_color)
		if gold and gold.icon:
			gold.icon.modulate = player_color

	if life_bar and player and player.current_stats and player.max_stats:
		life_bar.update_value(player.current_stats.health, player.max_stats.health)
	update_life_label(player)
	if xp_bar:
		xp_bar.update_value(int(RunData.get_player_xp(player_index)), int(RunData.get_next_level_xp_needed(player_index)))
	update_level_label()
	if gold:
		gold.update_value(RunData.get_player_gold(player_index))
	
	# Initialize our custom UI on first update when we have access to scene
	if not _mod_initialized and hud_container != null:
		_initialize_custom_ui()
		_mod_initialized = true
		print("ReloadUI: Mod initialized successfully")
	
	# Sync weapon panels when weapon count changes (not every frame!)
	if _mod_initialized and player and player.current_weapons:
		var weapon_count = player.current_weapons.size()
		if _weapon_panels.size() != weapon_count:
			_sync_weapon_panels(weapon_count)


func _initialize_custom_ui() -> void:
	if not hud_container:
		print("ReloadUI: ERROR - hud_container is null during initialization")
		return
	
	# Check if container already exists (avoid duplicates)
	if hud_container.has_node("ReloadUI_WeaponsContainer"):
		print("ReloadUI: Weapons container already exists, skipping initialization")
		return
	
	# Create container for weapon display
	_weapons_container = HBoxContainer.new()
	_weapons_container.name = "ReloadUI_WeaponsContainer"
	
	# Add to the HUD container
	hud_container.add_child(_weapons_container)
	
	# Create a timer for continuous updates (since update_hud isn't called every frame)
	_update_timer = Timer.new()
	_update_timer.name = "ReloadUI_UpdateTimer"
	_update_timer.wait_time = 0.016  # ~60 FPS
	_update_timer.autostart = true
	hud_container.add_child(_update_timer)
	_update_timer.connect("timeout", self, "_on_update_timer_timeout")
	
	print("ReloadUI: Custom UI container and update timer created")


func _sync_weapon_panels(weapon_count: int) -> void:
	# Called ONLY when weapon count changes 
	var panel_count = _weapon_panels.size()
	
	# Create new panels if needed
	while panel_count < weapon_count:
		var new_panel = _create_weapon_panel()
		_weapons_container.add_child(new_panel)
		_weapon_panels.append(new_panel)
		panel_count += 1
	
	# Remove extra panels if needed
	while panel_count > weapon_count:
		var removed_panel = _weapon_panels.pop_back()
		removed_panel.queue_free()
		panel_count -= 1
	
	print("ReloadUI: Synced to ", weapon_count, " weapon panels")


func _on_update_timer_timeout() -> void:
	# Called every ~16ms (~60 FPS) - ONLY update weapon panel visuals
	if not _current_player or not _current_player.current_weapons:
		return
	
	# Fast path: just update the visuals, no lookups or checks
	var weapon_count = min(_weapon_panels.size(), _current_player.current_weapons.size())
	for i in range(weapon_count):
		_update_weapon_panel(_weapon_panels[i], _current_player.current_weapons[i], i == 0)


func _create_weapon_panel() -> Control:
	# Create a panel for each weapon with fixed size
	var panel = PanelContainer.new()
	panel.rect_min_size = WEAPON_PANEL_SIZE
	
	# Create inner container for icon and label
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	panel.add_child(vbox)
	
	# Add weapon icon container with overlay
	var icon_container = Control.new()
	icon_container.name = "IconContainer"
	icon_container.rect_min_size = WEAPON_ICON_SIZE
	icon_container.rect_size = WEAPON_ICON_SIZE  # Force exact size
	vbox.add_child(icon_container)
	
	# Add weapon icon
	var icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.expand = true
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.anchor_right = 1.0
	icon_rect.anchor_bottom = 1.0
	icon_container.add_child(icon_rect)
	
	# Add cooldown overlay (red fills left-to-right during cooldown)
	var cooldown_overlay = ColorRect.new()
	cooldown_overlay.name = "CooldownOverlay"
	cooldown_overlay.color = COOLDOWN_OVERLAY_COLOR
	cooldown_overlay.anchor_top = 0.0
	cooldown_overlay.anchor_bottom = 1.0
	cooldown_overlay.anchor_left = 0.0  # Start at left edge
	cooldown_overlay.anchor_right = 0.0  # Width will be controlled via rect_size.x
	cooldown_overlay.rect_position = Vector2(0, 0)
	cooldown_overlay.rect_size = Vector2(0, 0)  # Start with 0 width (no red)
	cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(cooldown_overlay)
	
	# Add ready overlay (full green when ready to fire)
	var ready_overlay = ColorRect.new()
	ready_overlay.name = "ReadyOverlay"
	ready_overlay.color = READY_OVERLAY_COLOR
	ready_overlay.anchor_left = 0.0
	ready_overlay.anchor_top = 0.0
	ready_overlay.anchor_right = 1.0
	ready_overlay.anchor_bottom = 1.0
	ready_overlay.visible = false  # Hidden by default, shown when ready
	ready_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(ready_overlay)
	
	# Add flash overlay (bright yellow when firing)
	var flash_overlay = ColorRect.new()
	flash_overlay.name = "FlashOverlay"
	flash_overlay.color = FLASH_OVERLAY_COLOR
	flash_overlay.anchor_left = 0.0
	flash_overlay.anchor_top = 0.0
	flash_overlay.anchor_right = 1.0
	flash_overlay.anchor_bottom = 1.0
	flash_overlay.visible = false  # Hidden by default, shown when is_shooting
	flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(flash_overlay)
	
	# Add weapon name label
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.align = Label.ALIGN_CENTER
	name_label.add_color_override("font_color", Color.white)
	vbox.add_child(name_label)
	
	return panel


# Update existing weapon panel with current weapon data
func _update_weapon_panel(panel: Control, weapon, is_first_weapon: bool) -> void:
	# Update icon
	var icon_rect = panel.get_node_or_null("VBox/IconContainer/Icon")
	if icon_rect and "icon" in weapon and weapon.icon is Texture:
		icon_rect.texture = weapon.icon

	# Update name
	var name_label = panel.get_node_or_null("VBox/NameLabel")
	if name_label:
		name_label.text = _get_formatted_weapon_name(weapon)

	# Overlays
	var cooldown_overlay = panel.get_node_or_null("VBox/IconContainer/CooldownOverlay")
	var ready_overlay = panel.get_node_or_null("VBox/IconContainer/ReadyOverlay")
	var flash_overlay = panel.get_node_or_null("VBox/IconContainer/FlashOverlay")
	if not (cooldown_overlay and ready_overlay and flash_overlay):
		return

	# Compute progress (elapsed / max)
	var max_cd = 0.0
	if "current_stats" in weapon and weapon.current_stats and "cooldown" in weapon.current_stats:
		max_cd = float(weapon.current_stats.cooldown)
	var cur_cd = 0.0
	if "_current_cooldown" in weapon:
		cur_cd = float(weapon._current_cooldown)
	var has_fired = ("_nb_shots_taken" in weapon and weapon._nb_shots_taken > 0)
	var is_shooting = ("_is_shooting" in weapon and weapon._is_shooting)

	var progress = 0.0  # 0.0 empty bar (just fired), 1.0 full bar (ready)
	var state = "READY"
	
	if max_cd > 0.0:
		# _current_cooldown counts DOWN from ~max_cd to 0
		# When cur_cd reaches 0, weapon is ready to fire
		# Progress: 0.0 = just fired (full cooldown remaining), 1.0 = ready (no cooldown remaining)
		progress = 1.0 - clamp(cur_cd / max_cd, 0.0, 1.0)
		
		# State priority:
		# 1. READY: Cooldown finished (cur_cd at or near 0)
		if cur_cd <= 0.0:
			state = "READY"
			progress = 1.0
		# 2. JUST_FIRED: Brief flash during actual shooting animation
		elif is_shooting:
			state = "JUST_FIRED"
			# Progress stays wherever it is in the cooldown
		# 3. COOLING: Counting down from max to 0
		else:
			state = "COOLING"
	else:
		# No cooldown stat: always ready unless shooting
		if is_shooting:
			progress = 1.0  # Full bar, but yellow flash
			state = "JUST_FIRED"
		else:
			progress = 1.0
			state = "READY"

	# Apply visual state
	if state == "READY":
		ready_overlay.visible = true
		cooldown_overlay.visible = false
		flash_overlay.visible = false
	elif state == "JUST_FIRED":
		ready_overlay.visible = false
		cooldown_overlay.visible = false
		flash_overlay.visible = true  # Bright yellow flash on firing
	else: # COOLING
		ready_overlay.visible = false
		cooldown_overlay.visible = true
		flash_overlay.visible = false
		# Bar grows from left (0px) to right (48px) as progress goes 0.0 → 1.0
		var w = WEAPON_ICON_SIZE.x
		cooldown_overlay.rect_position.x = 0
		cooldown_overlay.rect_size.x = w * progress

	# Debug (first weapon, every 30 frames)
	if is_first_weapon:
		_debug_frame_counter += 1
		if _debug_frame_counter >= 30:
			_debug_frame_counter = 0
			print("ReloadUI: cur=", stepify(cur_cd,0.1), "/", stepify(max_cd,0.1), " progress=", stepify(progress,0.01), " state=", state, " shooting=", is_shooting, " fired=", has_fired)


# Calculate weapon cooldown ratio (0.0 = ready, 1.0 = full cooldown)
func _get_weapon_cooldown_progress(weapon) -> float:
	var max_cooldown = 0.0
	if "current_stats" in weapon and weapon.current_stats and "cooldown" in weapon.current_stats:
		max_cooldown = float(weapon.current_stats.cooldown)
		if "stats" in weapon and weapon.stats:
			var base_stats = weapon.stats
			if ("additional_cooldown_every_x_shots" in base_stats and base_stats.additional_cooldown_every_x_shots > 0 and "_nb_shots_taken" in weapon):
				var shots_taken = weapon._nb_shots_taken
				if shots_taken > 0 and (shots_taken % base_stats.additional_cooldown_every_x_shots == 0):
					if ("additional_cooldown_multiplier" in base_stats and base_stats.additional_cooldown_multiplier > 0):
						max_cooldown *= base_stats.additional_cooldown_multiplier

	if max_cooldown <= 0.0:
		return 1.0  # treat as ready if no cooldown stat

	var current_cooldown = 0.0
	if "_current_cooldown" in weapon:
		current_cooldown = float(weapon._current_cooldown)

	return clamp(current_cooldown / max_cooldown, 0.0, 1.0)


# Format weapon name for display
func _get_formatted_weapon_name(weapon) -> String:
	var raw_name = ""
	
	# Try different name properties
	if "weapon_id" in weapon:
		raw_name = str(weapon.weapon_id)
	elif "my_id" in weapon:
		raw_name = str(weapon.my_id)
	elif "name" in weapon:
		raw_name = str(weapon.name)
	else:
		return "Weapon"
	
	# Clean up name: remove prefix, format, truncate
	var formatted = raw_name.replace("weapon_", "").replace("_", " ").capitalize()
	
	if formatted.length() > MAX_NAME_LENGTH:
		formatted = formatted.substr(0, MAX_NAME_LENGTH - 2) + ".."
	
	return formatted
