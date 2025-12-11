# Analytato

**Combat Analytics & Statistics Tracker for Brotato**

## Overview

Analytato provides detailed combat statistics and analytics during gameplay. Track your performance with real-time metrics including:

- **Kill Tracking**: Enemies killed by type
- **Damage Tracking**: Total damage dealt and damage sources
- **Dodge Tracking**: Number of successful dodges
- **Projectile Tracking**: Bullets fired, hits, misses, and pierces _(performance intensive)_

## Features

### Phase 1 (Current)

- ✅ Boilerplate and configuration system
- 🚧 Basic kill tracking by enemy type
- 🚧 Total damage dealt tracking
- 🚧 Simple overlay display

### Phase 2 (Planned)

- ⏳ Dodge counter and effectiveness
- ⏳ Damage source attribution
- ⏳ Per-wave statistics

### Phase 3 (Future)

- ⏳ Bullet-level tracking (fired/hit/miss)
- ⏳ Pierce tracking
- ⏳ Advanced analytics UI

## Configuration

Accessible via **ModOptions** (if installed):

- `enable_kill_tracking`: Track enemies killed by type
- `enable_damage_tracking`: Track damage dealt and sources
- `enable_dodge_tracking`: Track dodge count
- `enable_projectile_tracking`: Track individual bullets _(warning: performance impact)_
- `show_stats_overlay`: Display real-time stats during combat
- `stats_position`: Overlay position (top_left, top_right, bottom_left, bottom_right)

## Installation

1. Install via Thunderstore or manually place in `mods-unpacked/Calico-Analytato/`
2. Launch Brotato
3. Configure settings via ModOptions (optional)

## Compatibility

- **Mod Loader**: 6.0.0+
- **Game Version**: All versions
- **Dependencies**: None (ModOptions recommended for configuration)

## Performance Notes

- Kill and damage tracking have minimal performance impact
- **Projectile tracking is performance-intensive** and disabled by default
- Consider disabling overlay on low-end systems

## Development

This mod is under active development. Features are being implemented in phases to ensure stability and performance.

### Architecture

- Extensions hook into game classes (Entity, Projectile, Player)
- Statistics stored in singleton pattern
- UI overlay updates per-frame during combat
- Data reset per-wave or per-run based on tracking mode

## Credits

**Author**: Calico  
**License**: MIT

## Contributing

Feedback and suggestions welcome! This is a learning project exploring Brotato's modding capabilities.
