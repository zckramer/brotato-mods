# 🚀 AI Assistant Session Check-In

**Copy-paste this at the start of each work session:**

---

```
I'm starting work on the ReloadUI mod for Brotato. Please confirm you've reviewed:

1. AI_CONTEXT.md - Repository scope and development rules
2. AI_GODOT_REFERENCE.md - Godot 3.6.2 syntax (NOT 4.x)
3. GAME_SYSTEMS.md - Core game mechanics and systems
4. WEAPON_ARCHITECTURE.md - Weapon system deep-dive

Key reminders:
- This repo ONLY tracks mods-unpacked/Calico-ReloadUI/ (never edit base game files)
- Use Godot 3.6.2 docs (https://docs.godotengine.org/en/3.6/)
- Test via Godot editor (F5), not Steam launch
- Check documentation for specific system architecture details

Please summarize what this mod does and confirm you understand the scope boundaries.
```

---

## ✅ Expected Assistant Response Should Include:

- **Mod Purpose**: Weapon cooldown/reload UI display
- **Scope Boundary**: Only modify files in `mods-unpacked/Calico-ReloadUI/`
- **Godot Version**: 3.6.2 (not 4.x)
- **Testing Method**: Launch via Godot editor (F5), not Steam
- **Architecture Awareness**: Understanding of system separation (check docs for specifics)

---

## 📚 Documentation Quick Reference

| File                       | Purpose                                | When to Read                         |
| -------------------------- | -------------------------------------- | ------------------------------------ |
| **AI_CONTEXT.md**          | Quick orientation, scope, workflows    | Every session (this prompt)          |
| **AI_GODOT_REFERENCE.md**  | Complete Godot 3.6.2 & GDScript syntax | Writing code, checking APIs          |
| **GAME_SYSTEMS.md**        | Core game mechanics documentation      | Working with any game system         |
| **WEAPON_ARCHITECTURE.md** | Weapon system deep-dive                | Working with weapons/icons/cooldowns |
| **README.md**              | User-facing documentation              | Understanding features               |

---

## ⚠️ Critical Don'ts

- ❌ Don't use Godot 4.x syntax (`await`, new signal connections)
- ❌ Don't edit files outside `mods-unpacked/Calico-ReloadUI/`
- ❌ Don't test via Steam launch (use Godot editor F5)
- ❌ Don't commit base game files
- ❌ Don't assume API structure without checking documentation

---

## ✅ Development Workflow

1. **Start**: Use this check-in prompt
2. **Context**: Read AI_CONTEXT.md
3. **Syntax**: Reference AI_GODOT_REFERENCE.md when coding
4. **Game Mechanics**: Check GAME_SYSTEMS.md for system understanding
5. **Architecture**: Check WEAPON_ARCHITECTURE.md for weapon patterns
6. **Code**: Only modify `mods-unpacked/Calico-ReloadUI/` files
7. **Test**: Launch via Godot editor (F5)
8. **Verify**: `git status` before commit
9. **Document**: Update GAME_SYSTEMS.md or WEAPON_ARCHITECTURE.md with discoveries

---

**Save this file for easy session starts!**
