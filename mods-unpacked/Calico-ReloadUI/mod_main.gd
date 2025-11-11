extends Node

const RELOAD_UI_LOG = "Calico-ReloadUI"

func _init(modLoader = ModLoader):
	ModLoaderUtils.log_info("Init", RELOAD_UI_LOG)
	modLoader.install_script_extension("res://mods-unpacked/Calico-ReloadUI/extensions/ui/hud/player_ui_elements.gd")

func _ready():
	ModLoaderUtils.log_info("Ready", RELOAD_UI_LOG)
