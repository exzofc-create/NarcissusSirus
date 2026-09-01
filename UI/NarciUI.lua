local addonName, NS = ...
local L = NS.L

local NarciUI = {}
NS.NarciUI = NarciUI

local format = string.format
local max = math.max
local min = math.min

local SLOT_SIZE = 48
local SLOT_NAME_MAX_CHARS = 24
local MODEL_WIDTH = 440
local MODEL_HEIGHT = 480
local BOTTOM_Y = -252
local SLOT_GAP = 70

local TOOLBAR_INDICATOR_Y = 4

local ARC_CURVE = 90
local ARC_BASE_LEFT = -580
local ARC_BASE_RIGHT = 200
local ARC_TOP_Y = 230
local NUM_SIDE_SLOTS = 8
local MODEL_X = (ARC_BASE_LEFT + ARC_BASE_RIGHT) / 2

local function getArcX(baseX, slotIndex, isRight)
    local t = (slotIndex - 1) / (NUM_SIDE_SLOTS - 1)
    local curve = 1 - (2 * t - 1) ^ 2
    local dir = isRight and 1 or -1
    return baseX + dir * ARC_CURVE * curve
end

local SLOT_LAYOUT = {}
local leftIds = { 1, 2, 3, 15, 5, 4, 19, 9 }
local leftNames = { "HeadSlot", "NeckSlot", "ShoulderSlot", "BackSlot", "ChestSlot", "ShirtSlot", "TabardSlot", "WristSlot" }
for i = 1, NUM_SIDE_SLOTS do
    SLOT_LAYOUT[i] = {
        id = leftIds[i], name = leftNames[i],
        x = getArcX(ARC_BASE_LEFT, i, false),
        y = ARC_TOP_Y - (i - 1) * SLOT_GAP,
        side = "LEFT",
    }
end
local rightIds = { 10, 6, 7, 8, 11, 12, 13, 14 }
local rightNames = { "HandsSlot", "WaistSlot", "LegsSlot", "FeetSlot", "Finger0Slot", "Finger1Slot", "Trinket0Slot", "Trinket1Slot" }
for i = 1, NUM_SIDE_SLOTS do
    SLOT_LAYOUT[NUM_SIDE_SLOTS + i] = {
        id = rightIds[i], name = rightNames[i],
        x = getArcX(ARC_BASE_RIGHT, i, true),
        y = ARC_TOP_Y - (i - 1) * SLOT_GAP,
        side = "RIGHT",
    }
end
local arcMidX = (ARC_BASE_LEFT + ARC_BASE_RIGHT) / 2
tinsert(SLOT_LAYOUT, { id = 16, name = "MainHandSlot",     x = arcMidX - 90, y = BOTTOM_Y + 15, side = "BOTTOM" })
tinsert(SLOT_LAYOUT, { id = 17, name = "SecondaryHandSlot",x = arcMidX,      y = BOTTOM_Y - 10, side = "BOTTOM" })
tinsert(SLOT_LAYOUT, { id = 18, name = "RangedSlot",       x = arcMidX + 90, y = BOTTOM_Y + 15, side = "BOTTOM" })

local MAX_BASE_DIM = 0.72

local LABEL_PAD      = 26
local LABEL_PER_CHAR = 6.5
local TOP_BAR_HEIGHT = 82
local TOOLBAR_TOP    = 98
local BOTTOM_LABEL   = 28
local SCENE_MARGIN   = 8
local MIN_AUTO_SCALE = 0.55

function NarciUI:GetAutoScale()
    local w = UIParent:GetWidth() or 1024
    local h = UIParent:GetHeight() or 768
    local half = SLOT_SIZE / 2
    local chars = (NS.db and NS.db.nameLength) or SLOT_NAME_MAX_CHARS
    local labelSpan = LABEL_PAD + chars * LABEL_PER_CHAR
    if NS.db and NS.db.showItemNames == false then labelSpan = 0 end

    local leftExtent = -ARC_BASE_LEFT + ARC_CURVE + half + labelSpan
    local rightExtent = ARC_BASE_RIGHT + ARC_CURVE + half + labelSpan
    local S = NS.Styling
    local panelColumn = (S and S.PANEL_WIDTH or 440)
                        - (S and S.PANEL_X or -8) + 16

    local needWidth = 2 * max(leftExtent, rightExtent + panelColumn)
    local needHeight = 2 * max(
        ARC_TOP_Y + half + TOP_BAR_HEIGHT + SCENE_MARGIN,
        -BOTTOM_Y + 10 + half + BOTTOM_LABEL + TOOLBAR_TOP + SCENE_MARGIN)

    local scale = min(1, w / needWidth, h / needHeight)
    return max(MIN_AUTO_SCALE, scale)
end

function NarciUI:ApplyScale()
    local mf = self.mainFrame
    if not mf then return end
    if InCombatLockdown() then
        self._scalePending = true
        return
    end
    self._scalePending = nil

    local scale = NS.db and NS.db.scaleOverride
    if not scale or scale <= 0 then scale = self:GetAutoScale() end
    self._appliedScale = scale

    mf:SetScale(scale)
    if mf.slotFrames then
        for _, sf in pairs(mf.slotFrames) do sf:SetScale(scale) end
    end
end

function NarciUI:ApplyWorldDim()
    local ov = self.edgeVignette
    if not ov or not ov.baseDim then return end
    local amount = (NS.db and NS.db.worldDim) or 0
    amount = max(0, min(100, amount)) / 100
    ov.baseDim:SetVertexColor(0.015, 0.015, 0.03, MAX_BASE_DIM * amount)
end

function NarciUI:SetSceneVisible(show)
    local mf = self.mainFrame
    self.sceneHidden = (not show) or nil
    if not mf then return end

    if mf.model then
        if show then mf.model:Show() else mf.model:Hide() end
    end

    if mf.backlight then
        if show then
            self:ApplyBacklight()
        else
            for i = 1, #mf.backlight do mf.backlight[i]:Hide() end
        end
    end

    if mf.slotFrames then
        for _, sf in pairs(mf.slotFrames) do
            if show then
                if not sf._hiddenEmpty then sf:Show() end
            else
                sf:Hide()
            end
        end
    end

    if NS.EquipInfo then
        if show then NS.EquipInfo:Show() else NS.EquipInfo:Hide() end
    end
end

function NarciUI:ApplyBacklight()
    local mf = self.mainFrame
    local parts = mf and mf.backlight
    if not parts then return end
    local on = not NS.db or NS.db.modelBacklight ~= false
    for i = 1, #parts do
        if on then parts[i]:Show() else parts[i]:Hide() end
    end
end

