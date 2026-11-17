# Changelog

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
