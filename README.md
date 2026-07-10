# Auto Combat Text

**Auto Combat Text** is a World of Warcraft addon that automatically manages **Blizzard Floating Combat Text** based on your role and the content you are in.

It is built for players who want combat text in some situations and less visual noise in others. For example, a tank may want numbers in open world or normal dungeons, but hide them in Mythic+ or raids.

The addon only controls built-in Blizzard Floating Combat Text CVars. It does **not** manage third-party combat text addons.

## Core Idea

Auto Combat Text detects your current context and applies your settings:

- **Default settings** when no rule matches
- **Rules** for specific role + content combinations

Example:

```text
Role: Tank
Content: Mythic+
Result: Hide damage and healing combat text
```

## Default Behavior

Out of the box, settings are account-wide and simple:

**Default settings** (fallback):

```text
Damage Text: Show
Healing Text: Show
```

**Default rules**:

```text
Tank + Mythic+: Hide / Hide
Tank + Raid (Any): Hide / Hide
```

Everything else uses the default settings. Use **Reset to Defaults** in the options panel to restore this setup.

| Role | Content | Damage | Healing |
| --- | --- | --- | --- |
| Tank | Open World | Show | Show |
| Tank | Group | Show | Show |
| Tank | Normal / Heroic / Mythic Dungeon | Show | Show |
| Tank | Delve | Show | Show |
| Tank | LFR / Normal / Heroic / Mythic Raid | Hide | Hide |
| Tank | Mythic+ | Hide | Hide |
| DPS / Healer | Any | Show | Show |

You can change all of this in the options UI or by editing saved variables.

## Supported Roles

```text
Any
Tank
Healer
DPS
```

## Supported Content Types

Auto Combat Text detects content automatically:

```text
Open World
Group (open world while grouped)
Normal Dungeon
Heroic Dungeon
Mythic Dungeon
Dungeon (Any) — matches any dungeon difficulty
Mythic+
Delve
LFR
Normal Raid
Heroic Raid
Mythic Raid
Raid (Any) — matches any raid difficulty
PvP
Scenario
Other
Any
```

Dungeon and raid difficulties use the same `GetInstanceInfo()` difficulty ID that the game already exposes. There is no extra polling and no meaningful performance cost.

## Rule Matching

Rules are matched by role and content. More specific rules win over broader ones.

Priority (highest first):

```text
1. Exact role + exact content
2. Exact role + Any content
3. Any role + exact content
4. Any role + Any content
5. Default settings
```

`Dungeon (Any)` matches all dungeon difficulties. `Raid (Any)` matches LFR, Normal, Heroic, and Mythic raid.

### Duplicate rules

Each **role + content** pair can only exist once. The UI blocks duplicate rules when adding or editing. Existing duplicate rules from older saves are still loaded, but you should remove duplicates manually.

## Actions

Each rule (and default settings) can set damage and healing text to:

```text
Show   — enable the Blizzard CVar
Hide   — disable the Blizzard CVar
Ignore — leave that category unchanged for this rule
```

## Disable Behavior

When the addon is disabled, it stops applying rules. Blizzard CVars stay at whatever value was last applied.

## CVar Handling

The addon manages these Blizzard floating combat text settings:

```text
floatingCombatTextCombatDamage / _v2
floatingCombatTextCombatHealing / _v2
```

CVars are only changed when the target value differs from the current value.

Settings are stored in the account-wide saved variable `AutoCombatTextDB`.

## Options UI

Open with:

```text
/act config
```

Or: **Esc → Options → AddOns → Auto Combat Text**

The panel includes:

- Enable / disable
- Default settings (fallback when no rule matches)
- Editable rules (add, remove, role, content, damage, healing)
- Current context preview

## Slash Commands

```text
/act                  — help
/act status           — current context and applied settings
/act enable           — enable the addon
/act disable          — disable the addon
/act apply            — re-detect context and apply
/act config           — open options
/act reset confirm    — reset settings and rules to defaults
```

## Install

Copy the `AutoCombatText` folder to:

```text
World of Warcraft/_retail_/Interface/AddOns/
```

Or use the local deploy script from this repository:

```powershell
.\deploy.bat
```

Then `/reload` in game and verify with `/act status`.

## Version

The version is defined in `AutoCombatText.toc` and shown in the options panel.

## Project Goal

> Show combat text when it is useful. Hide it when it becomes clutter.

The player defines the rules. The addon applies them automatically when role or content changes.