function NarciUI:Create()
    if self.mainFrame then return end
    local mf = CreateFrame("Frame", "NarcissusSirus_MainFrame", UIParent)
    mf:SetAllPoints(UIParent)
    mf:SetFrameStrata("FULLSCREEN_DIALOG")
    mf:SetFrameLevel(200)
    mf:Hide()

    tinsert(UISpecialFrames, "NarcissusSirus_MainFrame")
    mf:SetScript("OnHide", function()
        if NarciUI.isShown then NarciUI:Hide() end
    end)

    local NUM_STRIPS = 30
    local STRIP_SIZE = 8
    local MAX_ALPHA = 0.85
    local tex = "Interface\\Buttons\\WHITE8x8"
    local ov = CreateFrame("Frame", nil, mf)
    ov:SetAllPoints(mf)
    ov:SetFrameStrata("BACKGROUND")
    ov:SetFrameLevel(0)

    local baseDim = ov:CreateTexture(nil, "BACKGROUND", nil, -2)
    baseDim:SetAllPoints(mf)
    baseDim:SetTexture(tex)
    baseDim:SetVertexColor(0.015, 0.015, 0.03, 0)
    ov.baseDim = baseDim

    for i = 1, NUM_STRIPS do
        local t = ov:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(tex)
        t:SetPoint("TOPLEFT", mf, "TOPLEFT", 0, -(i - 1) * STRIP_SIZE)
        t:SetPoint("TOPRIGHT", mf, "TOPRIGHT", 0, -(i - 1) * STRIP_SIZE)
        t:SetHeight(STRIP_SIZE)
        t:SetVertexColor(0.02, 0.02, 0.04, MAX_ALPHA * (1 - (i - 1) / NUM_STRIPS))
    end
    for i = 1, NUM_STRIPS do
        local t = ov:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(tex)
        t:SetPoint("BOTTOMLEFT", mf, "BOTTOMLEFT", 0, (i - 1) * STRIP_SIZE)
        t:SetPoint("BOTTOMRIGHT", mf, "BOTTOMRIGHT", 0, (i - 1) * STRIP_SIZE)
        t:SetHeight(STRIP_SIZE)
        t:SetVertexColor(0.02, 0.02, 0.04, MAX_ALPHA * (1 - (i - 1) / NUM_STRIPS))
    end
    for i = 1, NUM_STRIPS do
        local t = ov:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(tex)
        t:SetPoint("TOPLEFT", mf, "TOPLEFT", (i - 1) * STRIP_SIZE, 0)
        t:SetPoint("BOTTOMLEFT", mf, "BOTTOMLEFT", (i - 1) * STRIP_SIZE, 0)
        t:SetWidth(STRIP_SIZE)
        t:SetVertexColor(0.02, 0.02, 0.04, MAX_ALPHA * (1 - (i - 1) / NUM_STRIPS))
    end
    for i = 1, NUM_STRIPS do
        local t = ov:CreateTexture(nil, "BACKGROUND")
        t:SetTexture(tex)
        t:SetPoint("TOPRIGHT", mf, "TOPRIGHT", -(i - 1) * STRIP_SIZE, 0)
        t:SetPoint("BOTTOMRIGHT", mf, "BOTTOMRIGHT", -(i - 1) * STRIP_SIZE, 0)
        t:SetWidth(STRIP_SIZE)
        t:SetVertexColor(0.02, 0.02, 0.04, MAX_ALPHA * (1 - (i - 1) / NUM_STRIPS))
    end
    self.edgeVignette = ov
    self:ApplyWorldDim()

    local GLOW_STRIPS = 22
    local GLOW_WIDTH = 560
    local GLOW_HEIGHT = 660
    local GLOW_PEAK = 0.16
    local GLOW_R, GLOW_G, GLOW_B = 0.34, 0.44, 0.62
    local stripHeight = GLOW_HEIGHT / GLOW_STRIPS
    mf.backlight = {}
    for i = 1, GLOW_STRIPS do
        local t = (i - 0.5) / GLOW_STRIPS
        local a = GLOW_PEAK * math.sin(t * math.pi)
        if a > 0.002 then
            local y = GLOW_HEIGHT / 2 - (i - 1) * stripHeight
            for half = 1, 2 do
                local g = mf:CreateTexture(nil, "BACKGROUND")
                g:SetTexture(tex)
                g:SetBlendMode("ADD")
                g:SetHeight(stripHeight + 1)
                g:SetWidth(GLOW_WIDTH / 2)
                if half == 1 then
                    g:SetPoint("TOPRIGHT", mf, "CENTER", MODEL_X, y)
                    g:SetGradientAlpha("Horizontal",
                        GLOW_R, GLOW_G, GLOW_B, 0, GLOW_R, GLOW_G, GLOW_B, a)
                else
                    g:SetPoint("TOPLEFT", mf, "CENTER", MODEL_X, y)
                    g:SetGradientAlpha("Horizontal",
                        GLOW_R, GLOW_G, GLOW_B, a, GLOW_R, GLOW_G, GLOW_B, 0)
                end
                mf.backlight[#mf.backlight + 1] = g
            end
        end
    end
    if NS.db and NS.db.modelBacklight == false then
        for i = 1, #mf.backlight do mf.backlight[i]:Hide() end
    end

    local model = CreateFrame("PlayerModel", "NarcissusSirus_MainModel", mf)
    model:SetSize(MODEL_WIDTH, MODEL_HEIGHT)
    model:SetPoint("CENTER", mf, "CENTER", MODEL_X, 0)
    model:SetUnit("player")
    model:SetFacing(0.4)
    pcall(model.SetPortraitZoom, model, 0.85)
    pcall(model.SetCamDistanceScale, model, 0.9)
    pcall(model.SetPosition, model, 0, 0, 0)
    model:SetFrameLevel(mf:GetFrameLevel() + 1)
    mf.model = model

    mf.slotFrames = {}
    self._slotLayout = SLOT_LAYOUT
    for _, slotInfo in ipairs(SLOT_LAYOUT) do
        local slotFrame = self:CreateSlotFrame(mf, slotInfo)
        slotFrame._origX = slotInfo.x
        slotFrame._origY = slotInfo.y
        mf.slotFrames[slotInfo.id] = slotFrame
    end

    local topBar = CreateFrame("Frame", nil, mf)
    topBar:SetHeight(82)
    topBar:SetPoint("TOPLEFT", mf, "TOPLEFT", 0, 0)
    topBar:SetPoint("TOPRIGHT", mf, "TOPRIGHT", 0, 0)

    local playerName = topBar:CreateFontString(nil, "OVERLAY")
    playerName:SetFont("Fonts\\FRIZQT__.TTF", 22, "OUTLINE")
    playerName:SetPoint("TOP", topBar, "TOP", 0, -12)
    mf.playerName = playerName

    local classIcon = topBar:CreateTexture(nil, "OVERLAY")
    classIcon:SetSize(20, 20)
    classIcon:SetPoint("RIGHT", playerName, "LEFT", -8, 0)
    mf.classIcon = classIcon

    local playerDetails = topBar:CreateFontString(nil, "OVERLAY")
    playerDetails:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    playerDetails:SetTextColor(0.55, 0.55, 0.60)
    playerDetails:SetPoint("TOP", playerName, "BOTTOM", 0, -4)
    mf.playerDetails = playerDetails

    local function HeaderRule(left)
        local t = topBar:CreateTexture(nil, "ARTWORK")
        t:SetHeight(1)
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        local A = NS.Styling.ACCENT
        if left then
            t:SetPoint("BOTTOMLEFT", topBar, "BOTTOMLEFT", 60, 0)
            t:SetPoint("BOTTOMRIGHT", topBar, "BOTTOM", 0, 0)
            t:SetGradientAlpha("Horizontal", A[1], A[2], A[3], 0, A[1], A[2], A[3], 0.45)
        else
            t:SetPoint("BOTTOMLEFT", topBar, "BOTTOM", 0, 0)
            t:SetPoint("BOTTOMRIGHT", topBar, "BOTTOMRIGHT", -60, 0)
            t:SetGradientAlpha("Horizontal", A[1], A[2], A[3], 0.45, A[1], A[2], A[3], 0)
        end
    end
    HeaderRule(true)
    HeaderRule(false)

    local sweep = CreateFrame("Frame", nil, mf)
    sweep:SetPoint("BOTTOMLEFT", topBar, "BOTTOMLEFT", 0, 0)
    sweep:SetPoint("BOTTOMRIGHT", topBar, "BOTTOMRIGHT", 0, 0)
    sweep:SetHeight(2)
    sweep:Hide()
    local G = NS.Styling.ACCENT_GLOW
    local function SweepHalf(toLeft)
        local t = sweep:CreateTexture(nil, "OVERLAY")
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        t:SetBlendMode("ADD")
        t:SetHeight(2)
        t:SetWidth(1)
        if toLeft then
            t:SetPoint("RIGHT", sweep, "CENTER", 0, 0)
            t:SetGradientAlpha("Horizontal", G[1], G[2], G[3], 0, G[1], G[2], G[3], 0.9)
        else
            t:SetPoint("LEFT", sweep, "CENTER", 0, 0)
            t:SetGradientAlpha("Horizontal", G[1], G[2], G[3], 0.9, G[1], G[2], G[3], 0)
        end
        return t
    end
    sweep.left = SweepHalf(true)
    sweep.right = SweepHalf(false)
    mf.introSweep = sweep

    local specLine = topBar:CreateFontString(nil, "OVERLAY")
    specLine:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    specLine:SetPoint("TOP", playerDetails, "BOTTOM", 0, -3)
    mf.specLine = specLine

    local iLvlDisplay = CreateFrame("Frame", nil, topBar)
    iLvlDisplay:SetSize(120, 40)
    iLvlDisplay:SetPoint("TOPRIGHT", topBar, "TOPRIGHT", -60, -10)
    local iLvlLabel = iLvlDisplay:CreateFontString(nil, "OVERLAY")
    iLvlLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    iLvlLabel:SetTextColor(0.40, 0.42, 0.50)
    iLvlLabel:SetPoint("TOP", iLvlDisplay, "TOP", 0, -2)
    iLvlLabel:SetText(L["УРОВЕНЬ ПРЕДМЕТОВ"])
    local iLvlValue = iLvlDisplay:CreateFontString(nil, "OVERLAY")
    iLvlValue:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    iLvlValue:SetTextColor(NS.Styling.GOLD[1], NS.Styling.GOLD[2], NS.Styling.GOLD[3])
    iLvlValue:SetPoint("TOP", iLvlLabel, "BOTTOM", 0, -2)
    mf.iLvlValue = iLvlValue

    local closeBtn = CreateFrame("Button", nil, mf)
    closeBtn:SetSize(32, 32)
    closeBtn:SetPoint("TOPRIGHT", mf, "TOPRIGHT", -16, -10)
    local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
    closeBg:SetAllPoints()
    closeBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    closeBg:SetVertexColor(0.12, 0.12, 0.18, 0.85)
    local closeBorder = CreateFrame("Frame", nil, closeBtn)
    closeBorder:SetPoint("TOPLEFT", -1, 1)
    closeBorder:SetPoint("BOTTOMRIGHT", 1, -1)
    closeBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    closeBorder:SetBackdropBorderColor(0.6, 0.2, 0.2, 0.8)
    closeBorder:EnableMouse(false)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY")
    closeText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    closeText:SetTextColor(0.9, 0.3, 0.3)
    closeText:SetPoint("CENTER")
    closeText:SetText("X")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
    closeBtn:GetHighlightTexture():SetVertexColor(0.5, 0.1, 0.1, 0.3)
    closeBtn:SetScript("OnClick", function() NarciUI:Hide() end)
    closeBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine(L["Закрыть (C / Esc)"], 1, 0.3, 0.3)
        GameTooltip:Show()
    end)
    closeBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    local toolbar = CreateFrame("Frame", nil, mf)
    toolbar:SetHeight(52)
    toolbar:SetPoint("BOTTOM", mf, "BOTTOM", 0, 46)
    mf.toolbar = toolbar

    local toolbarButtons = {
        { label = L["Статы"],      panel = "StatsPanel",    icon = "Interface\\Icons\\Ability_Warrior_OffensiveStance", func = function() NS:ToggleStatsPanel() end },
        { label = L["Усиления"],   panel = "Enhancements",  icon = "Interface\\Icons\\Spell_Holy_BlessingOfStrength",  func = function() NS:ToggleEnhancements() end },
        { label = L["Таланты"],    panel = "TalentPanel",   glyph = "tree",  func = function() NS:ToggleTalentPanel() end },
        { label = L["Титулы"],     panel = "TitleManager",  icon = "Interface\\Icons\\Achievement_BG_winWSG",           func = function() NS:ToggleTitleManager() end },
        { label = L["Быстрые наборы"], panel = "OutfitManager", icon = "Interface\\Icons\\INV_Chest_Chain_04",          func = function() NS:ToggleOutfitManager() end },
        { label = L["Профессии"],  panel = "ProfessionsPanel",
          icon = select(3, GetSpellInfo(2018)) or "Interface\\Icons\\Trade_BlackSmithing",
          func = function() NS:ToggleProfessions() end },
        { label = L["Настройки"],  glyph = "sliders",                                          func = function() NS:ToggleSettings() end },
    }
    mf.toolbarButtons = {}
    local numBtns = #toolbarButtons
    local btnSpacing = 52
    local S = NS.Styling

    toolbar:SetWidth(numBtns * btnSpacing + 18)
    toolbar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    toolbar:SetBackdropColor(S.BG_DARK[1], S.BG_DARK[2], S.BG_DARK[3], 0.85)
    toolbar:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    S.CreateShadow(toolbar, 4, 0.35)
    S.ApplyTabChrome(toolbar)

    local toolbarCaption = mf:CreateFontString(nil, "OVERLAY")
    toolbarCaption:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    toolbarCaption:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    toolbarCaption:SetPoint("BOTTOM", toolbar, "TOP", 0, 7)
    mf.toolbarCaption = toolbarCaption

    for i, btnInfo in ipairs(toolbarButtons) do
        local btn = CreateFrame("Button", nil, toolbar)
        btn:SetSize(40, 40)
        btn:SetPoint("CENTER", toolbar, "CENTER", (i - (numBtns + 1) / 2) * btnSpacing, 3)

        local btnBg = btn:CreateTexture(nil, "BACKGROUND")
        btnBg:SetAllPoints()
        btnBg:SetTexture("Interface\\Buttons\\WHITE8x8")
        btnBg:SetVertexColor(0.06, 0.07, 0.12, 0.8)

        local icon = btn:CreateTexture(nil, "ARTWORK")
        icon:SetSize(26, 26)
        icon:SetPoint("CENTER")
        if btnInfo.icon then
            icon:SetTexture(btnInfo.icon)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        end

        if btnInfo.glyph then
            local g = CreateFrame("Frame", nil, btn)
            g:SetAllPoints()

            local function Bar(w, h, x, y, r, gr, b, a)
                local t = g:CreateTexture(nil, "ARTWORK")
                t:SetSize(w, h)
                t:SetPoint("CENTER", g, "CENTER", x, y)
                t:SetTexture("Interface\\Buttons\\WHITE8x8")
                t:SetVertexColor(r, gr, b, a)
                return t
            end

            if btnInfo.glyph == "sliders" then
                local rows = { { y = 6, x = -3 }, { y = 0, x = 4 }, { y = -6, x = -1 } }
                for _, row in ipairs(rows) do
                    Bar(18, 2, 0, row.y, 0.80, 0.82, 0.88, 0.9)
                    Bar(4, 8, row.x, row.y, S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
                end
            elseif btnInfo.glyph == "tree" then
                local filled = {
                    { true,  true,  true  },
                    { true,  true,  false },
                    { false, false, false },
                }
                for col = 1, 3 do
                    Bar(1, 20, (col - 2) * 8, 0, 0.55, 0.58, 0.66, 0.5)
                    for row = 1, 3 do
                        local on = filled[col][row]
                        Bar(6, 6, (col - 2) * 8, (2 - row) * 8,
                            on and S.ACCENT_GLOW[1] or 0.40,
                            on and S.ACCENT_GLOW[2] or 0.42,
                            on and S.ACCENT_GLOW[3] or 0.50, 1)
                    end
                end
            end
            btn.glyph = g
        end

        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints(icon)
        highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
        highlight:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.25)

        S.CreateRingBorder(btn)

        local activeGlow = btn:CreateTexture(nil, "BACKGROUND", nil, 1)
        activeGlow:SetAllPoints()
        activeGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
        activeGlow:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.18)
        activeGlow:Hide()
        btn.activeGlow = activeGlow

        btn.panelName = btnInfo.panel
        btn.label = btnInfo.label
        btn.icon = icon
        btn.toolbarX = (i - (numBtns + 1) / 2) * btnSpacing

        btn:SetScript("OnEnter", function()
            if mf.toolbarCaption then
                mf.toolbarCaption:SetText(btnInfo.label)
                mf.toolbarCaption:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
            end
        end)
        btn:SetScript("OnLeave", function()
            NarciUI:UpdateToolbarState()
        end)
        btn:SetScript("OnClick", btnInfo.func)
        mf.toolbarButtons[i] = btn
    end

    local indicator = CreateFrame("Frame", nil, toolbar)
    indicator:SetSize(40, 2)
    indicator:SetPoint("BOTTOM", toolbar, "BOTTOM", 0, TOOLBAR_INDICATOR_Y)
    local indicatorTex = indicator:CreateTexture(nil, "OVERLAY")
    indicatorTex:SetAllPoints()
    indicatorTex:SetTexture("Interface\\Buttons\\WHITE8x8")
    indicatorTex:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.9)
    indicator:Hide()
    mf.toolbarIndicator = indicator

    model:EnableMouse(true)
    model:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then self.dragging = true; self.startX = GetCursorPosition() end
    end)
    model:SetScript("OnMouseUp", function(self) self.dragging = false end)
    model:SetScript("OnUpdate", function(self, e)
        if self.dragging then
            local x = GetCursorPosition()
            local delta = (x - (self.startX or x)) * 0.01
            self:SetFacing(self:GetFacing() + delta)
            self.startX = x
            self.intro = nil
        elseif self.intro then
            local a = self.intro
            a.elapsed = a.elapsed + (e or 0)
            local t = a.elapsed / a.duration
            if t >= 1 then
                self:SetFacing(a.toFacing)
                self:SetModelScale(a.toScale)
                self.intro = nil
            else
                local k = 1 - (1 - t) ^ 3
                self:SetFacing(a.fromFacing + (a.toFacing - a.fromFacing) * k)
                self:SetModelScale(a.fromScale + (a.toScale - a.fromScale) * k)
            end
        end
    end)
    model:EnableMouseWheel(true)
    model:SetScript("OnMouseWheel", function(self, delta)
        local scale = self:GetModelScale() or 1
        if delta > 0 then scale = min(scale * 1.05, 2.0) else scale = max(scale * 0.95, 0.5) end
        self:SetModelScale(scale)
    end)

    self.mainFrame = mf
