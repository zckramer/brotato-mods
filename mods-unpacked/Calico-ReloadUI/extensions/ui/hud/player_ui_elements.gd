## res://mods-unpacked/Calico-ReloadUI/extensions/ui/hud/player_ui_elements.gd
extends 'res://ui/hud/player_ui_elements.gd'

# Mod state
var _mod_initialized: bool = false
var _debug_frame_counter: int = 0
var _update_timer: Timer = null
var _current_player: Player = null

# Constants for weapon panel sizing
const WEAPON_PANEL_SIZE = Vector2(64, 64)
const WEAPON_ICON_SIZE = Vector2(48, 48)
const MAX_NAME_LENGTH = 12
const COOLDOWN_OVERLAY_COLOR = Color(1.0, 0.0, 0.0, 0.6)  # Red overlay during cooldown
const READY_OVERLAY_COLOR = Color(0.0, 1.0, 0.0, 0.4)      # Green overlay when ready
const READY_THRESHOLD = 0.05  # Show as ready when cooldown < 5%


func update_hud(player: Player) -> void:
	# Cache player reference for timer updates
	_current_player = player
	
	# Call parent's update_hud implementation
	if RunData.is_coop_run:
		life_bar.self_modulate.a = 0.75
		xp_bar.self_modulate.a = 0.75
		var player_color = CoopService.get_player_color(player_index)
		gold.gold_label.add_color_override("font_color", player_color)
		gold.icon.modulate = player_color

	life_bar.update_value(player.current_stats.health, player.max_stats.health)
	update_life_label(player)
	xp_bar.update_value(int(RunData.get_player_xp(player_index)), int(RunData.get_next_level_xp_needed(player_index)))
	update_level_label()
	gold.update_value(RunData.get_player_gold(player_index))
	
	# Initialize our custom UI on first update when we have access to scene
	if not _mod_initialized and hud_container != null:
		_initialize_custom_ui()
		_mod_initialized = true
		print("ReloadUI: Mod initialized")
	
	# Update weapon displays
	if _mod_initialized:
		_update_custom_display(player)


func _initialize_custom_ui() -> void:
	# Create container for weapon display
	var weapons_container = HBoxContainer.new()
	weapons_container.name = "ReloadUI_WeaponsContainer"
	
	# Add to the HUD container
	if hud_container:
		hud_container.add_child(weapons_container)
		
		# Create a timer to update weapon displays continuously
		_update_timer = Timer.new()
		_update_timer.name = "ReloadUI_UpdateTimer"
		_update_timer.wait_time = 0.016  # ~60 FPS (1/60 second)
		_update_timer.autostart = true
		_update_timer.connect("timeout", self, "_on_update_timer_timeout")
		hud_container.add_child(_update_timer)
		
		print("ReloadUI: Custom UI initialized successfully!")


func _on_update_timer_timeout() -> void:
	# Update weapon displays continuously
	if _current_player:
		_update_custom_display(_current_player)


