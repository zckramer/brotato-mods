extends "res://ui/menus/title_screen/title_screen.gd"

# Extension to add Analytics button to title screen main menu

const ANALYTATO_LOG = "Calico-Analytato"

var _analytics_button: Button = null
var _analytics_panel: Panel = null


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
	var AnalytatoButton = load("res://mods-unpacked/Calico-Analytato/extensions/ui/analytato_button.gd")
	_analytics_button = AnalytatoButton.new()
	_analytics_button.text = "O"
	_analytics_button.button_text = "O"
	_analytics_button.rect_min_size = Vector2(60, 60)
	
	# Add to main menu (will appear at bottom)
	main_menu.add_child(_analytics_button)
	
	# Connect signal
	_analytics_button.connect("pressed", self, "_on_analytics_button_pressed")
	
	# Create stats panel (same as shop version)
	_create_analytics_panel()
	
	ModLoaderLog.info("Analytics button added to main menu", ANALYTATO_LOG)


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
		# Focus the close button
		var vbox = _analytics_panel.get_child(0)
		var close_btn = vbox.get_node_or_null("CloseButton")
		if close_btn:
			close_btn.grab_focus()


func _on_analytics_panel_close() -> void:
	if _analytics_panel:
		_analytics_panel.visible = false
		# Return focus to AT button
		if _analytics_button:
			_analytics_button.grab_focus()


func _input(event: InputEvent) -> void:
	# Allow ESC to close panel
	if event.is_action_pressed("ui_cancel") and _analytics_panel and _analytics_panel.visible:
		_on_analytics_panel_close()
		get_tree().set_input_as_handled()