end

function NarciUI:CreateSlotFrame(parent, slotInfo)
    local slotName = "Character" .. slotInfo.name
    local originalButton = _G[slotName]
    local S = NS.Styling

    local f = CreateFrame("Button", "NarciSirus_Slot_" .. slotInfo.id, UIParent, "SecureActionButtonTemplate")
    f:SetSize(SLOT_SIZE, SLOT_SIZE)
    f:SetPoint("CENTER", parent, "CENTER", slotInfo.x, slotInfo.y)
    f:EnableMouse(true)
    f:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    f:SetFrameStrata(parent:GetFrameStrata())
    f:SetFrameLevel(parent:GetFrameLevel() + 5)

    if originalButton then
        f:SetAttribute("type1", "click")
        f:SetAttribute("type2", "click")
        f:SetAttribute("clickbutton", originalButton)
    end

    f:SetAttribute("target-slot", slotInfo.id)

    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.85)

    local border = CreateFrame("Frame", nil, f)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    border:EnableMouse(false)

    local strip = f:CreateTexture(nil, "OVERLAY")
    strip:SetSize(2, SLOT_SIZE - 4)
    strip:SetTexture("Interface\\Buttons\\WHITE8x8")
    if slotInfo.side == "LEFT" then
        strip:SetPoint("LEFT", f, "LEFT", 0, 0)
    elseif slotInfo.side == "RIGHT" then
        strip:SetPoint("RIGHT", f, "RIGHT", 0, 0)
    else
        strip:SetPoint("LEFT", f, "LEFT", 0, 0)
    end
    strip:SetVertexColor(0.3, 0.3, 0.3, 0.6)
    f.qualityStrip = strip

    local slotBevel = f:CreateTexture(nil, "BORDER")
    slotBevel:SetHeight(1)
    slotBevel:SetPoint("TOPLEFT", f, "TOPLEFT", 1, -1)
    slotBevel:SetPoint("TOPRIGHT", f, "TOPRIGHT", -1, -1)
    slotBevel:SetTexture("Interface\\Buttons\\WHITE8x8")
    slotBevel:SetVertexColor(0.55, 0.60, 0.72, 0.28)

    local shadow = f:CreateTexture(nil, "BACKGROUND", nil, -1)
    shadow:SetSize(SLOT_SIZE + 6, 4)
    shadow:SetPoint("BOTTOM", f, "BOTTOM", 0, -4)
    shadow:SetTexture("Interface\\Buttons\\WHITE8x8")
    shadow:SetVertexColor(0, 0, 0, 0.25)

    local icon = f:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", 2, -2)
    icon:SetPoint("BOTTOMRIGHT", -2, 2)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local iLvlBg = f:CreateTexture(nil, "OVERLAY", nil, -1)
    iLvlBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    iLvlBg:SetVertexColor(0, 0, 0, 0.6)
    iLvlBg:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 2, 2)
    iLvlBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
    iLvlBg:SetHeight(14)
    iLvlBg:Hide()

    local iLvl = f:CreateFontString(nil, "OVERLAY")
    iLvl:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    iLvl:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    iLvl:SetPoint("BOTTOM", f, "BOTTOM", 0, 2)

    local enchantDot = S.CreateEnchantDot(f, slotInfo.side)

    local gemIcons = {}
    for i = 1, 4 do
        local btn = CreateFrame("Button", nil, f)
        btn:SetSize(14, 14)
        btn:SetFrameLevel(f:GetFrameLevel() + 2)
        btn:EnableMouse(false)
        local tex = btn:CreateTexture(nil, "ARTWORK")
        tex:SetAllPoints()
        tex:SetTexture("Interface\\Buttons\\WHITE8x8")
        btn.texture = tex
        btn.gemLink = nil
        if slotInfo.side == "LEFT" then
            btn:SetPoint("TOPLEFT", f, "TOPRIGHT", 3, -2 - (i - 1) * 15)
        elseif slotInfo.side == "RIGHT" then
            btn:SetPoint("TOPRIGHT", f, "TOPLEFT", -3, -2 - (i - 1) * 15)
        else
            btn:SetPoint("BOTTOMLEFT", f, "TOPLEFT", -2 - (i - 1) * 15, 3)
        end
        tex:SetVertexColor(0.5, 0.5, 0.5, 0.5)
        btn:Hide()
        btn:SetScript("OnEnter", function(self)
            if self.gemLink then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetHyperlink(self.gemLink)
                GameTooltip:Show()
            end
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
        gemIcons[i] = btn
    end

    local nameLabel = f:CreateFontString(nil, "OVERLAY")
    nameLabel:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    nameLabel:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    if slotInfo.side == "LEFT" then
        nameLabel:SetPoint("RIGHT", f, "LEFT", -10, 0)
        nameLabel:SetJustifyH("RIGHT")
    elseif slotInfo.side == "RIGHT" then
        nameLabel:SetPoint("LEFT", f, "RIGHT", 10, 0)
        nameLabel:SetJustifyH("LEFT")
    else
        nameLabel:SetPoint("TOP", f, "BOTTOM", 0, -14)
        nameLabel:SetJustifyH("CENTER")
    end

    local function NamePlateHalf(leftHalf)
        local t = f:CreateTexture(nil, "BACKGROUND", nil, -2)
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        if leftHalf then
            t:SetPoint("TOPLEFT", nameLabel, "TOPLEFT", -16, 5)
            t:SetPoint("BOTTOMRIGHT", nameLabel, "BOTTOM", 0, -5)
            t:SetGradientAlpha("Horizontal", 0, 0, 0, 0, 0, 0, 0, 0.7)
        else
            t:SetPoint("TOPLEFT", nameLabel, "TOP", 0, 5)
            t:SetPoint("BOTTOMRIGHT", nameLabel, "BOTTOMRIGHT", 16, -5)
            t:SetGradientAlpha("Horizontal", 0, 0, 0, 0.7, 0, 0, 0, 0)
        end
        t:Hide()
        return t
    end
    f.namePlate = { NamePlateHalf(true), NamePlateHalf(false) }

    local okSlot, _, emptyTexture = pcall(GetInventorySlotInfo, slotInfo.name)
    f.emptyTexture = (okSlot and emptyTexture) or "Interface\\Icons\\INV_Misc_QuestionMark"

    local qualityGlow = f:CreateTexture(nil, "BACKGROUND", nil, -1)
    qualityGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    if slotInfo.side == "LEFT" then
        qualityGlow:SetPoint("TOPRIGHT", f, "TOPLEFT", 0, 4)
        qualityGlow:SetPoint("BOTTOMRIGHT", f, "BOTTOMLEFT", 0, -4)
        qualityGlow:SetWidth(80)
        qualityGlow:SetGradientAlpha("Horizontal", 1, 1, 1, 0, 1, 1, 1, 0.35)
    elseif slotInfo.side == "RIGHT" then
        qualityGlow:SetPoint("TOPLEFT", f, "TOPRIGHT", 0, 4)
        qualityGlow:SetPoint("BOTTOMLEFT", f, "BOTTOMRIGHT", 0, -4)
        qualityGlow:SetWidth(80)
        qualityGlow:SetGradientAlpha("Horizontal", 1, 1, 1, 0.35, 1, 1, 1, 0)
    else
        qualityGlow:SetPoint("TOPLEFT", f, "BOTTOMLEFT", -10, 0)
        qualityGlow:SetPoint("TOPRIGHT", f, "BOTTOMRIGHT", 10, 0)
        qualityGlow:SetHeight(60)
        qualityGlow:SetGradientAlpha("Vertical", 1, 1, 1, 0, 1, 1, 1, 0.35)
    end
    qualityGlow:Hide()
    f.qualityGlow = qualityGlow

    local highlight = f:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\Buttons\\WHITE8x8")
    highlight:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.15)

    S.AddHoverGlow(f)

    f:SetScript("OnEnter", function(self)
        local link = GetInventoryItemLink("player", slotInfo.id)
        if link then GameTooltip:SetOwner(self, "ANCHOR_RIGHT"); GameTooltip:SetInventoryItem("player", slotInfo.id); GameTooltip:Show() end
        if self.nameLabel then self.nameLabel:SetTextColor(1, 1, 1) end
    end)
    f:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        local c = self.nameColor
        if self.nameLabel and c then self.nameLabel:SetTextColor(c[1], c[2], c[3]) end
    end)

    f.icon = icon; f.border = border; f.bg = bg; f.iLvlText = iLvl; f.iLvlBg = iLvlBg
    f.enchantDot = enchantDot
    f.gemIcons = gemIcons; f.nameLabel = nameLabel; f.slotId = slotInfo.id; f.slotSide = slotInfo.side
    return f
