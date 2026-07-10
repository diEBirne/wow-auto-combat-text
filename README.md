# Auto Combat Text

**Auto Combat Text** is a World of Warcraft addon that automatically manages **Blizzard Floating Combat Text** based on your configured role and content rules.

It is designed for players who want different combat text behavior in different situations. For example, a tank may want to see damage numbers while playing solo or running normal dungeons, but hide them in Mythic+ or raids to reduce visual clutter.

Auto Combat Text only controls the built-in Blizzard Floating Combat Text settings. It does **not** manage third-party combat text addons such as MikScrollingBattleText, Parrot, NameplateSCT, or similar addons.

## Core Idea

Combat text is useful in some situations and distracting in others.

Auto Combat Text detects your current context and applies your configured rules automatically.

The detected context includes:

- Current role
- Current content type
- Instance type
- Mythic+ state
- Specialization fallback when no group role is assigned

Example:

```text
Role: Tank
Content: Mythic+
Action: Hide damage and healing combat text
```

Another example:

```text
Role: Tank
Content: Open World
Action: Show damage and healing combat text
```

## Why?

As a tank in Mythic+ or raids, floating damage and healing numbers can become visual noise. You are constantly receiving damage, healing, absorbs, DoT ticks, and other combat events.

In challenging group content, important information usually comes from unit frames, nameplates, boss mods, WeakAuras, and cooldown tracking instead.

In open world content, solo play, or casual dungeons, combat text can still feel good because it provides direct feedback.

Auto Combat Text is built around this idea:

> Show combat text when it is useful. Hide it when it becomes clutter.

## Default Behavior

The default profile is intentionally simple and safe.

Profile default:

```text
Damage Text: Show
Healing Text: Show
```

Default rules:

```text
Tank + Mythic+: Hide Damage, Hide Healing
Tank + Raid:    Hide Damage, Hide Healing
```

Everything else uses the profile default.

This means:

| Role | Content | Damage Text | Healing Text |
| --- | --- | --- | --- |
| Tank | Open World | Show | Show |
| Tank | Normal Dungeon | Show | Show |
| Tank | Heroic Dungeon | Show | Show |
| Tank | Mythic Dungeon | Show | Show |
| Tank | Mythic+ | Hide | Hide |
| Tank | Raid | Hide | Hide |
| DPS | Any Content | Show | Show |
| Healer | Any Content | Show | Show |

Users can change these rules to match their preferences.

## Rule-Based Configuration

Auto Combat Text uses a profile default plus optional specific rules.

A rule can match by:

- Role
- Content type

Supported roles:

```text
Any
Tank
Healer
DPS
```

Supported content types for the initial version:

```text
Any
Open World
Dungeon
Mythic+
Raid
PvP
Scenario
Other
```

More specific content types may be added later:

```text
Normal Dungeon
Heroic Dungeon
Mythic Dungeon
LFR
Normal Raid
Heroic Raid
Mythic Raid
Arena
Battleground
Delve
```

## Matching Priority

Rules should be evaluated by specificity.

Recommended priority:

```text
1. Exact role + exact content
2. Exact role + Any content
3. Any role + exact content
4. Any role + Any content
5. Profile default
```

Example:

```text
Default:
Damage Text = Show
Healing Text = Show

Rule:
Role = Tank
Content = Mythic+
Damage Text = Hide
Healing Text = Hide
```

If you are a tank in Mythic+, the rule applies.

If you are DPS in Mythic+, no tank rule applies, so the profile default is used.

## Actions

Each managed combat text category can be set to:

```text
Show
Hide
Ignore
```

### Show

Enables the corresponding Blizzard Floating Combat Text setting.

### Hide

Disables the corresponding Blizzard Floating Combat Text setting.

### Ignore

Leaves the category unchanged by that specific rule.

This is useful when a rule should only control damage text but not healing text, or vice versa.

For the first version, the most important managed categories are:

```text
Damage Text
Healing Text
```

Additional categories may be supported later:

```text
Periodic Damage
Periodic Healing
Pet Damage
Honor Gains
Auras
Reactives
Low Health / Low Mana warnings
```

## Blizzard Floating Combat Text Only

Auto Combat Text only manages Blizzard CVars related to Floating Combat Text.

It does not control or configure third-party combat text addons.

This limitation is intentional. The addon should be lightweight and predictable.

## CVar Handling

Blizzard Floating Combat Text settings are stored as global CVars.

Auto Combat Text should therefore handle them carefully:

- Store the original Blizzard settings on first run.
- Apply the current profile and rule settings when the context changes.
- Restore original settings when the addon is disabled, if configured to do so.
- Only change CVars that are managed by the addon.

Even though the CVars are global, profiles are still useful. Profiles store desired rules, and the addon applies those rules whenever a character logs in, changes specialization, enters content, or changes role.

## Profiles

Profile support is planned.

The first version may use a single global profile.

Future versions should support:

- Global profile
- Character-specific profile
- Class-specific profile
- Manually selected custom profiles

Example:

```text
Monk Profile:
- Tank + Mythic+: Hide Damage, Hide Healing
- Tank + Raid: Hide Damage, Hide Healing
- Default: Show Damage, Show Healing

Paladin Profile:
- Tank + Mythic+: Hide Damage, Hide Healing
- Tank + Raid: Show Damage, Show Healing
- Default: Show Damage, Show Healing
```

Profiles do not conflict with global CVars because they do not store separate live CVar states. They store rules that are applied when the profile is active.

## Example Use Cases

### Tank in Solo Play

```text
Role: Tank
Content: Open World
Damage Text: Show
Healing Text: Show
```

### Tank in Mythic+

```text
Role: Tank
Content: Mythic+
Damage Text: Hide
Healing Text: Hide
```

### Tank in Raid

```text
Role: Tank
Content: Raid
Damage Text: Hide
Healing Text: Hide
```

### Tank in Normal Dungeon

```text
Role: Tank
Content: Dungeon
Damage Text: Show
Healing Text: Show
```

### DPS in Any Content

```text
Role: DPS
Content: Any
Damage Text: Show
Healing Text: Show
```

### Healer in Mythic+ or Raid

Possible healer rule:

```text
Role: Healer
Content: Mythic+
Damage Text: Hide
Healing Text: Show
```

or:

```text
Role: Healer
Content: Raid
Damage Text: Hide
Healing Text: Show
```

## Planned Features

- Automatically manage Blizzard Floating Combat Text.
- Detect current role.
- Detect current content.
- Detect Mythic+ separately from regular dungeons.
- Use specialization as fallback when no group role is assigned.
- Profile default settings.
- Rule-based overrides by role and content.
- Separate settings for damage and healing combat text.
- Safe CVar handling.
- Restore original Blizzard settings when the addon is disabled.
- Slash commands for status, enable, disable, and apply.
- Optional profiles for different characters or classes.
- Optional UI panel for rule editing.

## Suggested Slash Commands

```text
/act
/act status
/act enable
/act disable
/act apply
/act reset
```

Possible future commands:

```text
/act profile list
/act profile create <name>
/act profile use <name>
/act default damage show
/act default damage hide
/act default healing show
/act default healing hide
```

## Current Context Display

The addon should make it easy to understand what it is doing.

A status command or options panel should show:

```text
Current Role: Tank
Current Content: Mythic+
Active Rule: Tank + Mythic+
Damage Text: Hidden
Healing Text: Hidden
```

This helps users verify that the correct rule is active.

## Project Goal

Auto Combat Text should make Blizzard Floating Combat Text feel automatic without being unpredictable.

The player defines the rules. The addon applies them.

The core goal is:

> Show combat text when it is useful, hide it when it becomes clutter.
