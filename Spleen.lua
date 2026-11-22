-- Pass the Spleen: spots Cannibalize in your party and picks the yells.
--
-- Your own Cannibalize: you yell one of LINES with your name (Chat.lua picks
-- /yell, /party or /say, whichever works).
-- A party member's Cannibalize (and you are Undead): you wait to hear their
-- line in /yell, /party or /say, work out which line it was, then send a
-- matching reaction from REACTIONS a moment later. Nothing is sent between
-- addons (Forever blocks that in instances); the caster's line in chat is
-- the signal. Reactions
-- already yelled by others in the group are skipped, so everyone says
-- something different.
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
  "%s FOUND A FRESH ONE! PASS THE SPLEEN!",
  "THE DARK LADY WATCHES OVER %s'S LUNCH BREAK!",
  "%s IS EATING FOR TWO! (THE OTHER ONE IS ALSO DEAD.)",
  "NOBODY TELL THE PALADINS! %s IS SNACKING!",
  "%s: \"THIS ONE NEEDS SALT!\"",
  "ALL YOU CAN EAT! %s IS AT THE BUFFET!",
  "WASTE NOT, WANT NOT! %s IS CLEANING UP!",
  "%s HAS ROTTEN TABLE MANNERS! PASS THE SPLEEN!",
  "BRAINS ARE FOR GHOULS! %s ONLY WANTS THE SPLEEN!",
  "A SPLEEN A DAY KEEPS THE PRIEST AWAY! %s KNOWS IT!",
}