end

local function RiseIn(frame, dy, duration)
    if not frame then return end
    if not frame._riseAnchor then
        local p, r, rp, ax, ay = frame:GetPoint(1)
        if not p then
            frame:SetAlpha(1)
            return
        end
        frame._riseAnchor = { p, r, rp, ax, ay }
    end
    local point, rel, relPoint, x, y =
        frame._riseAnchor[1], frame._riseAnchor[2], frame._riseAnchor[3],
        frame._riseAnchor[4], frame._riseAnchor[5]
    duration = duration or 0.25

    local elapsed = 0
    frame:SetAlpha(0)
    frame:ClearAllPoints()
    frame:SetPoint(point, rel, relPoint, x, y - dy)

    frame:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local t = elapsed / duration
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            self:SetAlpha(1)
            self:ClearAllPoints()
            self:SetPoint(point, rel, relPoint, x, y)
        else
            local ease = 1 - (1 - t) ^ 3
            self:SetAlpha(ease)
            self:ClearAllPoints()
            self:SetPoint(point, rel, relPoint, x, y - dy * (1 - ease))
        end
    end)
end

local INDICATOR_ANIM = 0.20

local function MoveIndicator(indicator, targetX)
    local startX = indicator._x
    if not indicator:IsShown() or not startX then startX = targetX end
    indicator._x = targetX

    local parent = indicator:GetParent()
    local elapsed = 0
    indicator:Show()

    if not NS.Styling.AnimationsEnabled() then
        indicator:SetScript("OnUpdate", nil)
        indicator:ClearAllPoints()
        indicator:SetPoint("BOTTOM", parent, "BOTTOM", targetX, TOOLBAR_INDICATOR_Y)
        indicator:SetAlpha(1)
        return
    end

    indicator:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local t = elapsed / INDICATOR_ANIM
        if t >= 1 then
            self:ClearAllPoints()
            self:SetPoint("BOTTOM", parent, "BOTTOM", targetX, TOOLBAR_INDICATOR_Y)
            self:SetAlpha(1)
            self:SetScript("OnUpdate", nil)
        else
            local ease = 1 - (1 - t) ^ 3
            self:ClearAllPoints()
            self:SetPoint("BOTTOM", parent, "BOTTOM", startX + (targetX - startX) * ease, TOOLBAR_INDICATOR_Y)
            self:SetAlpha(0.35 + 0.65 * ease)
        end
    end)
