-- Pass the Spleen: event dispatch, internal message bus, saved settings.
local addonName, ns = ...

---------------------------------------------------------------------------
-- One event frame, many handlers.
-- Events that may not exist on this client are registered with pcall.
---------------------------------------------------------------------------
local frame = CreateFrame("Frame")
local handlers = {}

frame:SetScript("OnEvent", function(_, event, ...)
  local list = handlers[event]
  if not list then return end
  for i = 1, #list do
    list[i](event, ...)
  end
end)

function ns.On(event, fn)
  if not handlers[event] then
    handlers[event] = {}
    if not pcall(frame.RegisterEvent, frame, event) then
      ns.Debug("Event not available:", event)
    end
  end
  table.insert(handlers[event], fn)
end

---------------------------------------------------------------------------
-- Internal message bus (not WoW events).
---------------------------------------------------------------------------
local listeners = {}

function ns.Listen(msg, fn)
  listeners[msg] = listeners[msg] or {}
  table.insert(listeners[msg], fn)
end

function ns.Fire(msg, ...)
  local list = listeners[msg]
  if not list then return end
  for i = 1, #list do
    list[i](...)
  end
end

---------------------------------------------------------------------------
-- Saved settings (account-wide)
---------------------------------------------------------------------------
ns.DEFAULTS = {
  enabled = true,            -- yell for Cannibalize (yours, or reactions to your party's)
  includeSelf = true,        -- yell the first line for your own Cannibalize
  react = true,              -- if you're Undead, react to a party member's line
  learnedID = nil,           -- Cannibalize's spell ID on this client, once seen
  debug = false,
}

ns.On("ADDON_LOADED", function(_, name)
  if name ~= addonName then return end
  PassTheSpleenDB = PassTheSpleenDB or {}
  local db = PassTheSpleenDB
  for k, v in pairs(ns.DEFAULTS) do
    if db[k] == nil then db[k] = v end
  end
  -- v0.3.0 dropped the yell button and its settings.
  if (db.schema or 1) < 2 then
    db.sound, db.buttonSeconds, db.buttonPoint = nil, nil, nil
  end
  db.schema = 2
  ns.db = db
  ns.Fire("INIT")
end)

ns.On("PLAYER_LOGIN", function()
  ns.loggedIn = true
  ns.Fire("LOGIN")
end)
