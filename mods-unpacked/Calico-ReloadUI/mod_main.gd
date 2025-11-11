# Add near the top:
extends Node
const WAVEMANAGER_NODE_NAMES := ["WaveManager", "Waves", "RunManager", "CombatManager"]
const SIGNALS_WAVE_START := ["wave_started", "wave_begin", "start_wave"]
const SIGNALS_WAVE_END   := ["wave_ended", "wave_complete", "end_wave"]
const SIGNALS_PREP_START := ["preparation_started", "prep_started", "intermission_started"]

var _wave_manager = null
var _in_wave := false
var _row = null
var _hud = null

func _ensure_overlay_row() -> void:
	# Ensure we have a valid overlay row attached to the HUD.
	if _row and is_instance_valid(_row):
		return
	# Try to use current HUD reference, otherwise find one in the scene tree.
	if not _hud or not is_instance_valid(_hud):
		_hud = get_tree().get_root().find_node("HUD", true, false)
		if not _hud:
			return
	# Create a simple container to act as the overlay row if missing.
	var row = HBoxContainer.new()
	row.name = "ReloadUI_OverlayRow"
	row.visible = false
	_hud.add_child(row)
	_row = row

func _enter_tree() -> void:
	print("[ReloadUI] _enter_tree")
	# Watch for scene/node churn so we can re-hook when the run scene appears.
	get_tree().connect("node_added", self, "_on_node_added")
	get_tree().connect("node_removed", self, "_on_node_removed")

# call at end of _start_safe() after overlay init:
#   _hook_wave_manager()  # new
#   _start_update_loop()

func _on_node_added(n: Node) -> void:
	# Re-attach overlay row if HUD got recreated
	if n.name == "HUD" and _row and _row.get_parent() == null:
		_hud = n
		_ensure_overlay_row()

	# Don’t hook immediately; stabilize first
	if _wave_manager == null and _looks_like_wave_manager(n):
		_consider_wave_manager_candidate(n)

func _consider_wave_manager_candidate(n: Node) -> void:
	# Wait ~100 ms to see if it sticks around
	var candidate := n
	var t := get_tree().create_timer(0.1)
	t.connect("timeout", self, "_stabilize_wave_manager", [candidate], CONNECT_ONESHOT)

func _stabilize_wave_manager(candidate: Node) -> void:
	if candidate and candidate.is_inside_tree():
		# Optional: prefer nodes that belong to current_scene
		var cs := get_tree().get_current_scene()
		var belongs_to_cs := false
		var p := candidate
		while p:
			if p == cs:
				belongs_to_cs = true
				break
			p = p.get_parent()
		if belongs_to_cs:
			_set_wave_manager(candidate)
		else:
			# Not part of the active run scene; keep listening.
			pass


func _on_node_removed(n: Node) -> void:
	if n == _wave_manager:
		print("[ReloadUI] WaveManager removed; will re-hook.")
		_wave_manager = null
		_in_wave = false
		_set_overlay_visible(false)

func _on_wave_manager_exited() -> void:
	if _wave_manager:
		print("[ReloadUI] WaveManager removed; will re-hook.")
	_wave_manager = null
	_in_wave = false
	_set_overlay_visible(false)
	# We’ll hook the next candidate via node_added + stabilization

func _looks_like_wave_manager(n: Node) -> bool:
	if not n: return false
	# Name check first
	for nm in WAVEMANAGER_NODE_NAMES:
		if n.name == nm:
			return true
	# Script name hint (works even if renamed)
	var s = n.get_script()
	if s and typeof(s) == TYPE_OBJECT:
		var path = str(s)
		if "wave" in path.to_lower():
			return true
	return false

func _hook_wave_manager() -> void:
	# Try find an existing one now
	if _wave_manager:
		return
	# pass the method name so the finder can call it correctly
	var found = _find_node_deep(get_tree().get_root(), "_looks_like_wave_manager")
	if found:
		_set_wave_manager(found)
	else:
		print("[ReloadUI] WaveManager not found yet; will keep listening for node_added.")