end

local function FadeOutIndicator(indicator)
    if not indicator:IsShown() then return end
    local startAlpha = indicator:GetAlpha()
    local elapsed = 0
    indicator:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local t = elapsed / (INDICATOR_ANIM * 0.7)
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            self:SetAlpha(1)
            self._x = nil
        else
            self:SetAlpha(startAlpha * (1 - t))
        end
    end)
end

function NarciUI:UpdateToolbarState(activeName)
    local mf = self.mainFrame
    if not mf or not mf.toolbarButtons then return end

    local activeX, activeLabel
    for _, btn in ipairs(mf.toolbarButtons) do
        local active
        if activeName then
            active = (btn.panelName == activeName)
        else
            local panel = btn.panelName and NS[btn.panelName]
            active = panel and panel.frame and panel.frame:IsShown()
        end
        if active then
            activeX = btn.toolbarX
            activeLabel = btn.label
            btn.activeGlow:Show()
            btn.icon:SetVertexColor(1, 1, 1)
            if btn.glyph then btn.glyph:SetAlpha(1) end
        else
            btn.activeGlow:Hide()
            btn.icon:SetVertexColor(0.65, 0.65, 0.7)
            if btn.glyph then btn.glyph:SetAlpha(0.7) end
        end
    end

    if mf.toolbarCaption then
        local S = NS.Styling
        mf.toolbarCaption:SetText(activeLabel or "")
        mf.toolbarCaption:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    end

    if mf.toolbarIndicator then
        if activeX then
            MoveIndicator(mf.toolbarIndicator, activeX)
        else
            FadeOutIndicator(mf.toolbarIndicator)
        end
    end
end

