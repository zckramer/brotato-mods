extends "res://ui/menus/shop/shop.gd"

# Extension to add Analytics button to shop

const ANALYTATO_LOG = "Calico-Analytato"

var _analytics_button: Button = null
var _analytics_panel: Panel = null


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
	
	# Create stats panel (hidden by default)
	_create_analytics_panel()
	
	ModLoaderLog.info("Analytics button added to shop", ANALYTATO_LOG)


func _create_analytics_panel() -> void:
	# Create a popup panel
	_analytics_panel = Panel.new()
	_analytics_panel.anchor_left = 0.5
	_analytics_panel.anchor_top = 0.5
	_analytics_panel.anchor_right = 0.5
	_analytics_panel.anchor_bottom = 0.5
	_analytics_panel.margin_left = -200
	_analytics_panel.margin_top = -150
	_analytics_panel.margin_right = 200
	_analytics_panel.margin_bottom = 150
	_analytics_panel.visible = false
	
	# Add VBoxContainer for content
	var vbox = VBoxContainer.new()
	vbox.anchor_right = 1
	vbox.anchor_bottom = 1
	vbox.margin_left = 20
	vbox.margin_top = 20
	vbox.margin_right = -20
	vbox.margin_bottom = -20
	_analytics_panel.add_child(vbox)
	
	# Add title label (pink)
	var title = Label.new()
	title.text = "Combat Analytics"
	title.align = Label.ALIGN_CENTER
	title.add_color_override("font_color", Color(1.0, 0.4, 0.7))
	vbox.add_child(title)
	
	# Add separator
	var separator = HSeparator.new()
	separator.rect_min_size.y = 20
	vbox.add_child(separator)
	
	# Add greeting label (pink)
	var greeting = Label.new()
	greeting.text = "Hello, zack!"
	greeting.align = Label.ALIGN_CENTER
	greeting.size_flags_vertical = SIZE_EXPAND_FILL
	greeting.valign = Label.VALIGN_CENTER
	greeting.add_color_override("font_color", Color(1.0, 0.4, 0.7))
	vbox.add_child(greeting)
	
	# Add close button using our custom AnalytatoButton
	var AnalytatoButton = load("res://mods-unpacked/Calico-Analytato/extensions/ui/analytato_button.gd")
	var close_btn = AnalytatoButton.new()
	close_btn.name = "CloseButton"
	close_btn.text = "Close"
	close_btn.button_text = "Close"
	close_btn.rect_min_size = Vector2(0, 50)
	close_btn.connect("pressed", self, "_on_analytics_panel_close")
	vbox.add_child(close_btn)
	
	# Add panel to scene
	add_child(_analytics_panel)


func _on_analytics_button_pressed() -> void:
	if _analytics_panel:
		_analytics_panel.visible = true
		# Disable shop button focus when panel is open
		if has_method("disable_shop_buttons_focus"):
			disable_shop_buttons_focus()
		# Focus the close button by name
		var vbox = _analytics_panel.get_child(0)
		var close_btn = vbox.get_node_or_null("CloseButton")
		if close_btn:
			close_btn.grab_focus()


func _on_analytics_panel_close() -> void:
	if _analytics_panel:
		_analytics_panel.visible = false
		# Re-enable shop button focus when panel closes
		if has_method("enable_shop_buttons_focus"):
			enable_shop_buttons_focus()
		# Return focus to AT button
		if _analytics_button:
			_analytics_button.grab_focus()


func _input(event: InputEvent) -> void:
	._input(event)
	
	# Allow ESC to close panel
	if event.is_action_pressed("ui_cancel") and _analytics_panel and _analytics_panel.visible:
		_on_analytics_panel_close()
		get_tree().set_input_as_handled()
