# Pass the Spleen (v0.1.0)

Undead can eat corpses, and the whole party should know about it. When you or anyone in your party uses **Cannibalize**, Pass the Spleen gets a yell ready. One click sends it.

- **The yell button.** A **Pass the Spleen!** button appears near the top of the screen with a raid warning sound. Click it to yell one of 8 lines with that player's name, for example *"THRALLBANE IS EATING A CORPSE! PASS THE SPLEEN!"*. Hover it first to see which line you'll get. The button hides itself after 12 seconds if you don't click it.
- **Why a button.** WoW: Forever only lets an addon /yell from a real click or key press, and blocks addon chat inside instances. So Pass the Spleen never yells on its own; your click sends it, anywhere.
- **Who counts.** You and the 4 other people in your party. In a raid, that's your own group of five. Each player can set it off once every 8 seconds.
- **Settings** in Esc → Options → AddOns → Pass the Spleen (or `/spleen`): turn it on or off, skip your own Cannibalize, mute the sound, and change how long the button stays up.

### Looks like Blizzard's UI
- The button is Blizzard's standard button with the Cannibalize icon, and the warning is Blizzard's raid warning sound.
- The settings page uses Blizzard's checkboxes, slider and buttons.
- Chat messages look like system messages, with a short "Pass the Spleen:" prefix.

## Install
1. Copy the `PassTheSpleen` folder to `World of Warcraft\_forever_\Interface\AddOns\`.
   **Copy the folder; don't symlink it.** On Forever, a symlinked addon folder silently resets its SavedVariables.
2. Restart the game, or `/reload` if it's already running, and enable the addon on the character screen.
3. The TOC says `## Interface: 16001`. If the addon shows as out of date, check the real number with
   `/run print(select(4, GetBuildInfo()))` and update the TOC line.

## First in-game test (solo)
1. Type `/spleen test`. The button should appear near the top of the screen with a sound. Hover it to see the line, then click it: your character yells.
2. Shift-drag the button to where you want it.
3. On an Undead, kill a Humanoid and use Cannibalize on the corpse. The button should appear with your name.
4. In a party with an Undead, have them use Cannibalize.
5. If something looks wrong, type `/spleen probe` and send the output.

## Commands
- `/spleen` or `/passthespleen`: open the settings
- `/spleen test`: show the yell button with your name
- `/spleen on`, `/spleen off`: turn it on or off
- `/spleen reset`: move the yell button back to the top
- `/spleen probe`: developer report (client APIs, Cannibalize's spell ID, what the addon has seen)

## How it works
| File | Role |
|---|---|
| `Util.lua` | Helpers: secret-value guard, safe API calls, chat output, timers |
| `Core.lua` | Event frame, internal message bus, SavedVariables (`PassTheSpleenDB`) |
| `UI_Common.lua` | Blizzard colors, icon and sounds |
| `Spleen.lua` | Watches `UNIT_SPELLCAST_CHANNEL_START` and `UNIT_SPELLCAST_SUCCEEDED` for you and party1-4, recognizes Cannibalize (spell 20577 or its name), throttles each player, picks the line |
| `UI_Button.lua` | The yell button: shows the line, sends it as a /yell on click, hides after a few seconds, Shift-drag to move |
| `Options.lua` | Settings page in Esc → Options → AddOns: Blizzard checkboxes, slider and buttons, through one setter (`ns.Options:Set`) |
| `Commands.lua` | `/spleen` and `/passthespleen`, and the `/spleen probe` report |

The yell lines are in `S.LINES` at the top of `Spleen.lua`.

## Needs in-game verification
- Cannibalize's spell ID on Forever: `/spleen probe` "Cannibalize:" line shows the learned ID after the first cast.
- That Cannibalize fires `UNIT_SPELLCAST_CHANNEL_START` (or `SUCCEEDED`) for party members, and that the spell ID isn't hidden as a secret value.
- That a click on the button can yell inside a dungeon.
- The settings page in Esc → Options → AddOns, and that `/spleen` opens it.
