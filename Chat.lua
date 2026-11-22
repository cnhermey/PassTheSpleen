-- Pass the Spleen: sends the lines. No button, and one message per line.
--
-- The chat is picked from where you are:
--   - inside a dungeon, raid or other instance, outside a boss fight: /yell
--     (an addon may yell there on its own)
--   - anywhere else (out in the world, or during a boss fight), in a group:
--     /party (instance chat in a dungeon-finder group)
--   - anywhere else, not in a group: /say
local _, ns = ...

local C = {
  sent = { YELL = 0, PARTY = 0, SAY = 0 },
}
ns.Chat = C

local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage

function C:InInstance()
  local inInstance = ns.Clean(ns.Try("IsInInstance", IsInInstance))
  return inInstance == true or inInstance == 1
end

function C:InBossFight()
  if not IsEncounterInProgress then return false end
  return ns.Clean(ns.Try("IsEncounterInProgress", IsEncounterInProgress)) == true
end

local function InGroup(category)
  if not IsInGroup then return false end
  return ns.Clean(ns.Try("IsInGroup", IsInGroup, category)) == true
end

-- "PARTY" or "INSTANCE_CHAT" if you're in a group, else nil.
local function PartyChat()
  local home, inst = LE_PARTY_CATEGORY_HOME, LE_PARTY_CATEGORY_INSTANCE
  if not home then return InGroup() and "PARTY" or nil end
  if InGroup(home) then return "PARTY" end
  if inst and InGroup(inst) then return "INSTANCE_CHAT" end
end

-- The chat type for here, and the kind it counts as ("YELL", "PARTY", "SAY").
function C:Pick()
  if self:InInstance() and not self:InBossFight() then return "YELL", "YELL" end
  local party = PartyChat()
  if party then return party, "PARTY" end
  return "SAY", "SAY"
end

-- Send `msg` once, on the chat for here.
function C:Deliver(msg)
  if not msg then return end
  local chatType, kind = self:Pick()
  local ok, err = pcall(send, msg, chatType)
  if ok then
    self.sent[kind] = self.sent[kind] + 1
    self.last = chatType
  else
    self.lastError = chatType .. ": " .. tostring(err)
    ns.Debug("send failed:", self.lastError)
  end
end

ns.Listen("CANNIBALIZE", function(who)
  C:Deliver(ns.Spleen:Line(who))
end)
