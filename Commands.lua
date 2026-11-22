-- Pass the Spleen: /spleen. Style rules: Blizzard system-message look
-- (ns.Print / ns.PrintLine) and short phrases.
local _, ns = ...
local P = function(text) ns.PrintLine(text) end

local function Yes(v) return ns.UI.Wrap(ns.UI.GREEN, v) end
local function No(v) return ns.UI.Wrap(ns.UI.RED, v) end

local function Has(path)
  local v = _G
  for part in string.gmatch(path, "[^%.]+") do
    if type(v) ~= "table" then return false end
    v = v[part]
  end
  return v ~= nil
end

-- Developer report: what this client offers, and what the addon has seen.
local function Probe()
  local build, _, _, iface = GetBuildInfo()
  ns.Print("Probe: build", build, "interface", iface, "version", ns.VERSION)
  local apis = {
    "C_Spell.GetSpellName", "GetSpellInfo", "C_ChatInfo.SendChatMessage", "SendChatMessage",
    "issecretvalue", "IsInInstance", "IsEncounterInProgress", "UnitRace", "Settings.RegisterCanvasLayoutCategory", "MinimalSliderWithSteppersMixin",
  }
  local line = {}
  for _, name in ipairs(apis) do
    line[#line + 1] = Has(name) and Yes(name) or No(name)
    if #line == 4 then P("  " .. table.concat(line, "  ")); line = {} end
  end
  if #line > 0 then P("  " .. table.concat(line, "  ")) end

  local S, C = ns.Spleen, ns.Chat
  local ids = {}
  for id in pairs(S.ids) do ids[#ids + 1] = tostring(id) end
  table.sort(ids)
  P("  Cannibalize: name " .. tostring(S.name) .. " · IDs " .. table.concat(ids, ", ")
    .. " · learned " .. tostring(ns.db.learnedID or "not yet"))
  P("  Seen " .. S.seen .. " · sent: yell " .. C.sent.YELL .. ", party " .. C.sent.PARTY .. ", say " .. C.sent.SAY
    .. " · reactions " .. S.reacted .. " · you're Undead " .. tostring(S:IAmUndead()))
  P("  Chat here: " .. string.lower((C:Pick())) .. (C.lastError and (" · last error " .. No(C.lastError)) or ""))
  P("  In instance " .. tostring(C:InInstance()) .. " · boss fight " .. tostring(C:InBossFight())
    .. " · in party " .. tostring(ns.Clean(IsInGroup and IsInGroup()))
    .. " · settings page " .. tostring(ns.Options.category ~= nil))
end

local function Help()
  ns.Print("commands:")
  P("  /spleen: open the settings")
  P("  /spleen test: send a line with your name")
  P("  /spleen react: test a reaction, as if Thrallbane had sent a line")
  P("  /spleen on | off: turn it on or off")
  P("  /spleen probe: developer report")
end

SLASH_PASSTHESPLEEN1 = "/spleen"
SLASH_PASSTHESPLEEN2 = "/passthespleen"
SlashCmdList.PASSTHESPLEEN = function(msg)
  if not ns.db then return end
  local cmd = string.lower(string.match(msg or "", "^%s*(%S*)") or "")
  if cmd == "" or cmd == "settings" or cmd == "options" or cmd == "config" then
    ns.Options:Open()
  elseif cmd == "test" then
    ns.Spleen:Test()
  elseif cmd == "react" then
    ns.Spleen:TestReaction()
  elseif cmd == "on" or cmd == "off" then
    ns.Options:Set("enabled", cmd == "on")
    ns.Print(cmd == "on" and "On." or "Off.")
  elseif cmd == "probe" then
    Probe()
  else
    Help()
  end
end

ns.Listen("LOGIN", function()
  ns.Debug("v" .. ns.VERSION .. " loaded. /spleen for the settings.")
end)
