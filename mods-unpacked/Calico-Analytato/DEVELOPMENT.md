# Analytato Development Documentation

## Project Overview

Analytato is a combat analytics mod for Brotato that tracks detailed statistics during gameplay.

## Architecture

### Core Components

1. **mod_main.gd** - Entry point, configuration management
2. **extensions/** - Game class extensions for tracking hooks
3. **singletons/** - Global state management (stats storage)
4. **ui/** - Overlay display components

### Planned Extensions

```
extensions/
├── entity_extension.gd        # Hook enemy deaths for kill tracking
├── player_extension.gd        # Hook dodge events
├── projectile_extension.gd    # Hook bullet events (Phase 3)
└── singletons/
    └── analytics_tracker.gd   # Central stats storage and calculation
```

## Development Phases

### Phase 1: Foundation (Current)

- [x] Boilerplate structure
- [ ] Analytics tracker singleton
- [ ] Basic kill tracking
- [ ] Simple overlay UI
- [ ] Wave reset logic

### Phase 2: Core Stats

- [ ] Dodge tracking
- [ ] Damage source attribution
- [ ] Enhanced overlay with categories
- [ ] Per-wave vs per-run modes

### Phase 3: Advanced Analytics

- [ ] Projectile-level tracking
- [ ] Pierce tracking
- [ ] Detailed UI panel
- [ ] Export/save statistics

## Configuration System

Settings are stored via ModLoaderConfig and exposed through ModOptions:

```gdscript
ModLoaderConfig.get_setting(MOD_ID, key, default_value)
ModLoaderConfig.set_setting(MOD_ID, key, value)
```

## Performance Considerations

- **Kill tracking**: ~10-50 events/wave (low impact)
- **Damage tracking**: ~100-500 events/wave (low-medium impact)
- **Dodge tracking**: ~5-20 events/wave (negligible impact)
- **Projectile tracking**: ~1000-5000 events/wave (HIGH impact)

Projectile tracking requires careful optimization:

- Object pooling for tracking data
- Batch updates instead of per-frame
- Consider sampling (track 1 in N bullets)

## Testing Strategy

1. Enable one tracking feature at a time
2. Test with different character builds (slow vs fast weapons)
3. Monitor frame rate with F3 debug overlay
4. Test wave 20+ for performance under load

## Code Style

- Follow Brotato's naming conventions
- Use `ModLoaderLog` for all logging
- Prefix private functions with underscore
- Document performance-critical sections
- Include TODO comments for deferred work

## Useful Game APIs (from WL analysis)

```gdscript
# Runtime state queries
RunData.get_player_effect(key, player_index)
RunData.tracked_item_effects[player_index]
Utils.get_stat(key, player_index)

# Likely useful for tracking
RunData.current_wave
RunData.get_player_level(player_index)
# Enemy death signals (TBD - need to investigate)
# Projectile hit signals (TBD - need to investigate)
```

## Next Steps

1. Create `analytics_tracker.gd` singleton
2. Extend entity death to hook kill events
3. Build minimal overlay UI
4. Test in-game and iterate
