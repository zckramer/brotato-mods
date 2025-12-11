extends Node

const ANALYTATO_LOG = "Calico-Analytato"
const MOD_ID := "Calico-Analytato"

# Mod settings (loaded from config)
var settings := {
	"enable_kill_tracking": true,
	"enable_damage_tracking": true,
	"enable_dodge_tracking": true,
	"enable_projectile_tracking": false,
	"show_stats_overlay": true,
	"stats_position": "top_right"
}

func _init() -> void:
	ModLoaderLog.info("Init", ANALYTATO_LOG)
	
	var mod_dir_path := ModLoaderMod.get_unpacked_dir().plus_file("Calico-Analytato")
	_load_translations(mod_dir_path)
	_load_settings()
	_install_extensions(mod_dir_path)

func _ready() -> void:
	ModLoaderLog.info("Ready", ANALYTATO_LOG)
	ModLoaderLog.info("Combat analytics tracking enabled", ANALYTATO_LOG)
	
	# Register options with ModOptions (after it's loaded)
	call_deferred("_register_mod_options")


func _load_translations(mod_dir_path: String) -> void:
	var translations_dir := mod_dir_path.plus_file("translations")
	var translation_file := translations_dir.plus_file("Analytato.en.translation")
	
	# Only add translation if file exists
	var file = File.new()
	if file.file_exists(translation_file):
		ModLoaderMod.add_translation(translation_file)


func _load_settings() -> void:
	# Settings will be loaded from ModOptions when available
	# Default values are already set in settings dict
	ModLoaderLog.debug("Default settings initialized: %s" % str(settings), ANALYTATO_LOG)


func _install_extensions(mod_dir_path: String) -> void:
	var extensions_dir := mod_dir_path.plus_file("extensions")
	
	# Install shop extension to add analytics button
	ModLoaderMod.install_script_extension(extensions_dir.plus_file("shop_extension.gd"))
	
	# Install title screen extension to add analytics button to main menu
	ModLoaderMod.install_script_extension(extensions_dir.plus_file("title_screen_extension.gd"))
	
	ModLoaderLog.info("Extensions installed", ANALYTATO_LOG)


func get_setting(key: String):
	return settings.get(key, null)


func set_setting(key: String, value) -> void:
	settings[key] = value
	var mod_options = _get_mod_options()
	if mod_options:
		mod_options.set_value("Analytato", key, value)


func _get_mod_options() -> Node:
	# Get sibling mod node (both are children of ModLoader)
	var parent = get_parent()
	if not parent:
		return null
	var mod_options_mod = parent.get_node_or_null("Oudstand-ModOptions")
	if not mod_options_mod:
		return null
	return mod_options_mod.get_node_or_null("ModOptions")


func _register_mod_options() -> void:
	var mod_options = _get_mod_options()
	if not mod_options:
		ModLoaderLog.info("ModOptions not found, using default settings", ANALYTATO_LOG)
		return

	mod_options.register_mod_options("Analytato", {
		"tab_title": "ANALYTATO_TAB_TITLE",
		"options": [
			{
				"type": "toggle",
				"id": "enable_kill_tracking",
				"label": "ANALYTATO_ENABLE_KILL_TRACKING_LABEL",
				"default": true
			},
			{
				"type": "toggle",
				"id": "enable_damage_tracking",
				"label": "ANALYTATO_ENABLE_DAMAGE_TRACKING_LABEL",
				"default": true
			},
			{
				"type": "toggle",
				"id": "enable_dodge_tracking",
				"label": "ANALYTATO_ENABLE_DODGE_TRACKING_LABEL",
				"default": true
			},
			{
				"type": "toggle",
				"id": "enable_projectile_tracking",
				"label": "ANALYTATO_ENABLE_PROJECTILE_TRACKING_LABEL",
				"default": false
			},
			{
				"type": "toggle",
				"id": "show_stats_overlay",
				"label": "ANALYTATO_SHOW_STATS_OVERLAY_LABEL",
				"default": true
			},
			{
				"type": "dropdown",
				"id": "stats_position",
				"label": "ANALYTATO_STATS_POSITION_LABEL",
				"default": "top_right",
				"options": [
					{"value": "top_left", "label": "ANALYTATO_POSITION_TOP_LEFT"},
					{"value": "top_right", "label": "ANALYTATO_POSITION_TOP_RIGHT"},
					{"value": "bottom_left", "label": "ANALYTATO_POSITION_BOTTOM_LEFT"},
					{"value": "bottom_right", "label": "ANALYTATO_POSITION_BOTTOM_RIGHT"}
				]
			}
		],
		"info_text": "ANALYTATO_INFO_TEXT"
	})
	
	# Load current settings from ModOptions
	for key in settings.keys():
		var value = mod_options.get_value("Analytato", key)
		if value != null:
			settings[key] = value
	
	ModLoaderLog.info("ModOptions registered and settings loaded", ANALYTATO_LOG)