function NarciUI:UpdateSlots()
    if not self.mainFrame then return end
    local S = NS.Styling

    local db = NS.db or {}
    local showILvl = db.showItemLevel ~= false
    local showEnchant = db.showEnchantInfo ~= false
    local showGems = db.showGemInfo ~= false
    local showNames = db.showItemNames ~= false
    local hideEmpty = db.hideEmptySlots == true
    local nameLength = db.nameLength or SLOT_NAME_MAX_CHARS

    for slotId, slotFrame in pairs(self.mainFrame.slotFrames) do
        local link = GetInventoryItemLink("player", slotId)

        slotFrame._hiddenEmpty = (hideEmpty and not link) or nil
        if slotFrame._hiddenEmpty or self.sceneHidden then
            slotFrame:Hide()
        elseif not slotFrame:IsShown() then
            slotFrame:Show()
        end

        if link then
            local name, _, quality, itemLevel, _, _, _, _, _, texture = GetItemInfo(link)
            local r, g, b = NS.GetQualityColor(quality)
            slotFrame.icon:SetTexture(texture)
            slotFrame.icon:SetVertexColor(1, 1, 1, 1)
            slotFrame.icon:Show()
            slotFrame.border:SetBackdropBorderColor(r, g, b, 0.9)
            slotFrame.qualityStrip:SetVertexColor(r, g, b, 0.85)
            if slotFrame.qualityGlow then
                slotFrame.qualityGlow:Show()
                if slotFrame.slotSide == "LEFT" then
                    slotFrame.qualityGlow:SetGradientAlpha("Horizontal", r, g, b, 0, r, g, b, 0.35)
                elseif slotFrame.slotSide == "RIGHT" then
                    slotFrame.qualityGlow:SetGradientAlpha("Horizontal", r, g, b, 0.35, r, g, b, 0)
                else
                    slotFrame.qualityGlow:SetGradientAlpha("Vertical", r, g, b, 0, r, g, b, 0.35)
                end
            end
            if showILvl and itemLevel and itemLevel > 0 then
                slotFrame.iLvlText:SetText(itemLevel)
                local ilR, ilG, ilB = S.GetILvlColor(itemLevel)
                slotFrame.iLvlText:SetTextColor(ilR, ilG, ilB)
                slotFrame.iLvlText:Show()
                slotFrame.iLvlBg:Show()
            else
                slotFrame.iLvlText:Hide()
                slotFrame.iLvlBg:Hide()
            end
            if slotFrame.nameLabel then
                if showNames and name then
                    slotFrame.nameLabel:SetText(NS.TruncateText(name, nameLength))
                    slotFrame.nameLabel:SetTextColor(r, g, b)
                    slotFrame.nameColor = { r, g, b }
                else
                    slotFrame.nameLabel:SetText("")
                end
                if slotFrame.namePlate then
                    for i = 1, #slotFrame.namePlate do
                        if showNames and name then
                            slotFrame.namePlate[i]:Show()
                        else
                            slotFrame.namePlate[i]:Hide()
                        end
                    end
                end
            end
            if not showEnchant then
                S.SetEnchantDotStatus(slotFrame.enchantDot, "none")
            elseif NS.ENCHANTABLE_SLOTS and NS.ENCHANTABLE_SLOTS[slotId] then
                S.SetEnchantDotStatus(slotFrame.enchantDot,
                    NS.GetEnchantInfo(link) and "enchanted" or "missing")
            else
                S.SetEnchantDotStatus(slotFrame.enchantDot, "none")
            end
            local totalSockets = 0
            if showGems and NS.TooltipScanner then
                totalSockets = NS.TooltipScanner:GetSocketCountFromTextures(link)
            end
            local gems = totalSockets > 0 and NS.GetGemInfo(link) or nil
            for i = 1, 4 do
                if i <= totalSockets and slotFrame.gemIcons[i] then
                    local btn = slotFrame.gemIcons[i]
                    btn:Show()
                    btn:EnableMouse(true)
                    if gems[i] and gems[i].texture then
                        btn.texture:SetTexture(gems[i].texture)
                        btn.texture:SetVertexColor(1, 1, 1, 1)
                        btn.gemLink = gems[i].link
                    else
                        local socketTex = NS.TooltipScanner
                            and NS.TooltipScanner:GetSocketTexture(link, i)
                        btn.texture:SetTexture(socketTex or "Interface\\ItemSocketingFrame\\UI-EmptySocket")
                        btn.texture:SetVertexColor(1, 1, 1, 0.95)
                        btn.gemLink = nil
                    end
                elseif slotFrame.gemIcons[i] then
                    slotFrame.gemIcons[i]:Hide()
                    slotFrame.gemIcons[i]:EnableMouse(false)
                    slotFrame.gemIcons[i].gemLink = nil
                end
            end
            slotFrame.bg:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.75)
        else
            if slotFrame.emptyTexture then
                slotFrame.icon:SetTexture(slotFrame.emptyTexture)
                slotFrame.icon:SetVertexColor(1, 1, 1, 0.75)
                slotFrame.icon:Show()
            else
                slotFrame.icon:SetTexture(nil)
            end
            slotFrame.iLvlText:Hide(); slotFrame.iLvlBg:Hide()
            if slotFrame.nameLabel then slotFrame.nameLabel:SetText("") end
            if slotFrame.namePlate then
                for i = 1, #slotFrame.namePlate do slotFrame.namePlate[i]:Hide() end
            end
            if slotFrame.qualityGlow then slotFrame.qualityGlow:Hide() end
            for i = 1, 4 do if slotFrame.gemIcons[i] then slotFrame.gemIcons[i]:Hide(); slotFrame.gemIcons[i]:EnableMouse(false); slotFrame.gemIcons[i].gemLink = nil end end
            slotFrame.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.4)
            slotFrame.qualityStrip:SetVertexColor(0.2, 0.2, 0.25, 0.3)
            slotFrame.bg:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.85)
        end
    end
end

