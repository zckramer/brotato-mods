extends "res://main.gd"

const MOD_NAME := "Calico-ReloadUI"

var _reload_ui_injected: bool = false
var _weapon_displays: Array = []  # One per player
var _weapon_data_cache: Dictionary = {}  # Cache for WeaponData lookups
var _mod_options: Node = null  # Reference to ModOptions

# Settings cache
var _show_icons: bool = true
var _show_backgrounds: bool = true
var _show_dots: bool = true
var _hide_during_waves: bool = false

func _enter_tree() -> void:
	if not _reload_ui_injected:
		call_deferred("_inject_reload_ui")
		call_deferred("_connect_to_mod_options")
		_reload_ui_injected = true


func _connect_to_mod_options() -> void:
	# Get ModOptions reference
	var mod_loader = get_node_or_null("/root/ModLoader")
	if not mod_loader:
		return
	
	var mod_options_mod = mod_loader.get_node_or_null("Oudstand-ModOptions")
	if not mod_options_mod:
		return
	
	_mod_options = mod_options_mod.get_node_or_null("ModOptions")
	if not _mod_options:
		return
	
	# Connect to settings change signal
	if not _mod_options.is_connected("config_changed", self, "_on_config_changed"):
		_mod_options.connect("config_changed", self, "_on_config_changed")
	
	# Load initial settings
	_load_settings()


func _load_settings() -> void:
	if not _mod_options:
		return
	
	_show_icons = _mod_options.get_value("ReloadUI", "show_weapon_icons")
	if _show_icons == null:
		_show_icons = true
	
	_show_backgrounds = _mod_options.get_value("ReloadUI", "show_tier_backgrounds")
	if _show_backgrounds == null:
		_show_backgrounds = true
	
	_show_dots = _mod_options.get_value("ReloadUI", "show_cooldown_dots")
	if _show_dots == null:
		_show_dots = true
	
	_hide_during_waves = _mod_options.get_value("ReloadUI", "hide_during_waves")
	if _hide_during_waves == null:
		_hide_during_waves = false


func _on_config_changed(mod_id: String, option_id: String, new_value) -> void:
	if mod_id != "ReloadUI":
		return
	
	match option_id:
		"show_weapon_icons":
			_show_icons = new_value
		"show_tier_backgrounds":
			_show_backgrounds = new_value
		"show_cooldown_dots":
			_show_dots = new_value
		"hide_during_waves":
			_hide_during_waves = new_value


func _inject_reload_ui() -> void:
	for i in range(4):
		var player_idx = str(i + 1)
		var parent_path = "UI/HUD/LifeContainerP%s" % player_idx
		var parent_node = get_node_or_null(parent_path)
		
		if not is_instance_valid(parent_node):
			continue
		
		var display_name = "ReloadUI_WeaponDisplayP%s" % player_idx
		if parent_node.has_node(display_name):
			continue
		
		# Create weapon display container
		var weapon_display = HBoxContainer.new()
		weapon_display.name = display_name
		weapon_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
		parent_node.add_child(weapon_display)
		
		_weapon_displays.append(weapon_display)


func _on_EntitySpawner_players_spawned(players: Array) -> void:
	._on_EntitySpawner_players_spawned(players)
	call_deferred("_setup_weapon_displays", players)


func _setup_weapon_displays(players: Array) -> void:
	for i in range(min(players.size(), _weapon_displays.size())):
		var display = _weapon_displays[i]
		if not is_instance_valid(display):
			continue
		
		display.visible = true
		_update_weapon_display(display, players[i])


func _physics_process(delta: float) -> void:
	._physics_process(delta)
	
	# Update weapon displays every frame
	if _players.size() > 0:
		for i in range(min(_players.size(), _weapon_displays.size())):
			if is_instance_valid(_weapon_displays[i]) and is_instance_valid(_players[i]):
				_update_weapon_display(_weapon_displays[i], _players[i])


func _update_weapon_display(display: HBoxContainer, player: Player) -> void:
	if not is_instance_valid(player) or not player.current_weapons:
		return
	
	# Build cache of WeaponData for fast icon lookups
	_weapon_data_cache.clear()
	var weapon_data_array = RunData.players_data[player.player_index].weapons
	for weapon_data in weapon_data_array:
		var key = "%s_t%d" % [weapon_data.weapon_id, weapon_data.tier]
		_weapon_data_cache[key] = weapon_data
	
	var weapon_count = player.current_weapons.size()
	var panel_count = display.get_child_count()
	
	# Sync panel count
	while panel_count < weapon_count:
		var panel = _create_weapon_panel()
		display.add_child(panel)
		panel_count += 1
	
	while panel_count > weapon_count:
		display.get_child(panel_count - 1).queue_free()
		panel_count -= 1
	
	# Update each panel
	for i in range(weapon_count):
		_update_weapon_panel(display.get_child(i), player.current_weapons[i])


