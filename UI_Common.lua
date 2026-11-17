-- Pass the Spleen: shared look. Style rule (as Queb and Familiar): every
-- element should look like Blizzard's own UI, so colors come from Blizzard's
-- constants and art from Blizzard's textures, with fallbacks.
local _, ns = ...

local UI = {}
ns.UI = UI

local function Const(c, r, g, b)
  if type(c) == "table" and c.r then return c end
  return { r = r, g = g, b = b }
end
UI.GOLD  = Const(NORMAL_FONT_COLOR, 1, 0.82, 0)
UI.WHITE = Const(HIGHLIGHT_FONT_COLOR, 1, 1, 1)
UI.GRAY  = Const(GRAY_FONT_COLOR, 0.5, 0.5, 0.5)
UI.GREEN = Const(GREEN_FONT_COLOR, 0.1, 1, 0.1)
UI.RED   = Const(RED_FONT_COLOR, 1, 0.1, 0.1)

local function Hex(c)
  return string.format("ff%02x%02x%02x", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5))
end
function UI.Wrap(c, text) return "|c" .. Hex(c) .. text .. "|r" end

UI.ICON = "Interface\\Icons\\Ability_Racial_Cannibalize"

function UI.PlaySound(kit)
  if PlaySound and SOUNDKIT and SOUNDKIT[kit] then PlaySound(SOUNDKIT[kit]) end
end
