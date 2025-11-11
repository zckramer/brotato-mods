## res://mods-unpacked/Calico-ReloadUI/extensions/ui/hud/player_ui_elements.gd
extends 'res://ui/hud/player_ui_elements.gd'


# Extension: Simple debug display to verify mod is working
var _mod_initialized: bool = false


func update_hud(player: Player) -> void:
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
	
	# Update custom display
	_update_custom_display(player)


func _initialize_custom_ui() -> void:
	# Add a simple label to verify the mod is working
	var test_label = Label.new()
	test_label.name = "ReloadUI_TestLabel"
	test_label.text = "MOD ACTIVE"
	test_label.add_color_override("font_color", Color(0, 1, 0))  # Green text
	
	# Add to the hud container
	if hud_container:
		hud_container.add_child(test_label)
		print("ReloadUI: Custom UI initialized successfully!")


func _update_custom_display(player: Player) -> void:
	# Find our label and update it with player info
	if hud_container:
		var test_label = hud_container.get_node_or_null("ReloadUI_TestLabel")
		if test_label:
			test_label.text = "MOD: Armor=" + str(int(player.current_stats.armor))
