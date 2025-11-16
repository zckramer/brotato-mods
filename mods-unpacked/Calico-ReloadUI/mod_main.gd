extends Node

const RELOAD_UI_LOG = "Calico-ReloadUI"
const MOD_ID := "Calico-ReloadUI"

func _init() -> void:
	ModLoaderLog.info("Init", RELOAD_UI_LOG)
	
	var mod_dir_path := ModLoaderMod.get_unpacked_dir().plus_file("Calico-ReloadUI")
	_load_translations(mod_dir_path)
	_install_extensions(mod_dir_path)

func _ready() -> void:
	ModLoaderLog.info("Ready", RELOAD_UI_LOG)
	
	# Register options with ModOptions (after it's loaded)
	call_deferred("_register_mod_options")


func _load_translations(mod_dir_path: String) -> void:
	var translations_dir := mod_dir_path.plus_file("translations")
	ModLoaderMod.add_translation(translations_dir.plus_file("ReloadUI.en.translation"))


func _install_extensions(mod_dir_path: String) -> void:
	var extensions_dir := mod_dir_path.plus_file("extensions")
	
	# Install Main extension to inject weapon cooldown displays
	ModLoaderMod.install_script_extension(extensions_dir.plus_file("main_extension.gd"))
	
	# Install ChallengeService extension only if running from editor (prevents null save crashes)
	# This is a dev-only fix and can be removed for production releases
	if OS.has_feature("editor"):
		var singletons_dir := extensions_dir.plus_file("singletons")
		var challenge_service_path = singletons_dir.plus_file("challenge_service.gd")
		var file = File.new()
		if file.file_exists(challenge_service_path):
			ModLoaderMod.install_script_extension(challenge_service_path)


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
		ModLoaderLog.info("ModOptions not found, cooldown options unavailable", MOD_ID)
		return

	mod_options.register_mod_options("ReloadUI", {
		"tab_title": "RELOADUI_TAB_TITLE",
		"options": [
			{
				"type": "toggle",
				"id": "show_weapon_icons",
				"label": "RELOADUI_SHOW_WEAPON_ICONS_LABEL",
				"default": true
			},
			{
				"type": "toggle",
				"id": "show_tier_backgrounds",
				"label": "RELOADUI_SHOW_TIER_BACKGROUNDS_LABEL",
				"default": true
			},
			{
				"type": "toggle",
				"id": "show_cooldown_dots",
				"label": "RELOADUI_SHOW_COOLDOWN_DOTS_LABEL",
				"default": true
			},
			{
				"type": "toggle",
				"id": "hide_during_waves",
				"label": "RELOADUI_HIDE_DURING_WAVES_LABEL",
				"default": false
			}
		],
		"info_text": "RELOADUI_INFO_TEXT"
	})
