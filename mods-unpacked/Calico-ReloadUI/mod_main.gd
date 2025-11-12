extends Node

const RELOAD_UI_LOG = "Calico-ReloadUI"

func _init() -> void:
	ModLoaderLog.info("Init", RELOAD_UI_LOG)
	
	# Install PlayerUIElements extension for weapon cooldown display
	ModLoaderMod.install_script_extension("res://mods-unpacked/Calico-ReloadUI/extensions/ui/hud/player_ui_elements.gd")
	
	# Install ChallengeService extension to fix null save data crashes (bugfix for editor mode)
	ModLoaderMod.install_script_extension("res://mods-unpacked/Calico-ReloadUI/extensions/singletons/challenge_service.gd")

func _ready() -> void:
	ModLoaderLog.info("Ready", RELOAD_UI_LOG)