func _update_custom_display(player: Player) -> void:
	if not hud_container:
		return
		
	var weapons_container = hud_container.get_node_or_null("ReloadUI_WeaponsContainer")
	if not weapons_container:
		return
	
	if not player.current_weapons:
		return
	
	# Sync panel count with weapon count
	var weapon_count = player.current_weapons.size()
	var panel_count = weapons_container.get_child_count()
	
	# Create new panels if needed
	while panel_count < weapon_count:
		weapons_container.add_child(_create_weapon_panel())
		panel_count += 1
	
	# Remove extra panels if needed
	while panel_count > weapon_count:
		weapons_container.get_child(panel_count - 1).queue_free()
		panel_count -= 1
	
	# Update each weapon panel with current data
	for i in range(weapon_count):
		_update_weapon_panel(weapons_container.get_child(i), player.current_weapons[i], i == 0)


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
	vbox.add_child(icon_container)
	
	# Add weapon icon
	var icon_rect = TextureRect.new()
	icon_rect.name = "Icon"
	icon_rect.expand = true
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.anchor_right = 1.0
	icon_rect.anchor_bottom = 1.0
	icon_container.add_child(icon_rect)
	
	# Add cooldown overlay (filled left-to-right during cooldown)
	var cooldown_overlay = ColorRect.new()
	cooldown_overlay.name = "CooldownOverlay"
	cooldown_overlay.color = COOLDOWN_OVERLAY_COLOR
	cooldown_overlay.anchor_top = 0.0
	cooldown_overlay.anchor_bottom = 1.0
	cooldown_overlay.anchor_left = 0.0
	cooldown_overlay.anchor_right = 0.0  # Will be updated based on cooldown
	cooldown_overlay.margin_right = 0.0
	cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(cooldown_overlay)
	
	# Add ready overlay (full green when ready to fire)
	var ready_overlay = ColorRect.new()
	ready_overlay.name = "ReadyOverlay"
	ready_overlay.color = READY_OVERLAY_COLOR
	ready_overlay.anchor_right = 1.0
	ready_overlay.anchor_bottom = 1.0
	ready_overlay.visible = false  # Hidden by default, shown when ready
	ready_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(ready_overlay)
	
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
	
	# Update cooldown overlays
	var cooldown_overlay = panel.get_node_or_null("VBox/IconContainer/CooldownOverlay")
	var ready_overlay = panel.get_node_or_null("VBox/IconContainer/ReadyOverlay")
	
	if cooldown_overlay and ready_overlay:
		var cooldown_ratio = _get_weapon_cooldown_ratio(weapon)
		
		# Debug output for first weapon only, every 60 frames (~1 second)
		if is_first_weapon:
			_debug_frame_counter += 1
			if _debug_frame_counter >= 60:
				_debug_frame_counter = 0
				var max_cd = weapon.current_stats.cooldown if ("current_stats" in weapon and weapon.current_stats) else 0
				var cur_cd = weapon._current_cooldown if "_current_cooldown" in weapon else 0
				var is_shooting = weapon._is_shooting if "_is_shooting" in weapon else false
				print("ReloadUI: cur=", stepify(cur_cd, 0.1), "/", max_cd, " ratio=", stepify(cooldown_ratio, 0.01), " shooting=", is_shooting)
		
		# Update overlay visibility based on cooldown state
		if cooldown_ratio > READY_THRESHOLD:
			# Weapon on cooldown - show red overlay filling left-to-right
			# INVERTED: 1.0 ratio (just fired) = 0% fill, 0.0 ratio (almost ready) = 100% fill
			ready_overlay.visible = false
			cooldown_overlay.visible = true
			cooldown_overlay.anchor_right = 1.0 - cooldown_ratio  # Invert the fill direction
		else:
			# Weapon ready - show green overlay
			ready_overlay.visible = true
			cooldown_overlay.visible = false


# Calculate weapon cooldown ratio (0.0 = ready, 1.0 = full cooldown)
func _get_weapon_cooldown_ratio(weapon) -> float:
	# Weapon is shooting - treat as on cooldown
	if "_is_shooting" in weapon and weapon._is_shooting:
		return 1.0
	
	# Get max cooldown (base stat affected by buffs/debuffs)
	var max_cooldown = 0.0
	if "current_stats" in weapon and weapon.current_stats and "cooldown" in weapon.current_stats:
		max_cooldown = float(weapon.current_stats.cooldown)
		
		# Check for reload mechanic (some weapons have longer cooldown every N shots)
		if "stats" in weapon and weapon.stats:
			var base_stats = weapon.stats
			if ("additional_cooldown_every_x_shots" in base_stats and 
				base_stats.additional_cooldown_every_x_shots > 0 and
				"_nb_shots_taken" in weapon):
				
				var shots_taken = weapon._nb_shots_taken
				# Apply reload multiplier if weapon just finished burst
				if shots_taken > 0 and (shots_taken % base_stats.additional_cooldown_every_x_shots == 0):
					if ("additional_cooldown_multiplier" in base_stats and 
						base_stats.additional_cooldown_multiplier > 0):
						max_cooldown *= base_stats.additional_cooldown_multiplier
	
	# Calculate ratio of current cooldown remaining
	if "_current_cooldown" in weapon and max_cooldown > 0.0:
		var current_cooldown = float(weapon._current_cooldown)
		return clamp(current_cooldown / max_cooldown, 0.0, 1.0)
	
	return 0.0  # No cooldown = ready


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