const WEAPON_ICON_SIZE = Vector2(48, 48)
const DOT_SIZE = 8.0  # Size of the cooldown indicator dot
const COOLDOWN_DOT_COLOR = Color(1.0, 0.3, 0.0, 1.0)
const READY_DOT_COLOR = Color(0.0, 1.0, 0.0, 1.0)
const FIRING_DOT_COLOR = Color(1.0, 1.0, 0.0, 1.0)


func _create_weapon_panel() -> Control:
	# Use Control instead of PanelContainer to avoid background
	var panel = Control.new()
	panel.rect_min_size = Vector2(64, 64)
	
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.anchor_right = 1.0
	vbox.anchor_bottom = 1.0
	panel.add_child(vbox)
	
	var icon_container = Control.new()
	icon_container.name = "IconContainer"
	icon_container.rect_min_size = WEAPON_ICON_SIZE
	icon_container.rect_size = WEAPON_ICON_SIZE
	vbox.add_child(icon_container)
	
	# Background panel for tier color (semi-transparent)
	var icon_bg = Panel.new()
	icon_bg.name = "IconBg"
	icon_bg.anchor_right = 1.0
	icon_bg.anchor_bottom = 1.0
	icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(icon_bg)
	
	# Icon must be added AFTER background so it renders on top
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.expand = true
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.anchor_right = 1.0
	icon.anchor_bottom = 1.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(icon)
	
	# Add colored dot indicator (bottom-right corner)
	var dot = ColorRect.new()
	dot.name = "Dot"
	dot.rect_size = Vector2(DOT_SIZE, DOT_SIZE)
	dot.rect_position = Vector2(WEAPON_ICON_SIZE.x - DOT_SIZE - 2, WEAPON_ICON_SIZE.y - DOT_SIZE - 2)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(dot)
	
	return panel


func _update_weapon_panel(panel: Control, weapon_node) -> void:
	var icon = panel.get_node_or_null("VBox/IconContainer/Icon")
	
	if icon and is_instance_valid(weapon_node):
		# Apply icon visibility setting
		icon.visible = _show_icons
		
		if _show_icons:
			# Match weapon_node (Node2D) to weapon_data (Resource) via cache
			var key = "%s_t%d" % [weapon_node.weapon_id, weapon_node.tier]
			if _weapon_data_cache.has(key):
				var weapon_data = _weapon_data_cache[key]
				icon.texture = weapon_data.icon
	
	# Update background color based on tier (using ItemService from game)
	var icon_bg = panel.get_node_or_null("VBox/IconContainer/IconBg")
	if icon_bg and "tier" in weapon_node:
		icon_bg.visible = _show_backgrounds
		
		if _show_backgrounds:
			var stylebox = StyleBoxFlat.new()
			ItemService.change_inventory_element_stylebox_from_tier(stylebox, weapon_node.tier, 0.5)  # 0.5 alpha for transparency
			
			# Rounded corners
			stylebox.corner_radius_top_left = 6
			stylebox.corner_radius_top_right = 6
			stylebox.corner_radius_bottom_left = 6
			stylebox.corner_radius_bottom_right = 6
			
			icon_bg.add_stylebox_override("panel", stylebox)
	
	var dot = panel.get_node_or_null("VBox/IconContainer/Dot")
	if not dot:
		return
	
	# Apply dot visibility setting
	dot.visible = _show_dots
	
	if not _show_dots:
		return
	
	# Calculate cooldown state
	var cur_cd = weapon_node._current_cooldown if "_current_cooldown" in weapon_node else 0.0
	var is_shooting = weapon_node._is_shooting if "_is_shooting" in weapon_node else false
	
	var state = "READY"
	if is_shooting:
		state = "FIRING"
	elif cur_cd > 0.0:
		state = "COOLING"
	
	# Set dot color based on state
	if state == "FIRING":
		dot.color = FIRING_DOT_COLOR
	elif state == "COOLING":
		dot.color = COOLDOWN_DOT_COLOR
	else:
		dot.color = READY_DOT_COLOR


func _on_EntitySpawner_wave_ended() -> void:
	._on_EntitySpawner_wave_ended()
	
	# Hide all weapon displays during inter-wave (shop, levelup, etc)
	for display in _weapon_displays:
		if is_instance_valid(display):
			display.visible = false


func _on_EntitySpawner_wave_started() -> void:
	._on_EntitySpawner_wave_started()
	
	# Show weapon displays when wave starts (unless hide_during_waves is enabled)
	if not _hide_during_waves:
		for i in range(min(_players.size(), _weapon_displays.size())):
			if is_instance_valid(_weapon_displays[i]):
				_weapon_displays[i].visible = true
