-- Pass the Spleen: sends the yells. No button.
--
-- Each line goes out on the first chat that works, in this order:
--   1. /yell
--   2. /party (instance chat in a dungeon-finder group), if you're in a group
--   3. /say
-- Forever doesn't always let an addon talk (out in the world, /yell and /say
-- need a real key press or click). A refused message doesn't raise an error,
-- so after each try the addon waits to see its own message in chat. If the
-- game reports the action as blocked (ADDON_ACTION_BLOCKED), or the message
-- doesn't show up within ECHO_WAIT seconds, it moves to the next chat.
-- A chat that's blocked here (in the world, in an instance, in a boss fight)
-- is skipped for the rest of the session, so you don't wait on it every time.
-- If nothing works, the line is shown in your chat window only.
local _, ns = ...

local C = {
  ORDER = { "YELL", "PARTY", "SAY" },
  ECHO_WAIT = 1.5,           -- seconds to wait for your own message in chat
  STRIKES = 2,               -- missing echoes before a chat counts as blocked
  sent = { YELL = 0, PARTY = 0, SAY = 0 },
  local_only = 0,            -- lines no chat would take
  blocked = {},              -- [where][kind] = true
  strikes = {},              -- [where][kind] = missing echoes in a row
  queue = {},
}
ns.Chat = C

local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage

-- Chat events that show your own message, and the kind they confirm.
local ECHO = {
  CHAT_MSG_YELL = "YELL",
  CHAT_MSG_PARTY = "PARTY",
  CHAT_MSG_PARTY_LEADER = "PARTY",
  CHAT_MSG_INSTANCE_CHAT = "PARTY",
  CHAT_MSG_INSTANCE_CHAT_LEADER = "PARTY",
  CHAT_MSG_SAY = "SAY",
}
C.EVENTS = ECHO

---------------------------------------------------------------------------
-- Where are we, and which chat type is "party" here?
---------------------------------------------------------------------------
function C:InInstance()
  local inInstance = ns.Clean(ns.Try("IsInInstance", IsInInstance))
  return inInstance == true or inInstance == 1
end

function C:InBossFight()
  if not IsEncounterInProgress then return false end
  return ns.Clean(ns.Try("IsEncounterInProgress", IsEncounterInProgress)) == true
end

function C:Where()
  if not self:InInstance() then return "world" end
  if self:InBossFight() then return "boss" end
  return "instance"
end

local function InGroup(category)
  if not IsInGroup then return false end
  return ns.Clean(ns.Try("IsInGroup", IsInGroup, category)) == true
end

-- The chat type to send `kind` on, or nil if it can't be used right now.
local function ChatType(kind)
  if kind ~= "PARTY" then return kind end
  local home, inst = LE_PARTY_CATEGORY_HOME, LE_PARTY_CATEGORY_INSTANCE
  if home then
    if InGroup(home) then return "PARTY" end
    if inst and InGroup(inst) then return "INSTANCE_CHAT" end
    return nil
  end
  return InGroup() and "PARTY" or nil
end

local function Bucket(t, where)
  t[where] = t[where] or {}
  return t[where]
end

---------------------------------------------------------------------------
-- Sending, one line at a time.
---------------------------------------------------------------------------
local Try, Next

local function Finish(job)
  ns.Cancel("chatEcho")
  C.current = nil
  Next()
end

local function Blocked(job, why)
  ns.Cancel("chatEcho")
  Bucket(C.blocked, job.where)[job.kind] = true
  C.lastError = job.kind .. ": " .. why
  ns.Debug("/" .. string.lower(job.kind), "blocked here (" .. job.where .. "):", why)
  job.step = job.step + 1
  Try(job)
end

local function NoEcho(job)
  local s = Bucket(C.strikes, job.where)
  s[job.kind] = (s[job.kind] or 0) + 1
  ns.Debug("/" .. string.lower(job.kind), "didn't show up in chat")
  if s[job.kind] >= C.STRIKES then
    Blocked(job, "never showed up in chat")
  else
    job.step = job.step + 1
    Try(job)
  end
end

Try = function(job)
  C.current = job
  local blocked = Bucket(C.blocked, job.where)
  while job.step <= #C.ORDER do
    local kind = C.ORDER[job.step]
    local chatType = ChatType(kind)
    if chatType and not blocked[kind] then
      job.kind, job.chatType, job.refused = kind, chatType, nil
      C.sending = true
      local ok, err = pcall(send, job.msg, chatType)
      C.sending = false
      if not ok then
        Blocked(job, tostring(err))
        return
      elseif job.refused then
        Blocked(job, job.refused)
        return
      end
      ns.Debounce("chatEcho", C.ECHO_WAIT, function()
        if C.current == job then NoEcho(job) end
      end)
      return
    end
    job.step = job.step + 1
  end
  -- No chat would take it: show it to you, so it's not lost.
  C.local_only = C.local_only + 1
  ns.Print(job.msg .. ns.UI.Wrap(ns.UI.GRAY, " (only you can see this)"))
  Finish(job)
end

Next = function()
  if C.current then return end
  local job = table.remove(C.queue, 1)
  if not job then return end
  job.step = 1
  job.where = C:Where()
  Try(job)
end

-- Send `msg` on the first chat that works.
function C:Deliver(msg)
  if not msg then return end
  self.queue[#self.queue + 1] = { msg = msg }
  Next()
end

---------------------------------------------------------------------------
-- Did it go out?
---------------------------------------------------------------------------
local function OnBlocked(_, addon, func)
  local job = C.current
  if not job or ns.Str(addon) ~= ns.ADDON_NAME then return end
  local why = "action blocked" .. (ns.Str(func) and (" (" .. func .. ")") or "")
  if C.sending then
    job.refused = why            -- reported while sending; Try handles it
  elseif job.kind then
    Blocked(job, why)
  end
end
ns.On("ADDON_ACTION_BLOCKED", OnBlocked)
ns.On("ADDON_ACTION_FORBIDDEN", OnBlocked)

local function Short(name)
  name = ns.Str(name)
  if not name then return nil end
  return (name:match("^([^%-]+)")) or name
end
C.Short = Short

local function OnEcho(event, text, sender)
  local job = C.current
  if not job or not job.kind or ECHO[event] ~= job.kind then return end
  text = ns.Str(text)
  local who = Short(sender)
  local me = ns.Str(UnitName("player"))
  -- Text or name can be secret inside instances; then any message of this
  -- kind counts as ours.
  if text and text ~= job.msg then return end
  if who and me and who ~= me then return end
  C.sent[job.kind] = C.sent[job.kind] + 1
  Bucket(C.strikes, job.where)[job.kind] = 0
  Finish(job)
end
for event in pairs(ECHO) do ns.On(event, OnEcho) end

-- For /spleen probe: what's blocked where.
function C:BlockedText()
  local parts = {}
  for _, where in ipairs({ "world", "instance", "boss" }) do
    local list = {}
    for _, kind in ipairs(self.ORDER) do
      if self.blocked[where] and self.blocked[where][kind] then list[#list + 1] = string.lower(kind) end
    end
    if #list > 0 then parts[#parts + 1] = where .. ": " .. table.concat(list, ", ") end
  end
  return #parts > 0 and table.concat(parts, "; ") or "none"
end

ns.Listen("CANNIBALIZE", function(who)
  C:Deliver(ns.Spleen:Line(who))
end)
