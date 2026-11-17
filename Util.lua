-- Pass the Spleen: shared helpers.
-- Every file receives the same private namespace table `ns` from the TOC loader.
local addonName, ns = ...

ns.ADDON_NAME = addonName

do
  local getMeta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  ns.VERSION = (getMeta and getMeta(addonName, "Version")) or "dev"
end

---------------------------------------------------------------------------
-- Secret values (12.x engine). WoW: Forever can hand back restricted values,
-- mostly in combat. Never compare, branch on, or format a secret.
---------------------------------------------------------------------------
function ns.IsSecret(v)
  return issecretvalue ~= nil and issecretvalue(v) == true
end

-- The value when it can be read, else nil.
function ns.Clean(v)
  if ns.IsSecret(v) then return nil end
  return v
end

-- A readable, non-empty string, else nil.
function ns.Str(v)
  if ns.IsSecret(v) or type(v) ~= "string" or v == "" then return nil end
  return v
end

---------------------------------------------------------------------------
-- Calls that may not exist or may fail on this client. Each place that fails
-- is reported once (with debug on), so one changed API never breaks the rest.
---------------------------------------------------------------------------
local reported = {}
local function Pack(...) return { n = select("#", ...), ... } end
function ns.Try(where, fn, ...)
  if type(fn) ~= "function" then return nil end
  local r = Pack(pcall(fn, ...))
  if not r[1] then
    if not reported[where] then
      reported[where] = true
      ns.Debug("API error in", where, tostring(r[2]))
    end
    return nil
  end
  return unpack(r, 2, r.n)
end

---------------------------------------------------------------------------
-- Output
---------------------------------------------------------------------------
-- Native look: messages look like Blizzard system messages (system chat
-- color, short "Pass the Spleen:" prefix).
local TAG = "Pass the Spleen: "

local function ToText(v)
  if ns.IsSecret(v) then return "<secret>" end
  return tostring(v)
end

local function SystemColor()
  local info = ChatTypeInfo and ChatTypeInfo.SYSTEM
  if info and info.r then return info.r, info.g, info.b end
  return 1, 1, 0
end

function ns.PrintLine(text)
  DEFAULT_CHAT_FRAME:AddMessage(text, SystemColor())
end

function ns.Print(...)
  local parts = {}
  for i = 1, select("#", ...) do
    parts[#parts + 1] = ToText((select(i, ...)))
  end
  ns.PrintLine(TAG .. table.concat(parts, " "))
end

function ns.Debug(...)
  if ns.db and ns.db.debug then
    ns.Print("[debug]", ...)
  end
end

---------------------------------------------------------------------------
-- Timers: Debounce restarts the timer on every request (runs after things
-- go quiet). Cancel stops a pending one.
---------------------------------------------------------------------------
local timers = {}
function ns.Debounce(key, delay, fn)
  if timers[key] then timers[key]:Cancel() end
  timers[key] = C_Timer.NewTimer(delay, function()
    timers[key] = nil
    fn()
  end)
end

function ns.Cancel(key)
  if timers[key] then
    timers[key]:Cancel()
    timers[key] = nil
  end
end
