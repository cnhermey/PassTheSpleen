# Changelog

## 0.3.0 (2026-11-21)
- No more button: clicking it didn't yell out in the world. Everything is automatic now.
- Each line goes on /yell if the game allows it, otherwise /party (instance chat in a dungeon-finder group), otherwise /say. The addon checks that the message really showed up in chat before moving on.
- If no chat will take it (solo out in the world), the line shows in your own chat window, marked "only you can see this".
- A chat that's blocked in the world, in an instance or in a boss fight is skipped there for the rest of the session.
- Reactions now also hear the caster's line in /party and /say, not just /yell.
- 10 new lines, each with 3 reactions (18 lines in all).
- Removed the button settings ("Play a sound", "Button stays up", "Reset position") and `/spleen reset`.
- `/spleen probe` shows how many lines went to each chat and which chats were blocked where.

## 0.2.0 (2026-11-16)
- The other Undead in your party now yell back. When an Undead uses Cannibalize, they yell a line; every other Undead in the party with the addon hears it and, a second or two later, yells a reaction that fits that line (for example "ME NEXT! I CALLED THE SPLEEN!"). Each line has 3 reactions, plus 3 general ones, and nobody repeats one that's already been yelled.
- Only the person who cannibalizes yells the first line now. Other races no longer get a button for a party member's Cannibalize.
- Works inside instances without addon messages: reactions are set off by hearing the caster's yell.
- New setting "React to other Undead"; "Also for my own" is now "When I cannibalize". New "Test reaction" button and `/spleen react`.

## 0.1.1 (2026-11-16)
- Inside dungeons, raids and other instances, you yell right away again, with no button (as the first test version did). During a boss fight, and out in the world, the button is used.
- If an automatic yell fails, the button appears instead.
- `/spleen probe` shows how many yells were automatic and whether a boss fight is on.

## 0.1.0 (2026-11-16)
- First version, for WoW: Forever (interface 16001).
- When you or anyone in your party uses Cannibalize, a **Pass the Spleen!** button appears near the top of the screen with a raid warning sound. Click it to yell one of 8 lines with that player's name, for example "THRALLBANE IS EATING A CORPSE! PASS THE SPLEEN!". The button hides itself after 12 seconds (adjustable). Hover it to see the line first.
- The addon never yells on its own: Forever only sends a /yell from a real click, and blocks addon chat inside instances.
- Cannibalize is found by spell ID and by name, so it still works if Forever gave the spell a new ID. The ID it uses is remembered.
- Each player can trigger it once every 8 seconds.
- Shift-drag the button to move it.
- Settings in Esc → Options → AddOns → Pass the Spleen (`/spleen`).
- `/spleen test` for testing solo; `/spleen probe` for a developer report.
