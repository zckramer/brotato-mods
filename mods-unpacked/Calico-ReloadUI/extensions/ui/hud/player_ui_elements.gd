## res://mods-unpacked/Calico-ReloadUI/extensions/ui/hud/player_ui_elements.gd
extends 'res://ui/hud/player_ui_elements.gd'


# Extension: Add custom UI status elements with color overlays
var status_elements: Array = []
var status_container: HBoxContainer


func _ready() -> void:
	# Create container for custom status elements
	status_container = HBoxContainer.new()
	status_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status_container.add_constant_override("separation", 8)
	
	# Initialize three custom status elements
	_create_status_element("Shield", Color(0.2, 0.8, 1.0, 0.6))  # Cyan overlay
	_create_status_element("Energy", Color(1.0, 0.8, 0.2, 0.6))  # Yellow overlay
	_create_status_element("Focus", Color(0.8, 0.2, 1.0, 0.6))   # Purple overlay


func _create_status_element(name: String, overlay_color: Color) -> void:
	var element = {
		"name": name,
		"panel": PanelContainer.new(),
		"texture": TextureRect.new(),
		"label": Label.new(),
		"overlay_color": overlay_color
	}
	
	# Setup the panel
	element["panel"].custom_minimum_size = Vector2(48, 48)
	element["panel"].add_stylebox_override("panel", _create_flat_stylebox(overlay_color))
	
	# Setup the placeholder texture (solid color square)
	element["texture"].texture = _create_placeholder_texture(overlay_color)
	element["texture"].expand = true
	element["texture"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	element["texture"].size_flags_vertical = Control.SIZE_EXPAND_FILL
	element["texture"].modulate = Color(1.0, 1.0, 1.0, 0.7)
	
	# Setup the label
	element["label"].text = name
	element["label"].align = Label.ALIGN_CENTER
	element["label"].valign = Label.VALIGN_CENTER
	element["label"].add_font_override("font", _create_small_font())
	element["label"].add_color_override("font_color", Color.white)
	
	# Create overlay effect
	var margin = MarginContainer.new()
	margin.add_child(element["texture"])
	element["panel"].add_child(margin)
	
	# Add label on top
	var overlay_label = Control.new()
	overlay_label.add_child(element["label"])
	element["panel"].add_child(overlay_label)
	
	status_container.add_child(element["panel"])
	status_elements.append(element)


func _create_placeholder_texture(color: Color) -> Texture:
	var img = Image.new()
	img.create(32, 32, false, Image.FORMAT_RGBA8)
	
	# Create a gradient from transparent to the color
	for y in range(32):
		for x in range(32):
			var dist = sqrt(pow(x - 16, 2) + pow(y - 16, 2)) / 16.0
			var alpha = max(0.0, 1.0 - dist)
			img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha * 0.8))
	
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	return tex


func _create_flat_stylebox(color: Color) -> StyleBox:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(color.r, color.g, color.b, 0.3)
	style.set_border_enabled_all(true)
	style.set_border_width_all(2)
	style.border_color = color
	return style


func _create_small_font() -> Font:
	var font = Font.new()
	return font  # Falls back to default small font


func update_hud(player: Player) -> void:
	# Call parent implementation
	._update_hud(player)
	
	# Update custom status elements with placeholder values
	_update_status_elements(player)


func _update_hud(player: Player) -> void:
	# This ensures we call the parent's update_hud
	# by invoking the original implementation
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


func _update_status_elements(player: Player) -> void:
	# Placeholder: Update status elements with dummy values
	if status_elements.size() >= 1:
		status_elements[0]["label"].text = "Shield: " + str(int(player.current_stats.armor))
	if status_elements.size() >= 2:
		status_elements[1]["label"].text = "Energy: 100%"
	if status_elements.size() >= 3:
		status_elements[2]["label"].text = "Focus: 75%"
