# Third-Party Mod Analysis Workflow

**CRITICAL**: This workflow is for **READ-ONLY ANALYSIS** of other developers' mods. **NEVER MODIFY THEIR CODE.**

---

## Purpose

When importing third-party mods into the repository for reference, learning, or compatibility analysis, we must:

1. **Preserve their work exactly as-is** (no modifications)
2. **Document our findings** without touching their files
3. **Learn from their patterns** for our own mods
4. **Track compatibility** between mods

---

## Workflow: Analyzing a Third-Party Mod

### Step 1: Import on Separate Branch

```powershell
# Create analysis branch (never modify main with third-party code)
git checkout -b import/ModName

# Files will be in mods-unpacked/ as usual
# Example: mods-unpacked/_wl-ImprovedTooltips/
```

### Step 2: Update .gitignore (Read-Only Tracking)

Add the third-party mod directory to `.gitignore` whitelist **for reference only**:

```gitignore
# Third-party mod analysis (READ-ONLY - DO NOT MODIFY)
!mods-unpacked/_wl-ImprovedTooltips/
!mods-unpacked/_wl-ImprovedTooltips/**

# Note: Still ignore auto-generated files
mods-unpacked/**/*.import
mods-unpacked/**/*.translation
```

**⚠️ CRITICAL**: Add a comment marking it as READ-ONLY to prevent accidental edits.

### Step 3: Initial Analysis Checklist

Review these aspects systematically:

#### 📋 Metadata Analysis

- [ ] **Author**: Who created this mod?
- [ ] **Version**: What version is this?
- [ ] **Dependencies**: What does it require?
- [ ] **Compatibility**: Game version, ModLoader version
- [ ] **Purpose**: What does this mod do?

#### 📂 Structure Analysis

- [ ] **File Organization**: How is it structured?
- [ ] **Extension Pattern**: Which files does it extend?
- [ ] **Resource Location**: Where are assets/translations?
- [ ] **Version Management**: Does it support multiple game versions?

#### 🔧 Technical Patterns

- [ ] **Extension Strategy**: How does it inject code?
- [ ] **Game Systems Used**: What systems does it interact with?
- [ ] **Data Access**: How does it read/modify game data?
- [ ] **Performance**: Update frequency, caching strategies
- [ ] **UI Modifications**: How does it alter UI?

#### 🧩 Code Patterns Worth Learning

- [ ] **Novel Techniques**: Approaches we haven't used
- [ ] **Problem Solutions**: How they solved similar problems
- [ ] **API Usage**: New APIs or clever uses of known APIs
- [ ] **Gotchas Avoided**: Problems they handled that we should note

### Step 4: Document Findings

Create analysis document in **our mod's directory** (not theirs):

```
mods-unpacked/Calico-ReloadUI/ANALYSIS_ThirdPartyModName.md
```

**Template**:

```markdown
# Analysis: [Mod Name] by [Author]

**Date**: [Date]
**Version Analyzed**: [Version]
**Purpose**: Brief description

## Overview

High-level summary of what this mod does and how.

## Structure

File organization and extension strategy.

## Technical Patterns

### Pattern 1: [Name]

**What**: Description
**Where**: File paths
**How**: Code explanation
**Learnings**: What we can apply to our work

### Pattern 2: [Name]

...

## Systems Interactions

Which game systems this mod touches and how.

## Compatibility Notes

- Works with: [Other mods, game versions]
- Conflicts with: [Known issues]
- Relevant to ReloadUI: [How it relates to our work]

## Code Snippets (For Learning)

### Example 1: [Technique]

\`\`\`gdscript

# REFERENCE ONLY - From ThirdPartyMod (DO NOT COPY WITHOUT ATTRIBUTION)

# Shows: [What this demonstrates]

[code snippet]
\`\`\`

**Learnings**: [What we learned from this]

## Potential Applications

How we might apply these patterns to ReloadUI (in our own implementation).

## References

- Mod Source: [Link if available]
- Author: [Credit]
- License: [If specified]
```

### Step 5: Update Game Systems Documentation

If the third-party mod reveals **new game systems or patterns**, document them:

**Add to GAME_SYSTEMS.md**:

```markdown
## [System Name]

### Overview

[How the system works]

### Pattern Discovered

**Source**: Observed in [ThirdPartyMod] by [Author]
**Implementation**: [How they interact with it]
**Key Insight**: [What we learned]
```

### Step 6: Commit Analysis (Not Their Code)

```powershell
# Stage only documentation and .gitignore
git add .gitignore
git add mods-unpacked/Calico-ReloadUI/ANALYSIS_*.md
git add mods-unpacked/Calico-ReloadUI/GAME_SYSTEMS.md  # If updated

git commit -m "docs: analysis of [ModName] for learning patterns"
git push origin import/ModName
```

**DO NOT** commit their actual mod files unless:

1. They have an open-source license
2. We're archiving for compatibility testing
3. We clearly mark it as third-party with attribution

### Step 7: Merge or Archive

**If keeping for reference**:

```powershell
# Merge analysis documentation into main
git checkout main
git merge import/ModName

# Delete import branch
git branch -d import/ModName
```

**If discarding after analysis**:

```powershell
# Keep documentation, remove third-party files
git checkout main
git checkout import/ModName -- mods-unpacked/Calico-ReloadUI/ANALYSIS_*.md

# Revert .gitignore changes (remove third-party whitelist)
git checkout HEAD -- .gitignore

git add .
git commit -m "docs: imported learnings from [ModName] analysis"

# Delete import branch
git branch -D import/ModName
```

