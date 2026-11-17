-- Pass the Spleen: spots Cannibalize in your party and picks the yell.
--
-- Cannibalize is channeled, so UNIT_SPELLCAST_CHANNEL_START is the main
-- signal; UNIT_SPELLCAST_SUCCEEDED is a backup in case Forever made it a
-- normal cast. Both can fire for one cast, so each player is throttled.
-- The spell was 20577 in the original game. Forever may use a new ID, so the
-- spell's name is checked too and the ID it uses is remembered.
local _, ns = ...

local S = {
  ids = { [20577] = true },
  name = "Cannibalize",      -- replaced by the client's own (localized) name at login
  THROTTLE = 8,              -- seconds before the same player can trigger again
  last = {},                 -- [player name] = GetTime() of the last trigger
  seen = 0,                  -- Cannibalizes seen this session (for /spleen probe)
}
ns.Spleen = S

local FALLBACK_NAME = "Cannibalize"

-- Only you and your party slots. In a raid that is your own group of five.
local WATCHED = { player = true, party1 = true, party2 = true, party3 = true, party4 = true }

S.LINES = {
  "%s IS EATING A CORPSE! PASS THE SPLEEN!",
  "PASS THE SPLEEN! %s SAYS THERE'S PLENTY FOR EVERYONE!",
  "SOMEBODY GET %s A NAPKIN!",
  "%s CALLS DIBS ON THE LIVER! PASS THE SPLEEN!",
  "DINNER IS SERVED! %s IS CANNIBALIZING!",
  "WHO WANTS SECONDS? %s IS PASSING THE SPLEEN!",
  "%s: \"IT'S NOT CANNIBALISM IF I'M ALREADY DEAD!\"",
  "HOLD MY SPLEEN! %s IS GOING IN!",
}

local function SpellName(id)
  if C_Spell and C_Spell.GetSpellName then
    return ns.Str(ns.Try("C_Spell.GetSpellName", C_Spell.GetSpellName, id))
  end
  if GetSpellInfo then
    return ns.Str((ns.Try("GetSpellInfo", GetSpellInfo, id)))
  end
end

function S:IsCannibalize(spellID)
  spellID = ns.Clean(spellID)
  if type(spellID) ~= "number" then return false end
  if self.ids[spellID] then return true end
  local name = SpellName(spellID)
  if name and (name == self.name or name == FALLBACK_NAME) then
    self.ids[spellID] = true
    ns.db.learnedID = spellID
    ns.Debug("Cannibalize is spell", spellID, "on this client")
    return true
  end
  return false
end

function S:Line(who)
  local line = self.LINES[math.random(#self.LINES)]
  return string.format(line, string.upper(who))
end

-- Test: offer a yell with your own name (no throttle).
function S:Test()
  local me = ns.Str(UnitName("player")) or "You"
  ns.Fire("CANNIBALIZE", me, "player")
end

local function OnCast(_, unit, _, spellID)
  if not ns.db or not ns.db.enabled then return end
  unit = ns.Str(unit)
  if not unit or not WATCHED[unit] then return end
  if unit == "player" and not ns.db.includeSelf then return end
  if not S:IsCannibalize(spellID) then return end

  local who = ns.Str(UnitName(unit)) or "Someone"
  local now = GetTime()
  if S.last[who] and now - S.last[who] < S.THROTTLE then return end
  S.last[who] = now
  S.seen = S.seen + 1
  ns.Debug("Cannibalize:", who, unit)
  ns.Fire("CANNIBALIZE", who, unit)
end

ns.On("UNIT_SPELLCAST_CHANNEL_START", OnCast)
ns.On("UNIT_SPELLCAST_SUCCEEDED", OnCast)

ns.Listen("LOGIN", function()
  S.name = SpellName(20577) or FALLBACK_NAME
  if type(ns.db.learnedID) == "number" then S.ids[ns.db.learnedID] = true end
end)
