# Turn-Based Combat Example (Godot)

A **Turn-based combat example** project built with **Godot Engine v4.5.1.stable.official**.  
This project demonstrates a simple **turn-based combat system** with player and enemy units, abilities, turn order, and UI feedback.

---

## 🧭 TODO ROADMAP

### 🔧 Core Systems
- [x] Modify UI (basic layout done)
- [x] Modify AI (basic attack logic done)
- [ ] Team mode (multiple players/allies per side)
- [ ] Team skills (affect multiple allies/enemies)
- [ ] Buffs/Debuffs/Stacking (timed effects, stat modifiers)

### ⚔️ Combat & Skills
- [x] Basic attack skill (works)
- [x] Fireball skill (enemy-target skill ready)
- [x] Healing skill (self-target skill ready)
- [ ] Critical hits and miss chance
- [ ] Elemental system (fire, ice, lightning, etc.)
- [ ] Resistance and weakness system
- [ ] Damage-over-time (poison, burn, bleed)
- [ ] Healing-over-time (regen)
- [ ] Status effects (stun, sleep, freeze, silence, etc.)
- [ ] Passive skills and traits
- [ ] Combo skills (triggered by previous actions)
- [ ] Cooldowns for skills
- [ ] Skill animations & VFX

### 🧠 AI & Decision Making
- [x] Enemy can use attack and choose target (basic AI)
- [x] Enemy avoids healing if HP > 50%
- [ ] Weighted decision-making based on situation (HP, MP, buffs)
- [ ] AI personalities (aggressive, defensive, support, balanced)
- [ ] AI learning or adaptive difficulty
- [ ] Contextual target selection (prioritize weakest, healer, etc.)

### 👥 Party & Progression
- [ ] Multiple player characters in one party
- [ ] Character leveling & XP system
- [ ] Equipment and inventory system
- [ ] Stat growth and customization
- [ ] Class system (Warrior, Mage, Healer, etc.)
- [ ] Skill tree / unlockable abilities

### 🧾 UI / UX Improvements
- [ ] Dynamic action log (show skill names, damage, healing, etc.)
- [ ] Hover tooltips for skills (damage, cost, description)
- [ ] Character portraits and HP/MP bars
- [ ] Animated turn order bar
- [ ] Floating combat text (damage numbers)
- [ ] Transition effects (fade in/out between turns)

### 🌍 Content & Integration
- [ ] Battle rewards (XP, gold, items)
- [ ] Shop system (buy/sell equipment)
- [ ] Save/Load battle state
- [ ] Integration with overworld (enter/exit battles)
- [ ] Procedural enemy generation
- [ ] Boss fights with unique mechanics

### 💥 Polish & Effects
- [ ] Sound effects for actions, hits, and UI
- [ ] Camera shake & zoom during impactful skills
- [ ] Screen effects (flashes, particles, slow motion)
- [ ] Custom win/lose animations
- [ ] Better victory/defeat screen (stats summary, rewards)

### 🧩 Technical Improvements
- [x] Modular data-driven system (Skills, Characters, Items as Resources)
- [x] Event-based system for all battle communication
- [ ] Configurable turn order logic (ATB, initiative roll, etc.)
- [ ] Replay or debug mode (recorded combat logs)
- [ ] Testing suite for combat balance
