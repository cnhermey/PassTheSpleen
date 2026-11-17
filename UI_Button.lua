-- Pass the Spleen: the yell button.
--
-- Forever (Midnight rules) only lets an addon /yell from a real click or key
-- press, and blocks addon chat inside instances. So the addon never yells on
-- its own: it shows the line on a Blizzard button, and your click sends it.
-- The button hides itself after a few seconds. Shift-drag to move it.
local _, ns = ...
local UI = ns.UI

local B = { sent = 0 }
ns.YellButton = B

local send = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage

local function Place(btn)
  btn:ClearAllPoints()
  local p = ns.db and ns.db.buttonPoint
  if type(p) == "table" and p[1] then
    btn:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  else
    btn:SetPoint("TOP", UIParent, "TOP", 0, -140)
  end
end

local function ShowTooltip(btn)
  GameTooltip:SetOwner(btn, "ANCHOR_BOTTOM")
  GameTooltip:SetText("Click to yell:", 1, 1, 1)
  if B.pending then
    local c = UI.GOLD
    GameTooltip:AddLine(B.pending, c.r, c.g, c.b, true)
  end
  local g = UI.GRAY
  GameTooltip:AddLine("Shift-drag to move.", g.r, g.g, g.b)
  GameTooltip:Show()
end

function B:Build()
  if self.frame then return self.frame end
  local btn = CreateFrame("Button", "PassTheSpleenButton", UIParent, "UIPanelButtonTemplate")
  btn:SetSize(240, 36)
  btn:SetFrameStrata("HIGH")
  btn:SetClampedToScreen(true)
  btn:SetMovable(true)
  btn:RegisterForDrag("LeftButton")

  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetSize(26, 26)
  icon:SetPoint("LEFT", btn, "LEFT", 6, 0)
  icon:SetTexture(UI.ICON)

  btn:SetText("Pass the Spleen!")
  local fs = btn:GetFontString()
  if fs then fs:SetFontObject("GameFontNormalLarge") end

  btn:SetScript("OnDragStart", function(self)
    if not IsShiftKeyDown() then return end
    self.dragging = true
    self:StartMoving()
  end)
  btn:SetScript("OnDragStop", function(self)
    if not self.dragging then return end
    self.dragging = false
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint(1)
    ns.db.buttonPoint = { point, relPoint, x, y }
  end)
  btn:SetScript("OnClick", function()
    if IsShiftKeyDown() then return end -- Shift is for moving
    B:Send()
  end)
  btn:SetScript("OnEnter", ShowTooltip)
  btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
  btn:Hide()

  self.frame = btn
  return btn
end

-- Show the button with this line; it hides after buttonSeconds.
function B:Offer(msg)
  local btn = self:Build()
  self.pending = msg
  Place(btn)
  btn:Show()
  if GameTooltip:IsOwned(btn) then ShowTooltip(btn) end
  if ns.db.sound then UI.PlaySound("RAID_WARNING") end
  ns.Debounce("yellButton", ns.db.buttonSeconds or 12, function() B:Dismiss() end)
end

function B:Dismiss()
  self.pending = nil
  ns.Cancel("yellButton")
  if self.frame then
    self.frame:Hide()
    if GameTooltip:IsOwned(self.frame) then GameTooltip:Hide() end
  end
end

-- Called from the click, so the game allows the yell.
function B:Send()
  local msg = self.pending
  self:Dismiss()
  if not msg then return end
  local ok, err = pcall(send, msg, "YELL")
  if ok then
    self.sent = self.sent + 1
  else
    self.lastError = tostring(err)
    ns.Debug("yell failed:", self.lastError)
  end
end

function B:ResetPosition()
  ns.db.buttonPoint = nil
  if self.frame then Place(self.frame) end
end

ns.Listen("CANNIBALIZE", function(who)
  B:Offer(ns.Spleen:Line(who))
end)
