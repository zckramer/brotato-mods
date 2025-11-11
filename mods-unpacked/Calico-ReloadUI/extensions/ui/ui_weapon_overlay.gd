#extends CanvasLayer
## Godot 3.x compatible overlay showing weapon icons with a cooldown fill.
#
## ------------ Configuration ------------
#export(String, "topleft", "topright") var anchor_corner = "topleft"
#export(Vector2) var overlay_offset = Vector2(16, 96)   # renamed from "offset" to avoid clash with CanvasLayer.offset
#export(Vector2) var icon_size = Vector2(42, 42)
#export(int) var icon_spacing = 6
#export(int) var max_icons_per_row = 6
#export(Vector2) var panel_padding = Vector2(10, 10)
## --------------------------------------
#
## Resolvers injected via FuncRef (Godot 3.x)
#var _resolve_player_node : FuncRef = null
#var _resolve_run_data_dict : FuncRef = null
#
## Root UI
#var _panel : Panel = null
#var _grid  : Control = null
#
## Internal model cache
#var _weapon_nodes  = []   # live weapon nodes or descriptors
#var _weapon_entries = []  # [{container, weapon, icon_rect, fill_rect, cooldown_max}, ...]
#
## Icon getters (FuncRef list in 3.x)
#var _weapon_icon_getters = []
#
## Re-scan timers
#var _rescan_accum = 0.0
#const RESCAN_INTERVAL = 0.5
#
#func _ready() -> void:
#	layer = 60
#	set_process(true)
#
#	_build_ui_shell()
#	_setup_icon_getters()
#
#	_refresh_weapon_sources()
#	_rebuild_icons()
#
#func set_player_resolvers(player_node_resolver: FuncRef, run_data_resolver: FuncRef) -> void:
#	_resolve_player_node = player_node_resolver
#	_resolve_run_data_dict = run_data_resolver
#
#func _process(delta: float) -> void:
#	_update_cooldown_fills(delta)
#
#	_rescan_accum += delta
#	if _rescan_accum >= RESCAN_INTERVAL:
#		_rescan_accum = 0.0
#		if _refresh_weapon_sources():
#			_rebuild_icons()
#
## ---------------- UI construction ----------------
#
#func _build_ui_shell() -> void:
#	_panel = Panel.new()
#	_panel.name = "WeaponOverlayPanel"
#	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
#	add_child(_panel)
#
#	_grid = Control.new()
#	_grid.name = "IconFlow"
#	_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
#	_panel.add_child(_grid)
#
#	_layout_panel()
#
#func _layout_panel() -> void:
#	match anchor_corner:
#		"topleft":
#			_panel.anchor_left = 0; _panel.anchor_top = 0
#			_panel.anchor_right = 0; _panel.anchor_bottom = 0
#			_panel.margin_left = overlay_offset.x
#			_panel.margin_top = overlay_offset.y
#		"topright":
#			_panel.anchor_left = 1; _panel.anchor_top = 0
#			_panel.anchor_right = 1; _panel.anchor_bottom = 0
#			_panel.margin_right = -overlay_offset.x
#			_panel.margin_top = overlay_offset.y
#		_:
#			_panel.anchor_left = 0; _panel.anchor_top = 0
#			_panel.margin_left = overlay_offset.x
#			_panel.margin_top = overlay_offset.y
#
## ---------------- Icon getters (3.x: FuncRef) ----------------
#
#func _setup_icon_getters() -> void:
#	# Register one or more strategies as FuncRefs (no inline lambdas in 3.x).
#	_weapon_icon_getters = [
#		funcref(self, "_getter_icon_default")
#	]
#
#func _getter_icon_default(weapon) -> Texture:
#	if weapon == null:
#		return null
#	# Common fields: icon, texture, get_icon()
#	if "icon" in weapon and weapon.icon is Texture:
#		return weapon.icon
#	if "texture" in weapon and weapon.texture is Texture:
#		return weapon.texture
#	if typeof(weapon) == TYPE_OBJECT and weapon.has_method("get_icon"):
#		var t = weapon.call("get_icon")
#		if t is Texture:
#			return t
#	return null
#
## ---------------- Data refresh ----------------
#
#func _refresh_weapon_sources() -> bool:
#	var prev_count = _weapon_nodes.size()
#	_weapon_nodes.clear()
#
#	var player = _safe_call_funcref(_resolve_player_node)
#	if player:
#		# 1) children likely to be weapon nodes
#		for c in player.get_children():
#			if c is Node:
#				if _looks_like_weapon_node(c):
#					_weapon_nodes.append(c)
#		# 2) method to enumerate weapons, if exposed
#		if player.has_method("get_weapons"):
#			var list = player.call("get_weapons")
#			if typeof(list) == TYPE_ARRAY:
#				for w in list:
#					if w and _weapon_nodes.find(w) == -1:
#						_weapon_nodes.append(w)
#
#	# Fallback: RunData descriptors
#	if _weapon_nodes.size() == 0:
#		var run = _safe_call_funcref(_resolve_run_data_dict)
#		if typeof(run) == TYPE_DICTIONARY:
#			if run.has("weapons") and typeof(run["weapons"]) == TYPE_ARRAY:
#				for desc in run["weapons"]:
#					_weapon_nodes.append(desc)
#
#	return prev_count != _weapon_nodes.size()
#
#func _looks_like_weapon_node(n: Node) -> bool:
#	if n.name.findn("weapon") != -1 or n.name.findn("Weapon") != -1:
#		return true
#	if "cooldown" in n or "cooldown_max" in n or "cooldown_remaining" in n:
#		return true
#	if n.has_method("get_cooldown_ratio") or n.has_method("get_cooldown_remaining"):
#		return true
#	return false
#
## ---------------- Icons & overlays ----------------
#
#func _rebuild_icons() -> void:
#	for child in _grid.get_children():
#		child.queue_free()
#	_weapon_entries.clear()
#
#	var x = panel_padding.x
#	var y = panel_padding.y
#	var col = 0
#	var row_h = icon_size.y
#
#	var count = _weapon_nodes.size()
#	for i in range(count):
#		var w = _weapon_nodes[i]
#		var entry = _create_icon_entry(w)
#		if entry == null:
#			continue
#
#		entry["container"].rect_position = Vector2(x, y)
#		entry["container"].rect_size = icon_size
#
#		_grid.add_child(entry["container"])
#		_weapon_entries.append(entry)
#
#		col += 1
#		if col >= max_icons_per_row:
#			col = 0
#			x = panel_padding.x
#			y += row_h + icon_spacing
#		else:
#			x += icon_size.x + icon_spacing
#
#	var columns = min(max_icons_per_row, max(1, _weapon_entries.size()))
#	var width = icon_size.x * columns + icon_spacing * (columns - 1) + panel_padding.x * 2
#	var rows = int(ceil(float(max(1, _weapon_entries.size())) / float(max_icons_per_row)))
#	var height = rows * icon_size.y + (rows - 1) * icon_spacing + panel_padding.y * 2
#	_panel.rect_size = Vector2(width, height)
#
#func _create_icon_entry(weapon_ref) -> Dictionary:
#	var box = Control.new()
#	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
#	box.rect_min_size = icon_size
#
#	var icon_tex = _resolve_weapon_icon(weapon_ref)
#	var icon = TextureRect.new()
#	icon.name = "Icon"
#	icon.expand = true
#	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
#	icon.texture = icon_tex
#	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
#	box.add_child(icon)
#
#	var fill = ColorRect.new()
#	fill.name = "CooldownFill"
#	fill.color = Color(0, 0, 0, 0.45)
#	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
#	fill.rect_position = Vector2(0, 0)
#	fill.rect_size = Vector2(icon_size.x, 0)
#	box.add_child(fill)
#
#	var entry = {
#		"container": box,
#		"weapon": weapon_ref,
#		"icon_rect": icon,
#		"fill_rect": fill,
#		"cooldown_max": _get_cooldown_max(weapon_ref)
#	}
#	return entry
#
#func _resolve_weapon_icon(weapon_ref) -> Texture:
#	for i in range(_weapon_icon_getters.size()):
#		var fr : FuncRef = _weapon_icon_getters[i]
#		if fr and fr.is_valid():
#			var t = fr.call_func(weapon_ref)
#			if t is Texture:
#				return t
#	return null
#
## ---------------- Cooldown updates ----------------
#
#func _update_cooldown_fills(_delta: float) -> void:
#	for i in range(_weapon_entries.size()):
#		var e = _weapon_entries[i]
#		var ratio = _get_cooldown_ratio(e["weapon"], e["cooldown_max"])
#		ratio = clamp(ratio, 0.0, 1.0)
#		var fill_h = icon_size.y * ratio
#		e["fill_rect"].rect_position = Vector2(0, 0)
#		e["fill_rect"].rect_size = Vector2(icon_size.x, fill_h)
#
#func _get_cooldown_max(weapon_ref) -> float:
#	if weapon_ref == null:
#		return 1.0
#	if "cooldown_max" in weapon_ref and (typeof(weapon_ref.cooldown_max) == TYPE_INT or typeof(weapon_ref.cooldown_max) == TYPE_REAL):
#		return max(0.001, float(weapon_ref.cooldown_max))
#	if typeof(weapon_ref) == TYPE_OBJECT and weapon_ref.has_method("get_cooldown_max"):
#		var v = weapon_ref.call("get_cooldown_max")
#		if typeof(v) == TYPE_INT or typeof(v) == TYPE_REAL:
#			return max(0.001, float(v))
#	if "attack_cooldown" in weapon_ref and (typeof(weapon_ref.attack_cooldown) == TYPE_INT or typeof(weapon_ref.attack_cooldown) == TYPE_REAL):
#		return max(0.001, float(weapon_ref.attack_cooldown))
#	return 1.0
#
#func _get_cooldown_ratio(weapon_ref, cooldown_max_hint: float) -> float:
#	if weapon_ref == null:
#		return 0.0
#
#	if "cooldown_remaining" in weapon_ref and (typeof(weapon_ref.cooldown_remaining) == TYPE_INT or typeof(weapon_ref.cooldown_remaining) == TYPE_REAL):
#		var maxv = 0.0
#		if cooldown_max_hint > 0.0:
#			maxv = cooldown_max_hint
#		else:
#			maxv = _get_cooldown_max(weapon_ref)
#		return float(weapon_ref.cooldown_remaining) / maxv
#
#	if typeof(weapon_ref) == TYPE_OBJECT and weapon_ref.has_method("get_cooldown_ratio"):
#		var r = weapon_ref.call("get_cooldown_ratio")
#		if typeof(r) == TYPE_INT or typeof(r) == TYPE_REAL:
#			return float(r)
#
#	if typeof(weapon_ref) == TYPE_OBJECT and weapon_ref.has_method("get_cooldown_remaining"):
#		var rem = weapon_ref.call("get_cooldown_remaining")
#		if typeof(rem) == TYPE_INT or typeof(rem) == TYPE_REAL:
#			var maxv2 = 0.0
#			if cooldown_max_hint > 0.0:
#				maxv2 = cooldown_max_hint
#			else:
#				maxv2 = _get_cooldown_max(weapon_ref)
#			return float(rem) / maxv2
#
#	if "time_since_last_attack" in weapon_ref and (typeof(weapon_ref.time_since_last_attack) == TYPE_INT or typeof(weapon_ref.time_since_last_attack) == TYPE_REAL):
#		var maxv3 = 0.0
#		if cooldown_max_hint > 0.0:
#			maxv3 = cooldown_max_hint
#		else:
#			maxv3 = _get_cooldown_max(weapon_ref)
#		var rem2 = max(0.0, maxv3 - float(weapon_ref.time_since_last_attack))
#		return rem2 / maxv3
#
#	return 0.0
#
## ---------------- Utilities ----------------
#
#func _safe_call_funcref(fr: FuncRef):
#	if fr and fr.is_valid():
#		return fr.call_func()
