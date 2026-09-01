local addonName, NS = ...
local L = NS.L

local MinimapButton = {}

local floor = math.floor
local atan2 = math.atan2
local cos = math.cos
local sin = math.sin

local ORBIT_RADIUS = 80

local BUTTON_SIZE = 31

function MinimapButton:Create()
    if self.button then return end

    local btn = CreateFrame("Button", "NarcissusSirus_MinimapButton", Minimap)
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetMovable(true)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(20, 20)
    bg:SetPoint("TOPLEFT", 7, -5)
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(17, 17)
    icon:SetPoint("TOPLEFT", 7, -6)
    icon:SetTexture("Interface\\Icons\\INV_Chest_Chain_04")
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    btn.icon = icon

    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn.border = border

    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    local hl = btn:GetHighlightTexture()
    if hl then
        local A = NS.Styling.ACCENT_GLOW
        hl:SetVertexColor(A[1], A[2], A[3], 0.7)
    end

    self.button = btn

    local angle = (NS.db and NS.db.minimapAngle) or math.rad(220)
    if angle > 6.2832 then angle = math.rad(angle) end
    self:UpdatePosition(angle)

    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            NS:ToggleCharacterUI()
        elseif button == "RightButton" then
            NS:ToggleSettings()
        end
    end)

    btn:SetScript("OnDragStart", function(self)
        self:SetScript("OnUpdate", function()
            local mx, my = Minimap:GetCenter()
            if not mx then return end
            local cx, cy = GetCursorPosition()
            local scale = Minimap:GetEffectiveScale()
            if not scale or scale == 0 then return end
            cx, cy = cx / scale, cy / scale
            MinimapButton:UpdatePosition(atan2(cy - my, cx - mx))
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
    end)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("NarcissusSirus", NS.Styling.ACCENT_GLOW[1], NS.Styling.ACCENT_GLOW[2], NS.Styling.ACCENT_GLOW[3])
        GameTooltip:AddLine(L["ЛКМ: открыть окно персонажа"], 0.8, 0.8, 0.8)
        GameTooltip:AddLine(L["ПКМ: настройки"], 0.8, 0.8, 0.8)
        GameTooltip:AddLine(L["Перетащить: передвинуть по краю миникарты"], 0.5, 0.5, 0.55)
        GameTooltip:Show()
    end)

    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

function MinimapButton:UpdatePosition(angle)
    if not angle or not self.button then return end

    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER",
        cos(angle) * ORBIT_RADIUS, sin(angle) * ORBIT_RADIUS)

    if NS.db then
        NS.db.minimapAngle = floor(angle * 100 + 0.5) / 100
    end
end

function MinimapButton:Show()
    if not self.button then self:Create() end
    self.button:Show()
end

function MinimapButton:Hide()
    if self.button then
        self.button:Hide()
    end
end

function MinimapButton:Toggle()
    if not self.button then self:Create() end
    if self.button:IsShown() then
        self:Hide()
        if NS.db then NS.db.minimapButton = false end
    else
        self:Show()
        if NS.db then NS.db.minimapButton = true end
    end
end

NS.MinimapButton = MinimapButton
