extends "res://ui/menus/title_screen/title_screen.gd"

# Extension to add Analytics button to title screen main menu

const ANALYTATO_LOG = "Calico-Analytato"
const AnalytatoButton = preload("res://mods-unpacked/Calico-Analytato/extensions/ui/analytato_button.gd")
const AnalyticsMenu = preload("res://mods-unpacked/Calico-Analytato/extensions/ui/analytics_menu.gd")

var _analytics_button: Button = null


func _ready() -> void:
	._ready()
	call_deferred("_add_analytics_button")


func _add_analytics_button() -> void:
	# Find the main menu VBoxContainer
	var main_menu = get_node_or_null("%MainMenu")
	if not main_menu:
		ModLoaderLog.error("Could not find MainMenu", ANALYTATO_LOG)
		return
	
	# Create Analytics button using our pink button
	_analytics_button = AnalytatoButton.new()
	_analytics_button.text = "O"
	_analytics_button.button_text = "O"
	_analytics_button.rect_min_size = Vector2(60, 60)
	
	# Add to main menu (will appear at bottom)
	main_menu.add_child(_analytics_button)
	
	# Connect signal
	_analytics_button.connect("pressed", self, "_on_analytics_button_pressed")
	
	ModLoaderLog.info("Analytics button added to main menu", ANALYTATO_LOG)


func _on_analytics_button_pressed() -> void:
	# Hide this menu
	visible = false
	
	# Create and show full-screen analytics menu
	var analytics_menu = AnalyticsMenu.new()
	analytics_menu.set_parent_menu(self)
	get_parent().add_child(analytics_menu)
