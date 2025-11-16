# Calico-ReloadUI

Weapon cooldown visualization mod for Brotato.

## Features

- **Weapon Icons with Cooldown Overlays**: Displays weapon icons near the life/material UI with visual cooldown indicators
- **Color-Coded States**: 
  - Green = Ready to fire
  - Red = Currently firing
  - Orange = Cooling down
- **ModOptions Integration**: Configure visibility settings via ModOptions menu
- **Editor Mode Bugfix**: Fixes null reference crashes in challenge service

## Dependencies

- **Oudstand-ModOptions**: Provides settings UI for mod configuration

## Architecture

ReloadUI extends main.gd to inject weapon cooldown displays directly into the HUD.

## Configuration

Access settings via the "Reload UI" tab in ModOptions:

- **Show Weapon Icons**: Toggle weapon icon display on/off
- **Show Cooldown Overlay**: Toggle cooldown visualization on/off

## Technical Details

### Extension Points

- `extensions/main_extension.gd`: Main extension that injects weapon displays into HUD
- `extensions/singletons/challenge_service.gd`: Bugfix extension for editor mode

### Cooldown Detection

Uses live weapon instances from `player.current_weapons` to read runtime cooldown state:
- `weapon._current_cooldown`: Current cooldown timer (counts DOWN to 0)
- `weapon._current_cooldown_max`: Maximum cooldown duration
- Progress calculation: `1.0 - (current / max)` where 0.0 = just fired, 1.0 = ready

### State Priority

1. READY (green): Weapon is ready to fire
2. FIRING (red): Weapon is currently firing
3. COOLING (orange): Weapon is in cooldown

## Version History

- **1.0.4**: Added ModOptions integration and DamageMeter dependency
- **1.0.3**: Fixed cooldown direction (was counting backwards)
- **1.0.2**: Fixed state detection priority
- **1.0.1**: Initial cooldown visualization
- **1.0.0**: Base weapon icon display

## Credits

- **Calico**: ReloadUI development
- **Oudstand**: ModOptions framework and DamageMeter utilities
- **Brotato Modding Community**: ModLoader and ecosystem support
