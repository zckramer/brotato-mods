extends "res://main.gd"

# Extension to track enemy deaths for analytics AND show HUD overlay

const ANALYTATO_LOG = "Calico-Analytato"

var _tracker: Node = null
var _wave_active: bool = false
var _run_in_progress: bool = false
var _stats_label: Label = null

func _enter_tree() -> void:
	call_deferred("_init_analytics_tracking")
	call_deferred("_inject_stats_overlay")


func _init_analytics_tracking() -> void:
	# Get reference to analytics tracker
	var mod_loader = get_node_or_null("/root/ModLoader")
	if not mod_loader:
		ModLoaderLog.error("ModLoader not found", ANALYTATO_LOG)
		return
	
	var analytato_mod = mod_loader.get_node_or_null("Calico-Analytato")
	if not analytato_mod:
		ModLoaderLog.error("Calico-Analytato mod not found", ANALYTATO_LOG)
		return
	
	_tracker = analytato_mod.analytics_tracker
	if _tracker:
		ModLoaderLog.info("Analytics tracking hooked to Main - tracker found!", ANALYTATO_LOG)
	else:
		ModLoaderLog.error("Analytics tracker is null", ANALYTATO_LOG)


func _on_EntitySpawner_wave_started() -> void:
	._on_EntitySpawner_wave_started()
	_wave_active = true
	
	ModLoaderLog.info("Wave started - analytics tracking active", ANALYTATO_LOG)
	
	if _tracker:
		# Start new run on wave 1
		if RunData.current_wave == 1:
			var character_name = "Unknown"
			if RunData.players_data.size() > 0 and RunData.players_data[0].current_character:
				character_name = RunData.players_data[0].current_character.name
			_tracker.start_new_run(character_name)
			_run_in_progress = true
			ModLoaderLog.info("Started new run with character: %s" % character_name, ANALYTATO_LOG)
		
		_tracker.reset_wave_stats()


func _on_EntitySpawner_wave_ended() -> void:
	._on_EntitySpawner_wave_ended()
	_wave_active = false
	
	ModLoaderLog.info("Wave ended - analytics paused", ANALYTATO_LOG)
	
	if _tracker:
		_tracker.on_wave_complete()
		
		# Check if run ended (death or victory)
		if _is_run_lost or _is_run_won:
			var victory = _is_run_won
			_tracker.on_run_complete(victory)
			_run_in_progress = false
			ModLoaderLog.info("Run complete - Victory: %s" % victory, ANALYTATO_LOG)


func _exit_tree() -> void:
	# Save progress if player quits mid-run
	if _tracker and _run_in_progress:
		# Treat exit as incomplete run but still save the stats
		_tracker.on_run_complete(false)
		ModLoaderLog.info("Run exited early - saving progress", ANALYTATO_LOG)
	
	._exit_tree()


func _on_EntitySpawner_entity_spawned(entity) -> void:
	._on_EntitySpawner_entity_spawned(entity)
	
	# Connect to entity death signal for kill tracking
	if _tracker and entity and not entity.is_connected("died", self, "_on_entity_died"):
		var err = entity.connect("died", self, "_on_entity_died")
		if err != OK:
			ModLoaderLog.error("Failed to connect to entity died signal: %s" % err, ANALYTATO_LOG)
		else:
			ModLoaderLog.debug("Connected to entity death: %s" % entity.name, ANALYTATO_LOG)


func _on_entity_died(entity, _die_args) -> void:
	if not _tracker:
		ModLoaderLog.warning("Tracker is null in _on_entity_died", ANALYTATO_LOG)
		return
	
	if not _wave_active:
		ModLoaderLog.debug("Wave not active, ignoring death", ANALYTATO_LOG)
		return
	
	# Get enemy type from entity
	var enemy_type = "Unknown"
	if "my_id" in entity:
		enemy_type = entity.my_id
	elif "name" in entity:
		enemy_type = entity.name
	
	ModLoaderLog.info("Enemy killed: %s" % enemy_type, ANALYTATO_LOG)
	_tracker.on_enemy_killed(enemy_type)


func _inject_stats_overlay() -> void:
	# Create stats label for HUD
	_stats_label = Label.new()
	_stats_label.name = "AnalytatoStatsOverlay"
	_stats_label.rect_position = Vector2(10, 100)  # Top left
	_stats_label.add_color_override("font_color", Color(1.0, 0.7, 0.8, 0.9))  # Pink
	_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var hud = get_node_or_null("UI/HUD")
	if hud:
		hud.add_child(_stats_label)
		ModLoaderLog.info("Stats overlay injected into HUD", ANALYTATO_LOG)


func _process(_delta: float) -> void:
	._process(_delta)
	_update_stats_display()


func _update_stats_display() -> void:
	if not _stats_label or not _tracker or not is_instance_valid(_stats_label):
		return
	
	# Only show during active run and wave
	if not _run_in_progress or not _wave_active:
		_stats_label.visible = false
		return
	
	_stats_label.visible = true
	
	var current_run = _tracker.get_current_run_stats()
	
	# Count entities and projectiles for real-time stats
	var entity_spawner = get_node_or_null("EntitySpawner")
	var enemy_count = entity_spawner.enemies.size() if entity_spawner else 0
	
	var projectile_container = get_node_or_null("Projectiles")
	var projectile_count = projectile_container.get_child_count() if projectile_container else 0
	
	_stats_label.text = "Kills: %d | Enemies: %d | Projectiles: %d" % [current_run.kills, enemy_count, projectile_count]
