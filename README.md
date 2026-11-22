# Pass the Spleen (v0.3.0)

Undead can eat corpses, and the whole party should know about it. When you use **Cannibalize**, Pass the Spleen yells about it. Then every other Undead in your party who has the addon yells back with a reaction to what you said.

- **The first line.** When you cannibalize, you yell one of 18 lines with your name, for example *"THRALLBANE IS EATING A CORPSE! PASS THE SPLEEN!"*.
- **The reactions.** Every other Undead in your party with the addon hears that line and, a second or two later, answers with a reaction that fits it: *"ME NEXT! I CALLED THE SPLEEN!"*, *"SAVE ME THE SPLEEN, THRALLBANE!"*. Each line has 3 reactions (plus 3 general ones), and nobody repeats a reaction someone else in the group already used.
- **Yell, else party, else say.** The addon tries /yell first. If the game won't let it yell (out in the world, Forever only allows /yell from a real key press), it uses /party, or instance chat in a dungeon-finder group. If you're not in a group, it uses /say. It checks that each message really showed up in chat before it counts it as sent.
- **No button.** Everything is automatic. If no chat will take the line (for example solo out in the world, where /say is blocked too), the line appears in your own chat window, marked "only you can see this".
- **It learns.** A chat that's blocked in the world, in an instance or in a boss fight is skipped there for the rest of the session, so later lines go straight to one that works.
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
1. Solo, out in the world, type `/spleen test`. You won't be allowed to yell or say, so the line shows in your chat window with "only you can see this".
2. In a party, out in the world, type `/spleen test`: the line goes to /party.
3. In a dungeon (not during a boss), type `/spleen test`: your character should yell.
4. Type `/spleen react`: a second or two later you send a reaction, as if Thrallbane had just sent a line.
5. On an Undead, kill a Humanoid and use Cannibalize on the corpse.
6. If something looks wrong, type `/spleen probe` and send the output. It shows how many lines went to each chat and which chats were blocked where.

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
| `Chat.lua` | Sends each line on /yell, then /party (or instance chat), then /say. After each try it waits up to 1.5 s for the message to show up in chat, and moves on if it doesn't or if the game reports `ADDON_ACTION_BLOCKED`. Remembers blocked chats per place (world, instance, boss fight) for the session |
| `Options.lua` | Settings page in Esc → Options → AddOns: Blizzard checkboxes and buttons, through one setter (`ns.Options:Set`) |
| `Commands.lua` | `/spleen` and `/passthespleen`, and the `/spleen probe` report |

The lines are in `S.LINES` and the reactions in `S.REACTIONS` (same order) at the top of `Spleen.lua`.

## Needs in-game verification
- Cannibalize's spell ID on Forever: `/spleen probe` "Cannibalize:" line shows the learned ID after the first cast.
- That Cannibalize fires `UNIT_SPELLCAST_CHANNEL_START` (or `SUCCEEDED`) for party members, and that the spell ID isn't hidden as a secret value.
- That a blocked /yell or /say is noticed (no echo in chat, or `ADDON_ACTION_BLOCKED`) and the next chat is used. The first blocked try may print Blizzard's "Interface action failed because of an AddOn" once.
- That an addon can send /party out in the world without a key press (it doesn't need one in the original game).
- That the caster's text and name are readable in chat events inside instances (not secret), so reactions fire. Turn on debug messages to see "Heard <name> line <n>".
- That `UnitRace` reports Undead as `Scourge` on Forever (`/spleen probe` shows "you're Undead").
