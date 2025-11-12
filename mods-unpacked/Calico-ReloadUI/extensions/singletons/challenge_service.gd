## res://mods-unpacked/Calico-ReloadUI/extensions/singletons/challenge_service.gd
extends "res://singletons/challenge_service.gd"

# FIX: Patch the _sync_character_challenge method to handle null save data
# This prevents crashes when running from Godot editor or with corrupted saves
func _sync_character_challenge(challenge: ChallengeData) -> void :
	var char_id = challenge.my_id.replace("chal_", "character_")
	for zone_id in [0, 1]:
		var diff_info = ProgressData.get_character_difficulty_info(char_id, zone_id)
		
		# BUGFIX: Safety check for null save data
		if diff_info == null or diff_info.max_difficulty_beaten == null:
			print("ReloadUI: Skipping challenge sync for ", char_id, " zone ", zone_id, " (missing save data)")
			continue
		
		var diff_score = diff_info.max_difficulty_beaten
		if diff_score.difficulty_value >= 0:
			if Platform.get_type() == PlatformType.STEAM:
				if zone_id == 0:
					Platform.complete_challenge(challenge.my_id)
				elif zone_id == 1:
					Platform.complete_challenge(challenge.my_id + "_abyss")
			else:
				Platform.complete_challenge(challenge.my_id)
