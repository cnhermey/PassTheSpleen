# Pass the Spleen (v0.3.1)

Undead can eat corpses, and the whole party should know about it. When you use **Cannibalize**, Pass the Spleen yells about it. Then every other Undead in your party who has the addon yells back with a reaction to what you said.

- **The first line.** When you cannibalize, you yell one of 18 lines with your name, for example *"THRALLBANE IS EATING A CORPSE! PASS THE SPLEEN!"*.
- **The reactions.** Every other Undead in your party with the addon hears that line and, a second or two later, answers with a reaction that fits it: *"ME NEXT! I CALLED THE SPLEEN!"*, *"SAVE ME THE SPLEEN, THRALLBANE!"*. Each line has 3 reactions (plus 3 general ones), and nobody repeats a reaction someone else in the group already used.
- **One message, picked by where you are.** Inside a dungeon, raid or other instance, you yell. Out in the world, or during a boss fight, where Forever won't let an addon yell, it goes to /party (instance chat in a dungeon-finder group). If you're not in a group there, it goes to /say.
- **No button.** Everything is automatic.
- **Who counts.** You and the 4 other people in your party. In a raid, that's your own group of five. Only Undead react; other races stay quiet. Each player can set it off once every 8 seconds.
- **No addon messages.** The reactions come from hearing the caster's line in /yell, /party or /say, so they work inside instances, where Forever blocks addon-to-addon messages. The caster needs the addon too, or there's no line to react to.
- **Settings** in Esc → Options → AddOns → Pass the Spleen (or `/spleen`): turn it on or off, send a line for your own Cannibalize, and react to other Undead.

### Looks like Blizzard's UI
- The settings page uses Blizzard's checkboxes and buttons, with the Cannibalize icon.
- Chat messages look like system messages, with a short "Pass the Spleen:" prefix.

## Install
1. Copy the `PassTheSpleen` folder to `World of Warcraft\_forever_\Interface\AddOns\`.
   **Copy the folder; don't symlink it.** On Forever, a symlinked addon folder silently resets its SavedVariables.
2. Restart the game, or `/reload` if it's already running, and enable the addon on the character screen.
3. The TOC says `## Interface: 16001`. If the addon shows as out of date, check the real number with
   `/run print(select(4, GetBuildInfo()))` and update the TOC line.

## First in-game test
1. In a dungeon (not during a boss), type `/spleen test`: your character yells, once.
2. In a party, out in the world, type `/spleen test`: the line goes to /party.
3. Solo, out in the world, type `/spleen test`: the line goes to /say (Forever may refuse this one).
4. Type `/spleen react`: a second or two later you send a reaction, as if Thrallbane had just sent a line.
5. On an Undead, kill a Humanoid and use Cannibalize on the corpse.
6. If something looks wrong, type `/spleen probe` and send the output. It shows which chat it would use where you are, and how many lines went to each.

## Commands
- `/spleen` or `/passthespleen`: open the settings
- `/spleen test`: send a line with your name
- `/spleen react`: test a reaction, as if Thrallbane had just sent a line
- `/spleen on`, `/spleen off`: turn it on or off
- `/spleen probe`: developer report (client APIs, Cannibalize's spell ID, what was sent where, what was blocked)

## How it works
| File | Role |
|---|---|
| `Util.lua` | Helpers: secret-value guard, safe API calls, chat output, timers |
| `Core.lua` | Event frame, internal message bus, SavedVariables (`PassTheSpleenDB`) |
| `UI_Common.lua` | Blizzard colors, icon and sounds |
| `Spleen.lua` | Watches `UNIT_SPELLCAST_CHANNEL_START` and `UNIT_SPELLCAST_SUCCEEDED` for you and party1-4, recognizes Cannibalize (spell 20577 or its name), throttles each player, picks your line. For a party member's cast (if you're Undead), waits for their line in /yell, /party or /say, matches it and picks a reaction nobody has used yet |
| `Chat.lua` | Sends each line once: /yell inside an instance outside a boss fight; otherwise /party (or instance chat) in a group, else /say |
| `Options.lua` | Settings page in Esc → Options → AddOns: Blizzard checkboxes and buttons, through one setter (`ns.Options:Set`) |
| `Commands.lua` | `/spleen` and `/passthespleen`, and the `/spleen probe` report |

The lines are in `S.LINES` and the reactions in `S.REACTIONS` (same order) at the top of `Spleen.lua`.

## Needs in-game verification
- Cannibalize's spell ID on Forever: `/spleen probe` "Cannibalize:" line shows the learned ID after the first cast.
- That Cannibalize fires `UNIT_SPELLCAST_CHANNEL_START` (or `SUCCEEDED`) for party members, and that the spell ID isn't hidden as a secret value.
- That an addon can send /party out in the world without a key press (it doesn't need one in the original game).
- That addons can read other players' chat inside instances at all, so reactions fire there. v0.3.0 didn't see its own yell in a dungeon, which suggests they can't. Turn on debug messages to see "Heard <name> line <n>".
- That `UnitRace` reports Undead as `Scourge` on Forever (`/spleen probe` shows "you're Undead").