---

## Analysis Example: ImprovedTooltips

### Initial Observations

**Mod**: ImprovedTooltips by \_wl  
**Version**: 1.8.2  
**Purpose**: Enhanced tooltips with additional stat information

### Structure

```
mods-unpacked/_wl-ImprovedTooltips/
├── manifest.json           # Config schema with 7+ toggleable features
├── mod_main.gd            # Version-aware extension loading (legacy/current)
├── current/               # Extensions for current game version
│   └── extensions/
│       ├── effects/
│       ├── main.gd
│       ├── singletons/
│       │   ├── item_service.gd  ← Extends shop icon logic
│       │   └── text.gd
│       └── ui/
├── legacy/                # Extensions for older game version
└── translations/
```

### Key Patterns Observed

#### 1. Version-Aware Extension Loading

**File**: `mod_main.gd`

Uses `match` statement to load different extensions based on game version:

```gdscript
var version = get_version()  # "legacy" or "current"
match version:
    "legacy":
        extensions = [...]
    "current":
        extensions = [...]
```

**Learning**: Supports multiple game versions in single mod - useful for maintaining compatibility across updates.

#### 2. Custom Icon System

**File**: `singletons/text.gd` (implied by `Text._wl_load_icons()`)

Mod loads custom icons and references them via namespace:

```gdscript
Text._wl_icons["knot"].get_data()
```

**Learning**: Can extend singletons to add custom data (icons, text, etc.) with namespaced keys.

#### 3. ItemService Extension

**File**: `current/extensions/singletons/item_service.gd`

Extends `get_icon_for_duplicate_shop_item()` to show additional symbols:

```gdscript
func get_icon_for_duplicate_shop_item(...) -> Texture:
    if shop_item is WeaponData:
        if RunData.get_player_effect_bool("lock_current_weapons", player_index):
            if !RunData.has_weapon_slot_available(shop_item, player_index):
                return Text._wl_icons["knot"].get_data()
    return .get_icon_for_duplicate_shop_item(...)  # Call original
```

**Learning**:

- Can extend singleton methods to add behavior
- Check conditions, return custom result, or fall back to original
- Uses effect system (`get_player_effect_bool`) for conditional logic

#### 4. Config Schema in Manifest

**File**: `manifest.json`

Declares JSON schema for config with defaults:

```json
"config_schema": {
    "properties": {
        "show_actual_stat_gains": {
            "type": "boolean",
            "default": true
        }
    }
}
```

**Learning**: ModLoader supports config schemas directly in manifest - alternative to ModOptions integration.

### Systems Interactions

1. **ItemService**: Modifies shop item display logic
2. **Text Singleton**: Extends with custom icons/text
3. **RunData**: Reads player effects and weapon slots
4. **Config System**: Uses ModLoader's native config instead of ModOptions

### Compatibility Considerations

**Relevant to ReloadUI**:

- ✅ Different scope (tooltips vs cooldown UI) - unlikely conflicts
- ✅ Both extend ItemService but different methods
- ⚠️ Both rely on RunData.players_data - shared dependency
- ⚠️ If they modify same UI nodes, could have z-order conflicts

### Learnings Applied to ReloadUI

1. **Version Management**: Consider supporting legacy game versions
2. **Singleton Extension**: We could extend Text or ItemService for custom data
3. **Config Schema**: Alternative to ModOptions dependency
4. **Effect System**: Use `RunData.get_player_effect_bool()` for conditional features

---

## General Rules

### ✅ DO:

- Analyze third-party code for learning
- Document patterns and techniques
- Credit authors in documentation
- Note compatibility implications
- Update GAME_SYSTEMS.md with discoveries
- Keep analysis in **our mod's directory**

### ❌ DON'T:

- Modify third-party mod files
- Copy code without understanding and rewriting
- Commit their files to main branch
- Remove author attribution
- Use their patterns without adapting to our style
- Assume their implementation is perfect

### 📋 Attribution Template

When documenting learned patterns:

```markdown
**Pattern Source**: Observed in [ModName] by [Author] (v[Version])
**Adapted Implementation**: [How we applied it to our work]
```

---

## Checklist: Before Closing Analysis

- [ ] Documented all relevant patterns
- [ ] Updated GAME_SYSTEMS.md if new systems discovered
- [ ] Created ANALYSIS_ModName.md in our directory
- [ ] Noted compatibility implications
- [ ] Committed only documentation (not their files)
- [ ] Properly attributed techniques
- [ ] Cleaned up import branch if temporary

---

## When to Use This Workflow

**Analyze third-party mods when**:

1. Learning new modding techniques
2. Investigating compatibility issues
3. Understanding game systems better
4. Researching feature implementations
5. Evaluating potential dependencies

**Do NOT use for**:

1. Copying code directly
2. Forking/maintaining their mod
3. Creating derivative works without permission
4. Circumventing their licensing

---

## Related Documentation

- **AI_CONTEXT.md**: Project scope and rules
- **GAME_SYSTEMS.md**: Core game mechanics (update with discoveries)
- **WEAPON_ARCHITECTURE.md**: Specific system deep-dives
- **This file**: Third-party analysis process

---

**Remember**: We're learning FROM them, not copying them. Respect their work, credit their ideas, and implement our own solutions.
