# Analytato Data Model

## Source of Truth

All analytics data follows this three-tier structure:

### 1. Wave Stats (Resets each wave)

```gdscript
{
    "kills": int,
    "damage_dealt": int,
    "dodges": int
}
```

### 2. Current Run Stats (Resets each run)

```gdscript
{
    "kills": int,  # Total kills this run
    "damage_dealt": int,
    "dodges": int,
    "waves_completed": int,
    "character": String,
    "start_time": int  # Unix timestamp
}
```

### 3. All-Time Stats (Persists forever)

```gdscript
{
    "total_runs": int,
    "total_kills": int,
    "total_damage": int,
    "total_dodges": int,
    "total_waves": int,
    "most_kills_single_run": int,
    "most_damage_single_run": int,
    "highest_wave_reached": int,
    "favorite_character": String
}
```

## Display Table Format

| Stat            | Current Run                 | This Wave               | All Time                        |
| --------------- | --------------------------- | ----------------------- | ------------------------------- |
| Kills           | current_run.kills           | wave_stats.kills        | all_time.total_kills            |
| Damage Dealt    | current_run.damage_dealt    | wave_stats.damage_dealt | all_time.total_damage           |
| Dodges          | current_run.dodges          | wave_stats.dodges       | all_time.total_dodges           |
| Waves Completed | current_run.waves_completed | -                       | all_time.total_waves            |
| Total Runs      | -                           | -                       | all_time.total_runs             |
| Best Kill Run   | -                           | -                       | all_time.most_kills_single_run  |
| Best Damage Run | -                           | -                       | all_time.most_damage_single_run |
| Highest Wave    | -                           | -                       | all_time.highest_wave_reached   |

## CSV Export Format

```
Stat,Value
Total Runs,{all_time.total_runs}
Total Kills,{all_time.total_kills}
Total Damage,{all_time.total_damage}
Total Dodges,{all_time.total_dodges}
Total Waves,{all_time.total_waves}
Most Kills (Single Run),{all_time.most_kills_single_run}
Most Damage (Single Run),{all_time.most_damage_single_run}
Highest Wave Reached,{all_time.highest_wave_reached}
Favorite Character,{all_time.favorite_character}
```

## Notes

- All counters are integers
- Character name is stored per-run and as "favorite" in all-time
- Wave stats reset at wave start
- Run stats reset at run start (wave 1)
- All-time stats only update when run completes
