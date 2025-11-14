extends Node
class_name CooldownHelper

# Shared utility for calculating weapon cooldown state
# Can be used by multiple mods without coupling

enum CooldownState {
	READY,      # Weapon can fire (cur_cd <= 0)
	COOLING,    # Counting down from max to 0
	FIRING      # Actively shooting (is_shooting flag)
}

# Calculate cooldown progress for a weapon
# Returns: Dictionary with {state, progress, cur_cd, max_cd}
static func get_weapon_cooldown_info(weapon) -> Dictionary:
	var result = {
		"state": CooldownState.READY,
		"progress": 1.0,  # 0.0 = just fired, 1.0 = ready
		"cur_cd": 0.0,
		"max_cd": 0.0
	}
	
	if not is_instance_valid(weapon):
		return result
	
	# Get max cooldown
	var max_cd = 0.0
	if "current_stats" in weapon and weapon.current_stats and "cooldown" in weapon.current_stats:
		max_cd = float(weapon.current_stats.cooldown)
	
	# Get current cooldown
	var cur_cd = 0.0
	if "_current_cooldown" in weapon:
		cur_cd = float(weapon._current_cooldown)
	
	# Get shooting state
	var is_shooting = ("_is_shooting" in weapon and weapon._is_shooting)
	
	result.cur_cd = cur_cd
	result.max_cd = max_cd
	
	if max_cd <= 0.0:
		# No cooldown stat - always ready unless shooting
		result.state = CooldownState.FIRING if is_shooting else CooldownState.READY
		result.progress = 1.0
		return result
	
	# _current_cooldown counts DOWN from ~max_cd to 0
	# When cur_cd reaches 0, weapon is ready to fire
	# Progress: 0.0 = just fired (full cooldown remaining), 1.0 = ready (no cooldown remaining)
	result.progress = 1.0 - clamp(cur_cd / max_cd, 0.0, 1.0)
	
	# Determine state
	if cur_cd <= 0.0:
		result.state = CooldownState.READY
	elif is_shooting:
		result.state = CooldownState.FIRING
	else:
		result.state = CooldownState.COOLING
	
	return result

# Check if a source is a weapon (has cooldown tracking)
static func is_weapon_source(source) -> bool:
	if not is_instance_valid(source):
		return false
	
	# Weapons have dmg_dealt_last_wave property
	return "dmg_dealt_last_wave" in source

# Get cooldown color for overlay (can be customized)
static func get_cooldown_color(state: int) -> Color:
	match state:
		CooldownState.READY:
			return Color(0.0, 1.0, 0.0, 0.4)  # Green
		CooldownState.FIRING:
			return Color(1.0, 1.0, 0.0, 0.6)  # Yellow flash
		CooldownState.COOLING:
			return Color(1.0, 0.0, 0.0, 0.6)  # Red
		_:
			return Color(1.0, 1.0, 1.0, 0.0)  # Transparent