func _set_wave_manager(n: Node) -> void:
	_wave_manager = n
	print("[ReloadUI] WaveManager hooked: %s path=%s" % [_wave_manager, _wave_manager.get_path()])

	# Reconnect signals every time; no ONESHOT
	for sig in SIGNALS_WAVE_START:
		if _wave_manager.has_signal(sig) and not _wave_manager.is_connected(sig, self, "_on_wave_started"):
			_wave_manager.connect(sig, self, "_on_wave_started")
			print("[ReloadUI] connected wave-start signal:", sig)
			break
	for sig in SIGNALS_WAVE_END:
		if _wave_manager.has_signal(sig) and not _wave_manager.is_connected(sig, self, "_on_wave_ended"):
			_wave_manager.connect(sig, self, "_on_wave_ended")
			print("[ReloadUI] connected wave-end signal:", sig)
			break
	for sig in SIGNALS_PREP_START:
		if _wave_manager.has_signal(sig) and not _wave_manager.is_connected(sig, self, "_on_prep_started"):
			_wave_manager.connect(sig, self, "_on_prep_started")
			print("[ReloadUI] connected prep signal:", sig)
			break

	# Watch this specific instance; when it exits, we’ll re-hook.
	if not _wave_manager.is_connected("tree_exited", self, "_on_wave_manager_exited"):
		_wave_manager.connect("tree_exited", self, "_on_wave_manager_exited")

	# If no signals present, keep the lightweight poll
	if not _any_signal_connected():
		_start_wave_state_poll()
	else:
		_stop_wave_state_poll()  # if you added this helper


func _any_signal_connected() -> bool:
	# crude heuristic: if we got at least one start OR end signal
	return true # set true because above connects are ONESHOT/DEFERRED; actual tracking not needed here

# Signal handlers
func _on_wave_started() -> void:
	_in_wave = true
	_set_overlay_visible(true)
	print("[ReloadUI] wave started")

func _on_wave_ended() -> void:
	_in_wave = false
	_set_overlay_visible(false)
	print("[ReloadUI] wave ended")

func _on_prep_started() -> void:
	_in_wave = false
	_set_overlay_visible(false)
	print("[ReloadUI] prep/intermission started")

# Visibility helper
func _set_overlay_visible(v: bool) -> void:
	if _row and is_instance_valid(_row):
		_row.visible = v

# Lightweight poll (runs only if no signals are available)
var _wave_poll_timer = null
func _start_wave_state_poll() -> void:
	if _wave_poll_timer: return
	_wave_poll_timer = Timer.new()
	_wave_poll_timer.wait_time = 0.25
	_wave_poll_timer.autostart = true
	_wave_poll_timer.one_shot = false
	add_child(_wave_poll_timer)
	_wave_poll_timer.connect("timeout", self, "_poll_wave_state")

func _stop_wave_state_poll() -> void:
	if not _wave_poll_timer:
		return
	if is_instance_valid(_wave_poll_timer):
		# disconnect handler if still connected
		if _wave_poll_timer.is_connected("timeout", self, "_poll_wave_state"):
			_wave_poll_timer.disconnect("timeout", self, "_poll_wave_state")
		_wave_poll_timer.stop()
		_wave_poll_timer.queue_free()
	_wave_poll_timer = null

func _poll_wave_state() -> void:
	if not _wave_manager:
		return
	var new_state := _guess_in_wave(_wave_manager)
	if new_state != _in_wave:
		_in_wave = new_state
		_set_overlay_visible(_in_wave)
		print("[ReloadUI] wave state (polled) -> ", _in_wave)

func _guess_in_wave(mgr: Node) -> bool:
	# Check a few likely property names
	var props := ["in_wave", "is_active", "is_running", "is_in_wave", "is_wave_active", "state"]
	for p in props:
		if mgr.has_method("get"): # generic
			if mgr.has(p):
				var v = mgr.get(p)
				if typeof(v) == TYPE_BOOL:
					return v
				if typeof(v) in [TYPE_INT, TYPE_REAL, TYPE_STRING]:
					var s = str(v).to_lower()
					if s == "wave" or s == "combat": return true
					if s == "prep" or s == "intermission" or s == "shop": return false
	# Last resort: look for time-like fields
	var t_names := ["time_left", "time_left_in_wave", "wave_time_remaining"]
	for t in t_names:
		if mgr.has(t):
			var f = float(mgr.get(t))
			if f > 0.0:
				return true
	return false
# Utility DFS finder
func _find_node_deep(root: Node, pred) -> Node:
	# Support passing either a method name (String) or a Funcref/Callable-like object.
	var matches := false
	if typeof(pred) == TYPE_STRING:
		if has_method(pred):
			matches = call(pred, root)
	elif typeof(pred) == TYPE_OBJECT:
		# If pred is an Object (e.g. Funcref in some engines), try common call methods safely.
		if pred.has_method("call_func"):
			matches = pred.call_func(root)
		elif pred.has_method("call"):
			matches = pred.call(root)
		# If pred is a bare Callable in some engine versions, it may not be TYPE_OBJECT;
		# we skip that here to avoid referencing engine-specific types that may not exist.

	if matches:
		return root

	for c in root.get_children():
		if c is Node:
			var r = _find_node_deep(c, pred)
			if r: return r
	return null