function NarciUI:UpdatePlayerInfo()
    if not self.mainFrame then return end
    local mf = self.mainFrame
    local name = UnitName("player")
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    if color then
        mf.playerName:SetText(format("|cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, name))
    else
        mf.playerName:SetText(name or "")
    end
    NS.Styling.SetClassIcon(mf.classIcon, class)
    local level = UnitLevel("player")
    local race = UnitRace("player")
    local _, localizedClass = UnitClass("player")
    mf.playerDetails:SetText(format("%s |cff00ccff%d|r %s %s", "", level, race, localizedClass))
    local avg = NS.GetAverageItemLevel()
    mf.iLvlValue:SetText(format("%.1f", avg))
    mf.iLvlValue:SetTextColor(NS.Styling.GetILvlColor(avg))

    if mf.specLine then
        local text = ""
        if NS.StatPriority then
            local ok, _, info = pcall(NS.StatPriority.Get, NS.StatPriority)
            if ok and info then
                local A = NS.Styling.ACCENT_GLOW
                local G = NS.Styling.GOLD_DIM
                if info.specName then
                    text = format("|cff%02x%02x%02x%s|r",
                        A[1] * 255, A[2] * 255, A[3] * 255, info.specName)
                end
                if info.tier then
                    local okt, tierText = pcall(NS.StatPriority.GetTierLabel, NS.StatPriority, info)
                    if okt then
                        if text ~= "" then text = text .. "   " end
                        text = text .. format(L["|cff%02x%02x%02xнабор %s|r"],
                            G[1] * 255, G[2] * 255, G[3] * 255, tierText)
                    end
                end
            end
        end
        mf.specLine:SetText(text)
    end
end

function NarciUI:RefreshModel()
    local mf = self.mainFrame
    local model = mf and mf.model
    if not model then return end

    local facing = model:GetFacing()
    local scale = model:GetModelScale()

    model:SetUnit("player")
    pcall(model.RefreshUnit, model)
    pcall(model.SetPortraitZoom, model, 0.85)
    pcall(model.SetCamDistanceScale, model, 0.9)
    pcall(model.SetPosition, model, 0, 0, 0)

    if facing then model:SetFacing(facing) end
    if scale and scale > 0 then model:SetModelScale(scale) end
end

function NarciUI:PlayIntroSweep()
    local sweep = self.mainFrame and self.mainFrame.introSweep
    if not sweep then return end
    sweep:SetScript("OnUpdate", nil)
    if not NS.Styling.AnimationsEnabled() then
        sweep:Hide()
        return
    end

    local half = (sweep:GetWidth() or 1920) / 2 - 40
    if half < 10 then half = 10 end
    local grow, fade = 0.26, 0.30
    local elapsed = 0

    sweep.left:SetWidth(1)
    sweep.right:SetWidth(1)
    sweep:SetAlpha(1)
    sweep:Show()
    sweep:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + (e or 0)
        if elapsed <= grow then
            local w = max(1, half * (1 - (1 - elapsed / grow) ^ 3))
            self.left:SetWidth(w)
            self.right:SetWidth(w)
        elseif elapsed <= grow + fade then
            self.left:SetWidth(half)
            self.right:SetWidth(half)
            self:SetAlpha(1 - (elapsed - grow) / fade)
        else
            self:SetScript("OnUpdate", nil)
            self:Hide()
        end
    end)
end

function NarciUI:PlayModelIntro()
    local model = self.mainFrame and self.mainFrame.model
    if not model then return end
    if not NS.Styling.AnimationsEnabled() then
        model.intro = nil
        return
    end

    local toScale = model:GetModelScale() or 1
    if not toScale or toScale <= 0 then toScale = 1 end
    local toFacing = model:GetFacing() or 0.4

    model.intro = {
        elapsed = 0, duration = 0.55,
        fromFacing = toFacing + 0.6, toFacing = toFacing,
        fromScale = toScale * 0.90,  toScale = toScale,
    }
    model:SetFacing(model.intro.fromFacing)
    model:SetModelScale(model.intro.fromScale)
end

function NarciUI:Show()
    if not self.mainFrame then self:Create() end
    self.sceneHidden = nil
    self:ApplyScale()
    self:UpdateSlots(); self:UpdatePlayerInfo()
    self.mainFrame.model:SetUnit("player")
    local remember = NS.db and NS.db.rememberModelView
    self.mainFrame.model:SetFacing(remember and NS.db.modelFacing or 0.4)
    if remember and NS.db.modelScale and NS.db.modelScale > 0 then
        pcall(self.mainFrame.model.SetModelScale, self.mainFrame.model, NS.db.modelScale)
    end
    pcall(function() self.mainFrame.model:RefreshUnit() end)
    local mf = self.mainFrame
    local animate = NS.Styling.AnimationsEnabled()

    self._showToken = (self._showToken or 0) + 1
    local token = self._showToken

    mf:SetAlpha(0); mf:Show()
    NS.Styling.FadeIn(mf, 0.35)
    self:PlayIntroSweep()
    self:PlayModelIntro()

    if self.edgeVignette then
        if animate then
            NS.Styling.FadeIn(self.edgeVignette, 0.3)
        else
            self.edgeVignette:SetAlpha(1)
            self.edgeVignette:Show()
        end
    end

    local order = self._slotLayout or {}
    for i = 1, #order do
        local info = order[i]
        local slotFrame = mf.slotFrames[info.id]
        if slotFrame and not slotFrame._hiddenEmpty then
            if animate then
                local row = (info.side == "BOTTOM") and (NUM_SIDE_SLOTS + 1)
                            or ((i - 1) % NUM_SIDE_SLOTS) + 1
                slotFrame:SetAlpha(0)
                NS.After(0.14 + (row - 1) * 0.035, function()
                    if self._showToken ~= token then return end
                    if not slotFrame._hiddenEmpty and not self.sceneHidden then
                        NS.Styling.FadeIn(slotFrame, 0.25)
                    end
                end)
            else
                slotFrame:SetAlpha(1)
            end
        end
    end

    if mf.toolbar then
        if animate then
            mf.toolbar:SetAlpha(0)
            NS.After(0.30, function()
                if self._showToken ~= token then return end
                RiseIn(mf.toolbar, 20, 0.28)
            end)
        else
            mf.toolbar:SetAlpha(1)
        end
    end
    self.isShown = true
    self:UpdateToolbarState()
    if NS.EquipInfo then NS.EquipInfo:Show() end

    local openPanel = NS.db and NS.db.openPanel
    if openPanel and openPanel ~= "none" then
        local panel = NS[openPanel]
        if panel and not (panel.frame and panel.frame:IsShown()) then
            NS:TogglePanelByName(openPanel)
        end
    end
    self:RaiseBags()
    if self._bagWatcher then self._bagWatcher:Show() end
    self:HideOtherAddons()
end

local function Unpack(out, ...)
    local n = select("#", ...)
    for i = 1, n do out[i] = select(i, ...) end
    for i = n + 1, #out do out[i] = nil end
    return n
end

local childScratch = {}
local kidScratch = {}

local function HasAdiBagsChild(frame)
    local n = Unpack(kidScratch, frame:GetChildren())
    for i = 1, n do
        local kid = kidScratch[i]
        local name = kid and kid:GetName()
        if name and name:find("AdiBags") then return true end
    end
    return false
end

local BAG_TARGET_LEVEL = 300

local TOP_FRAME_NAMES = { "TradeSkillFrame", "CraftFrame" }

local BAG_NAME_PATTERNS = {
    "^ContainerFrame%d", "AdiBags", "Bagnon", "ArkInventory",
    "Baggins", "OneBag", "Combuctor", "ElvUI_ContainerFrame",
}

local function IsBagFrame(frame)
    local name = frame:GetName()
    if name then
        for _, p in ipairs(BAG_NAME_PATTERNS) do
            if name:find(p) then return true end
        end
        return false
    end
    return HasAdiBagsChild(frame)
end

local function RaiseTree(frame, strata, delta, store, depth)
    if not frame or not frame.GetFrameLevel or depth > 6 then return end
    if not store[frame] then
        store[frame] = { frame:GetFrameStrata(), frame:GetFrameLevel() }
    end
    frame:SetFrameStrata(strata)
    frame:SetFrameLevel(frame:GetFrameLevel() + delta)
    local kids = { frame:GetChildren() }
    for i = 1, #kids do
        RaiseTree(kids[i], strata, delta, store, depth + 1)
    end
end

local CRAFT_GAP     = 16
local CRAFT_TOP_GAP = 8

local function CraftParkY(frame, scale)
    local weaponTop = (BOTTOM_Y + 15 + SLOT_SIZE / 2) * scale
    local height = frame:GetHeight() or 496
    local y = weaponTop + CRAFT_GAP + height / 2

    local maxY = (UIParent:GetHeight() or 768) / 2
                 - TOP_BAR_HEIGHT * scale - CRAFT_TOP_GAP - height / 2
    if y > maxY then y = maxY end
    return y
end

function NarciUI:ParkTopFrame(frame)
    if not frame or not frame.ClearAllPoints then return end

    local moved = self._movedFrames
    if not moved then
        moved = {}
        self._movedFrames = moved
    end
    if moved[frame] == nil then
        local point, rel, relPoint, x, y = frame:GetPoint(1)
        moved[frame] = point and { point, rel, relPoint, x, y } or false
    end

    local scale = self._appliedScale or 1
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", MODEL_X * scale, CraftParkY(frame, scale))
end

function NarciUI:KeepTopFramesParked()
    if not self.isShown then return end
    local scale = self._appliedScale or 1
    local wantX = MODEL_X * scale
    for i = 1, #TOP_FRAME_NAMES do
        local frame = _G[TOP_FRAME_NAMES[i]]
        if frame and frame.IsShown and frame:IsShown() then
            local point, _, _, x, y = frame:GetPoint(1)
            if point ~= "CENTER" or x ~= wantX or y ~= CraftParkY(frame, scale) then
                self:ParkTopFrame(frame)
            end
        end
    end
end

local function Raise(frame, raised)
    if not frame or raised[frame] then return end
    RaiseTree(frame, "FULLSCREEN_DIALOG", BAG_TARGET_LEVEL - frame:GetFrameLevel(), raised, 1)
end

local CONTAINER_NAMES = {}
for i = 1, 13 do CONTAINER_NAMES[i] = "ContainerFrame" .. i end

function NarciUI:RaiseBags()
    if not self.isShown then return end
    local raised = self._raisedBags
    if not raised then
        raised = {}
        self._raisedBags = raised
    end

    for i = 1, 13 do
        local cf = _G[CONTAINER_NAMES[i]]
        if cf and cf:IsShown() then Raise(cf, raised) end
    end

    for i = 1, #TOP_FRAME_NAMES do
        local frame = _G[TOP_FRAME_NAMES[i]]
        if frame and frame.IsShown and frame:IsShown() then Raise(frame, raised) end
    end
    self:KeepTopFramesParked()

    local n = Unpack(childScratch, UIParent:GetChildren())
    for i = 1, n do
        local child = childScratch[i]
        if child and child:IsShown() and IsBagFrame(child) then
            Raise(child, raised)
        end
    end
end

local BAG_WATCH_INTERVAL = 0.3
do
    local bagWatcher = CreateFrame("Frame")
    bagWatcher:Hide()
    local elapsed = 0
    bagWatcher:SetScript("OnUpdate", function(self, e)
        NarciUI:KeepTopFramesParked()

        elapsed = elapsed + e
        if elapsed < BAG_WATCH_INTERVAL then return end
        elapsed = 0
        NarciUI:RaiseBags()
    end)
    NarciUI._bagWatcher = bagWatcher
end

do
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("UI_SCALE_CHANGED")
    watcher:RegisterEvent("DISPLAY_SIZE_CHANGED")
    watcher:RegisterEvent("PLAYER_REGEN_ENABLED")
    watcher:SetScript("OnEvent", function(_, event)
        if event == "PLAYER_REGEN_ENABLED" then
            if NarciUI._scalePending then NarciUI:ApplyScale() end
            if NarciUI._hiddenFrames and not NarciUI.isShown then
                NarciUI:RestoreOtherAddons()
            end
        elseif NarciUI.mainFrame then
            NarciUI:ApplyScale()
        end
    end)
end

function NarciUI:PrintBagDiagnostics()
    NS.Print(L["окно открыто: "] .. tostring(self.isShown and true or false))
    local n = 0
    local count = Unpack(childScratch, UIParent:GetChildren())
    for i = 1, count do
        local child = childScratch[i]
        if child and child:IsShown() and IsBagFrame(child) then
            n = n + 1
            NS.Print(format("  %s | %s | %d%s",
                child:GetName() or L["<без имени>"],
                child:GetFrameStrata(), child:GetFrameLevel(),
                (self._raisedBags and self._raisedBags[child]) and L[" | поднят"] or ""))
        end
    end
    if n == 0 then NS.Print(L["  видимых фреймов сумок не найдено"]) end
end

function NarciUI:RestoreBags()
    if not self._raisedBags then return end
    for frame, saved in pairs(self._raisedBags) do
        if frame and frame.SetFrameStrata then
            frame:SetFrameStrata(saved[1])
            frame:SetFrameLevel(saved[2])
        end
    end
    self._raisedBags = nil

    if self._movedFrames then
        for frame, saved in pairs(self._movedFrames) do
            if saved and frame and frame.ClearAllPoints then
                frame:ClearAllPoints()
                frame:SetPoint(saved[1], saved[2] or frame:GetParent() or UIParent,
                               saved[3], saved[4], saved[5])
            end
        end
        self._movedFrames = nil
    end
end

if type(ShowUIPanel) == "function" then
    hooksecurefunc("ShowUIPanel", function(frame)
        if not NarciUI.isShown or not frame or not frame.GetName then return end
        local name = frame:GetName()
        if not name then return end
        for i = 1, #TOP_FRAME_NAMES do
            if name == TOP_FRAME_NAMES[i] then
                NS.After(0, function() NarciUI:RaiseBags() end)
                return
            end
        end
    end)
end

for _, fname in ipairs({ "ToggleBackpack", "OpenBackpack", "ToggleBag", "OpenBag", "OpenAllBags" }) do
    if type(_G[fname]) == "function" then
        hooksecurefunc(fname, function()
            if not NarciUI.isShown then return end
            NS.After(0, function() NarciUI:RaiseBags() end)
        end)
    end
end

local HIDE_WHITELIST = {
    "^NarcissusSirus", "^NarciSirus",
    "^MiniMap", "^Minimap",
    "^UIParent", "^WorldFrame",
    "^StaticPopup", "^GameTooltip",
    "^TokenFrame", "^FriendsFrame",
    "^GossipFrame", "^QuestFrame",
    "^MerchantFrame", "^TradeFrame",
    "^TradeSkillFrame", "^CraftFrame",
    "^BankFrame", "^Backpack",
    "^ContainerFrame", "^MailFrame",
    "^CharacterFrame", "^InspectFrame",
    "^PVPFrame", "^LootFrame",
    "^TicketStatus",
    "^MinimapCluster", "^GameTimeFrame",
    "^MiniMapBattlefield", "^MiniMapWorldMap",
    "^MiniMapMailFrame", "^MiniMapLFG",
    "^MiniMapMeetingStone", "^MiniMapBGFrame",
    "^MiniMapInstance", "^QueueStatus",
    "^HelpFrame", "^ScreenshotOption",
    "^TalentFrame", "^SpellBook",
    "^SkillFrame", "^PVPReady",
    "^WorldStateScore", "^ArenaEnemy",
    "^CompactRaidFrame", "^RaidWarningFrame",
    "^BossEmote", "^ErrorsFrame",
    "^UIErrorsFrame", "^Sound",
    "^KeyBinding", "^MacroFrame",
    "^VideoOptions", "^InterfaceOptions",
    "^StoreFrame", "^HelpOpen",
    "^AutoComplete", "^DropDownList",
    "^ColorPicker", "^OpenMail", "^SendMail",
    "AdiBags",
}

local STOCK_UI_WHITELIST = {
    "^ChatFrame", "^MainMenuBar", "^MultiBar",
    "^PetAction", "^Possess", "^Vehicle",
    "^CastingBar", "^BuffFrame", "^TemporaryEnchant",
    "^WatchFrame", "^ObjectiveTracker",
    "^DurabilityFrame", "^DPMInfo", "^Damage",
}

local function ShouldHideFrame(name)
    for _, pattern in ipairs(HIDE_WHITELIST) do
        if name:find(pattern) then return false end
    end
    if not (NS.db and NS.db.hideBlizzardUI) then
        for _, pattern in ipairs(STOCK_UI_WHITELIST) do
            if name:find(pattern) then return false end
        end
    end
    return true
end

function NarciUI:HideOtherAddons()
    if not self._hiddenFrames then self._hiddenFrames = {} end
    local mf = self.mainFrame
    local n = Unpack(childScratch, UIParent:GetChildren())
    for i = 1, n do
        local child = childScratch[i]
        if child and child ~= mf and child:IsShown() then
            local name = child:GetName()
            if name == "" then name = nil end
            local hide = name and ShouldHideFrame(name) or (not name and not HasAdiBagsChild(child))
            if hide and InCombatLockdown()
               and child.IsProtected and child:IsProtected() then
                hide = false
            end
            if hide then
                self._hiddenFrames[child] = true
                child:Hide()
            end
        end
    end
    if Minimap then Minimap:Hide() end
    if MinimapCluster then MinimapCluster:Hide() end
    SetCVar("UnitNameOwn", "0")
    SetCVar("UnitNameFriendlyPlayerName", "0")
    SetCVar("UnitNameEnemyPlayerName", "0")
    SetCVar("UnitNameFriendlyPetName", "0")
    SetCVar("UnitNameEnemyPetName", "0")
end

function NarciUI:RestoreOtherAddons()
    if self._hiddenFrames then
        local pending
        for frame in pairs(self._hiddenFrames) do
            if frame and frame.Show then
                if InCombatLockdown() and frame.IsProtected and frame:IsProtected() then
                    pending = pending or {}
                    pending[frame] = true
                else
                    frame:Show()
                end
            end
        end
        self._hiddenFrames = pending
    end
    if Minimap then Minimap:Show() end
    if MinimapCluster then MinimapCluster:Show() end
    SetCVar("UnitNameOwn", "1")
    SetCVar("UnitNameFriendlyPlayerName", "1")
    SetCVar("UnitNameEnemyPlayerName", "1")
    SetCVar("UnitNameFriendlyPetName", "1")
    SetCVar("UnitNameEnemyPetName", "1")
end

function NarciUI:StopIntro()
    local mf = self.mainFrame
    if not mf then return end

    if mf.introSweep then
        mf.introSweep:SetScript("OnUpdate", nil)
        mf.introSweep:Hide()
    end

    if mf.model then
        local a = mf.model.intro
        if a then
            mf.model.intro = nil
            mf.model:SetFacing(a.toFacing)
            mf.model:SetModelScale(a.toScale)
        end
    end

    local tb = mf.toolbar
    if tb then
        tb:SetScript("OnUpdate", nil)
        local a = tb._riseAnchor
        if a then
            tb:ClearAllPoints()
            tb:SetPoint(a[1], a[2], a[3], a[4], a[5])
        end
        tb:SetAlpha(1)
    end
end

function NarciUI:Hide()
    if not self.mainFrame then return end
    self.isShown = false

    if NS.db and NS.db.rememberModelView and self.mainFrame.model then
        local m = self.mainFrame.model
        NS.db.modelFacing = m:GetFacing()
        local ok, scale = pcall(m.GetModelScale, m)
        if ok and scale and scale > 0 then NS.db.modelScale = scale end
    end

    self._showToken = (self._showToken or 0) + 1
    self:StopIntro()
    NS:HideAllPanels()
    if self.mainFrame and self.mainFrame.slotFrames then
        for _, sf in pairs(self.mainFrame.slotFrames) do
            sf:SetScript("OnUpdate", nil)
            sf:Hide()
        end
    end
    if NS.EquipInfo then NS.EquipInfo:Hide() end
    if self._bagWatcher then self._bagWatcher:Hide() end
    self:RestoreBags()
    self:RestoreOtherAddons()
    NS.Styling.FadeOut(self.mainFrame, 0.25, true)
    self.isShown = false
end

function NarciUI:Toggle() if self.isShown then self:Hide() else self:Show() end end