-- Reactions for each line above, by position. %s is the caster's name.
S.REACTIONS = {
  { "ME NEXT! I CALLED THE SPLEEN!", "SAVE ME THE SPLEEN, %s!", "DON'T HOG THE SPLEEN, %s!" },
  { "I'LL TAKE A SPLEEN TO GO!", "PLENTY? %s ALREADY ATE HALF OF IT!", "GET IN LINE, I'M NEXT!" },
  { "NAPKINS ARE FOR THE LIVING!", "FORGET THE NAPKIN, PASS THE GRAVY!", "%s, YOU'VE GOT SOME... EVERYWHERE." },
  { "FINE, BUT I GET THE KIDNEYS!", "DIBS ON THE PANCREAS!", "NO FAIR! %s ALWAYS GETS THE LIVER!" },
  { "IS THERE A KIDS' MENU?", "I'LL HAVE WHAT %s IS HAVING!", "COMPLIMENTS TO THE CORPSE!" },
  { "ME! ME! I WANT SECONDS!", "SECONDS? I HAVEN'T HAD FIRSTS!", "PASS IT THIS WAY, %s!" },
  { "THAT'S... ACTUALLY A GOOD POINT.", "THE FORSAKEN LAWYERS AGREE!", "I'M ALSO DEAD! ME NEXT!" },
  { "I'M HOLDING IT! ...I ATE IT. SORRY.", "GO %s GO! LEAVE SOME FOR ME!", "SOMEONE HOLD MY SPLEEN TOO, I'M GOING IN!" },
  { "FRESH? IT'S BEEN THERE SINCE TUESDAY!", "SAVE ME THE CRUNCHY BITS, %s!", "SMELLS LIKE HOME COOKING!" },
  { "FOR THE DARK LADY! AND FOR SECONDS!", "SHE'D WANT YOU TO SHARE, %s!", "DOES THE DARK LADY WANT THE SPLEEN?" },
  { "CONGRATULATIONS...?", "THEN I'LL EAT FOR THREE!", "IS IT A BOY OR A GHOUL, %s?" },
  { "MY LIPS ARE SEALED. MOSTLY ROTTED, BUT SEALED.", "TOO LATE, THE PALADIN SAW!", "WHAT PALADINS? THERE WERE PALADINS?" },
  { "TRY THE MARROW, IT'S PRE-SEASONED!", "SALT IS FOR SLUGS AND THE LIVING!", "PASS THE SALT AND THE SPLEEN, %s!" },
  { "WHERE'S THE DESSERT CORPSE?", "I'LL WAIT FOR THE SECOND SEATING!", "%s, LEAVE SOME FOR THE GHOULS!" },
  { "RECYCLING IS IMPORTANT!", "MOTHER WOULD BE PROUD, %s!", "I'LL DO THE DISHES! ...THE BONES, I MEAN." },
  { "ELBOWS OFF THE CORPSE, %s!", "MY MANNERS FELL OFF WITH MY JAW!", "CHEW WITH YOUR MOUTH CLOSED! ...IF YOU STILL HAVE ONE!" },
  { "MORE BRAINS FOR ME THEN!", "THE SPLEEN IS THE BEST PART, EVERYONE KNOWS!", "%s HAS REFINED TASTES!" },
  { "I'VE HAD THREE TODAY! I FEEL GREAT!", "THE APOTHECARIES APPROVE, %s!", "WHAT ABOUT THE PRIEST WE ATE YESTERDAY?" },
}
-- When the caster's line can't be read (or isn't one of ours).
S.GENERIC = { "ME NEXT!", "SAVE ME A BITE, %s!", "ARE YOU GOING TO FINISH THAT?" }

S.WAIT = 8                 -- seconds to wait for the caster's line
S.waiting = {}             -- [caster name] = GetTime() of their cast
S.round = nil              -- { caster, idx, said = { [line] = true } } of the latest reaction round
S.reacted = 0              -- reactions sent this session (for /spleen probe)

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

---------------------------------------------------------------------------
-- Reactions
---------------------------------------------------------------------------
local function Upper(who) return string.upper(who or "SOMEONE") end

-- Lua patterns that match each line, with any name in place of %s.
local PATTERNS = {}
for i, line in ipairs(S.LINES) do
  local p = line:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
  p = p:gsub("%%%%s", ".+")
  PATTERNS[i] = "^" .. p .. "$"
end

-- Which of LINES this message is, or nil.
function S:WhichLine(text)
  text = ns.Str(text)
  if not text then return nil end
  for i, p in ipairs(PATTERNS) do
    if text:find(p) then return i end
  end
end

function S:IAmUndead()
  local _, race = UnitRace("player")
  race = ns.Str(race)
  return race == "Scourge" or race == "Undead"
end

-- Pick a reaction nobody in this round has yelled yet.
function S:PickReaction()
  local r = self.round
  if not r then return nil end
  local function Fresh(list)
    local out = {}
    for _, line in ipairs(list) do
      local text = string.format(line, Upper(r.caster))
      if not r.said[text] then out[#out + 1] = text end
    end
    return out
  end
  local options = r.idx and Fresh(self.REACTIONS[r.idx]) or {}
  if #options == 0 then options = Fresh(self.GENERIC) end
  if #options == 0 then return nil end -- everything's been said
  return options[math.random(#options)]
end

-- The caster's line was heard: react after a short, random pause so
-- several Undead don't all yell at once.
function S:StartRound(caster, idx)
  self.round = { caster = caster, idx = idx, said = {} }
  local round = self.round
  ns.Debounce("react", 1 + math.random() * 2, function()
    if self.round ~= round then return end
    local msg = self:PickReaction()
    if not msg then return end
    round.said[msg] = true
    self.reacted = self.reacted + 1
    ns.Chat:Deliver(msg)
  end)
end

local function Short(name)
  name = ns.Str(name)
  if not name then return nil end
  return (name:match("^([^%-]+)")) or name
end

-- The caster's line in /yell, /party or /say.
local function OnChat(_, text, sender)
  local who = Short(sender)
  if not who then return end
  text = ns.Str(text)

  -- Someone else's reaction in the current round: don't repeat it.
  if S.round and text then S.round.said[text] = true end

  local castAt = S.waiting[who]
  if not castAt then return end
  if GetTime() - castAt > S.WAIT then S.waiting[who] = nil; return end
  local idx = S:WhichLine(text)
  if not idx then return end -- a message from them, but not a spleen line
  S.waiting[who] = nil
  ns.Debug("Heard", who, "line", idx)
  S:StartRound(who, idx)
end

for _, event in ipairs({ "CHAT_MSG_YELL", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_SAY" }) do
  ns.On(event, OnChat)
end

-- Test: send a line with your own name (no throttle).
function S:Test()
  local me = ns.Str(UnitName("player")) or "You"
  ns.Fire("CANNIBALIZE", me, "player")
end

-- Test a reaction, as if Thrallbane had just sent a random line.
function S:TestReaction()
  self:StartRound("Thrallbane", math.random(#self.LINES))
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
  if unit == "player" then
    ns.Fire("CANNIBALIZE", who, unit)     -- you send the first line
  elseif ns.db.react and S:IAmUndead() then
    S.waiting[who] = now                  -- react once their line is heard
  end
end

ns.On("UNIT_SPELLCAST_CHANNEL_START", OnCast)
ns.On("UNIT_SPELLCAST_SUCCEEDED", OnCast)

ns.Listen("LOGIN", function()
  S.name = SpellName(20577) or FALLBACK_NAME
  if type(ns.db.learnedID) == "number" then S.ids[ns.db.learnedID] = true end
end)
