# res://mods-unpacked/Calico-ReloadUI/ui/Overlay.gd
extends Control
class_name ReloadOverlay

# Public API you can call from your mod:
# set_weapons([{ icon: Texture, cooldown: float, cooldown_max: float }, ...])
# update_cooldowns([{ cooldown: float }, ...])

var _container: HBoxContainer
var _bars: Array = []
var _weapons: Array = []

func _ready() -> void:
	_container = HBoxContainer.new()
	_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(_container)

func set_weapons(weapons: Array) -> void:
	_weapons = weapons.duplicate()
	_bars.clear()
	_container.queue_free()
	_container = HBoxContainer.new()
	_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_container.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	add_child(_container)

	for w in _weapons:
		var icon: Texture = w.get("icon")
		var slot = _make_icon_bar(icon)
		_container.add_child(slot)
		_bars.append(slot)

func update_cooldowns(states: Array) -> void:
	# states[i].cooldown pairs with _weapons[i].cooldown_max
	for i in range(_bars.size()):
		var max_cd: float = max(_weapons[i].get("cooldown_max", 1.0), 0.0001)
		var cur_cd: float = clamp(states[i].get("cooldown", 0.0), 0.0, max_cd)
		var remaining = cur_cd / max_cd # 0..1
		# Fill represents time remaining until fire: 1.0 = fully blocked
		_bars[i].min_value = 0.0
		_bars[i].max_value = 1.0
		_bars[i].value = remaining

func _make_icon_bar(icon: Texture) -> TextureProgress:
	var bar = TextureProgress.new()
	# Put the icon as the "under" texture; the "progress" layer is just color.
	bar.texture_under = icon
	bar.texture_progress = _make_solid_texture()  # 1x1 white
	bar.tint_progress = Color(0.1, 0.6, 1.0, 0.55) # semi-transparent overlay color
	bar.fill_mode = TextureProgress.FILL_TOP_TO_BOTTOM  # or FILL_BOTTOM_TO_TOP / RADIAL
	bar.custom_minimum_size = Vector2(64, 64)
	# Optional: keep square icons as the layout resizes
	bar.stretch_mode = TextureProgress.STRETCH_SCALE
	return bar

func _make_solid_texture() -> Texture:
	var img = Image.new()
	img.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color(1, 1, 1, 1))
	var tex = ImageTexture.new()
	tex.create_from_image(img)
	return tex
