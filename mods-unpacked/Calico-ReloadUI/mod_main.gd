extends Node

const RELOAD_UI_LOG = "Calico-ReloadUI"

func _init() -> void:
	ModLoaderLog.info("Init", RELOAD_UI_LOG)
	ModLoaderMod.install_script_extension("res://mods-unpacked/Calico-ReloadUI/extensions/ui/hud/player_ui_elements.gd")

func _ready() -> void:
	ModLoaderLog.info("Ready", RELOAD_UI_LOG)
