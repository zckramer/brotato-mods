extends "res://ui/menus/shop/shop.gd"

# Extension to add Analytics button to shop

const ANALYTATO_LOG = "Calico-Analytato"
const AnalytatoButton = preload("res://mods-unpacked/Calico-Analytato/extensions/ui/analytato_button.gd")
const AnalyticsMenu = preload("res://mods-unpacked/Calico-Analytato/extensions/ui/analytics_menu.gd")

var _analytics_button: Button = null


func _ready() -> void:
	# Call parent _ready but catch any errors from double connections
	._ready()
	call_deferred("_add_analytics_button")


func _add_analytics_button() -> void:
	# Find the HBoxContainer that holds the Title, GoldUI, and RerollButton
	var reroll_button = get_node_or_null("%RerollButton")
	if not reroll_button:
		ModLoaderLog.error("Could not find RerollButton", ANALYTATO_LOG)
		return
	
	var hbox = reroll_button.get_parent()
	if not hbox:
		ModLoaderLog.error("Could not find RerollButton parent", ANALYTATO_LOG)
		return
	
	# Create Analytics button using our pink button
	var AnalytatoButton = load("res://mods-unpacked/Calico-Analytato/extensions/ui/analytato_button.gd")
	_analytics_button = AnalytatoButton.new()
	_analytics_button.text = "O"
	_analytics_button.button_text = "O"
	_analytics_button.rect_min_size = Vector2(60, 60)
	_analytics_button.size_flags_horizontal = SIZE_SHRINK_END
	_analytics_button.size_flags_vertical = SIZE_SHRINK_CENTER
	
	# Add to container after RerollButton (will appear to the right)
	hbox.add_child(_analytics_button)
	
	# Connect signal
	_analytics_button.connect("pressed", self, "_on_analytics_button_pressed")
	
	ModLoaderLog.info("Analytics button added to shop", ANALYTATO_LOG)


func _on_analytics_button_pressed() -> void:
	# Hide this menu
	visible = false
	
	# Create and show full-screen analytics menu
	var analytics_menu = AnalyticsMenu.new()
	analytics_menu.set_parent_menu(self)
	get_parent().add_child(analytics_menu)

