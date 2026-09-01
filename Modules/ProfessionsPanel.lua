local addonName, NS = ...
local L = NS.L

local ProfessionsPanel = {}

local format = string.format
local max = math.max
local min = math.min

local WHITE = "Interface\\Buttons\\WHITE8x8"

local TITLE_Y      = -12
local HINT_Y       = -34
local SEPARATOR_Y  = -52
local CONTENT_TOP  = -60
local ROW_PITCH    = 44
local BOTTOM_PAD   = 12
local MIN_HEIGHT   = 220
local MAX_HEIGHT   = 470
local PAD          = 14
local ICON_SIZE    = 32
local EXTRA_SIZE   = 28
local BAR_HEIGHT   = 6
local TEXT_Y       = -5
local BAR_Y        = -23

local PROFESSION_LIST = {
    { skill = TRADESKILL_ALCHEMY,        open = 2259                },
    { skill = TRADESKILL_BLACKSMITHING,  open = 2018                },
    { skill = TRADESKILL_ENCHANTING,     open = 7411,  extra = 13262 },
    { skill = TRADESKILL_ENGINEERING,    open = 4036                },
    { skill = TRADESKILL_HERBALISM,      open = 2366                },
    { skill = TRADESKILL_INSCRIPTION,    open = 45357, extra = 51005 },
    { skill = TRADESKILL_JEWELCRAFTING,  open = 25229, extra = 31252 },
    { skill = TRADESKILL_LEATHERWORKING, open = 2108                },
    { skill = TRADESKILL_MINING,         open = 2656                },
    { skill = TRADESKILL_SKINNING,       open = 8613                },
    { skill = TRADESKILL_TAILORING,      open = 3908                },
    { skill = PROFESSION_FISHING,        open = 7620                },
    { skill = PROFESSION_COOKING,        open = 2550,  extra = 818   },
    { skill = PROFESSION_FIRST_AID,      open = 3273                },
}

local byName

local function BuildIndex()
    if byName then return byName end
    byName = {}
    for _, p in ipairs(PROFESSION_LIST) do
        if p.skill then byName[p.skill] = p end
    end
    local smelting = GetSpellInfo(2656)
    if smelting and byName[TRADESKILL_MINING] then
        byName[smelting] = byName[TRADESKILL_MINING]
    end
    return byName
end

local function CollectProfessions()
    local index = BuildIndex()
    local found, result = {}, {}

    for i = 1, (GetNumSkillLines() or 0) do
        local skillName, isHeader, _, skillRank, _, skillModifier, skillMaxRank = GetSkillLineInfo(i)
        if not isHeader and skillName then
            local entry = index[skillName]
            if entry and skillMaxRank and skillMaxRank > 0 then
                local prev = found[entry]
                if not prev or (prev.maxRank or 0) < skillMaxRank then
                    found[entry] = {
                        entry = entry,
                        rank = skillRank or 0,
                        maxRank = skillMaxRank,
                        modifier = skillModifier or 0,
                    }
                end
            end
        end
    end

    for _, p in ipairs(PROFESSION_LIST) do
        if found[p] then result[#result + 1] = found[p] end
    end
    return result
end

local function CreateSpellButton(parent, size, name)
    local S = NS.Styling
    local btn = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
    btn:SetSize(size, size)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("TOPLEFT", btn, "TOPLEFT", 1, -1)
    icon:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", -1, 1)
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    local border = CreateFrame("Frame", nil, btn)
    border:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
    border:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
    border:SetBackdrop({ edgeFile = WHITE, edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    border:EnableMouse(false)
    btn.border = border

    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints(icon)
    highlight:SetTexture(WHITE)
    highlight:SetBlendMode("ADD")
    highlight:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.22)

    btn:SetScript("OnEnter", function(self)
        if not self.spellID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local ok = false
        pcall(function()
            local link = GetSpellLink(self.spellID)
            if link then ok = GameTooltip:SetHyperlink(link) end
        end)
        if not ok then
            GameTooltip:AddLine(self.spellName or "", 1, 1, 1)
        end
        if self.hintText then
            GameTooltip:AddLine(self.hintText, 0.6, 0.6, 0.65)
        end
        GameTooltip:Show()
        self.border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
    end)
    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        self.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    end)

    return btn
end

local function SetButtonSpell(btn, spellID, hintText)
    local spellName, _, texture = GetSpellInfo(spellID)
    btn.spellID = spellID
    btn.spellName = spellName
    btn.hintText = hintText
    btn.icon:SetTexture(texture)

    if btn._spellSet == spellName then return true end
    if InCombatLockdown() then return false end

    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", spellName)
    btn._spellSet = spellName
    return true
end

function ProfessionsPanel:Create()
    if self.frame then return end
    local S = NS.Styling
    local parent = NS.NarciUI and NS.NarciUI.mainFrame
    if not parent then return end

    local f = CreateFrame("Frame", "NarcissusSirus_ProfessionsPanel", parent)
    f:SetWidth(S.PANEL_WIDTH)
    f:SetHeight(S.PANEL_HEIGHT)
    f:SetPoint("TOPRIGHT", parent, "RIGHT", S.PANEL_X, S.PANEL_Y + S.PANEL_HEIGHT / 2)
    f:SetFrameLevel(parent:GetFrameLevel() + 5)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = WHITE,
            edgeFile = WHITE,
            edgeSize = 1,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(S.BG_DARK[1], S.BG_DARK[2], S.BG_DARK[3], S.BG_DARK_A)
        f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    end
    S.CreateShadow(f, 5, 0.4)
    S.ApplyTabChrome(f)
    S.CreateGradientTopBorder(f)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOP", f, "TOP", 0, TITLE_Y)
    title:SetText(L["Профессии"])

    local hint = f:CreateFontString(nil, "OVERLAY")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    hint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    hint:SetPoint("TOP", f, "TOP", 0, HINT_Y)
    hint:SetText(L["Щёлкните по значку, чтобы открыть окно профессии."])
    f.hint = hint

    S.CreateAnimatedSeparator(f, SEPARATOR_Y)

    local empty = f:CreateFontString(nil, "OVERLAY")
    empty:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    empty:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    empty:SetPoint("TOP", f, "TOP", 0, CONTENT_TOP - 20)
    empty:SetText(L["Профессии не изучены."])
    empty:Hide()
    f.empty = empty

    f.rows = {}

    local ev = CreateFrame("Frame")
    ev:RegisterEvent("SKILL_LINES_CHANGED")
    ev:RegisterEvent("LEARNED_SPELL_IN_TAB")
    ev:RegisterEvent("PLAYER_REGEN_ENABLED")
    ev:SetScript("OnEvent", function()
        if ProfessionsPanel.frame and ProfessionsPanel.frame:IsShown() then
            ProfessionsPanel:Update()
        end
    end)
    f.eventFrame = ev

    self.frame = f
    f:Hide()
end

function ProfessionsPanel:CreateRow(index)
    local S = NS.Styling
    local f = self.frame
    local row = {}

    local holder = CreateFrame("Frame", nil, f)
    holder:SetPoint("TOPLEFT", f, "TOPLEFT", PAD, CONTENT_TOP - (index - 1) * ROW_PITCH)
    holder:SetPoint("TOPRIGHT", f, "TOPRIGHT", -PAD, CONTENT_TOP - (index - 1) * ROW_PITCH)
    holder:SetHeight(ROW_PITCH - 4)
    row.holder = holder

    local stripe = holder:CreateTexture(nil, "BACKGROUND")
    stripe:SetAllPoints(holder)
    stripe:SetTexture(WHITE)
    stripe:SetVertexColor(S.BG_STRIPE[1], S.BG_STRIPE[2], S.BG_STRIPE[3], 0.10)
    row.stripe = stripe

    local openBtn = CreateSpellButton(holder, ICON_SIZE, "NarciSirus_ProfOpen" .. index)
    openBtn:SetPoint("LEFT", holder, "LEFT", 0, 0)
    row.openBtn = openBtn

    local extraBtn = CreateSpellButton(holder, EXTRA_SIZE, "NarciSirus_ProfExtra" .. index)
    extraBtn:SetPoint("RIGHT", holder, "RIGHT", 0, 0)
    extraBtn:Hide()
    row.extraBtn = extraBtn

    local name = holder:CreateFontString(nil, "OVERLAY")
    name:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
    name:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
    name:SetPoint("TOPLEFT", holder, "TOPLEFT", ICON_SIZE + 8, TEXT_Y)
    name:SetJustifyH("LEFT")
    row.name = name

    local rank = holder:CreateFontString(nil, "OVERLAY")
    rank:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    rank:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, TEXT_Y)
    rank:SetJustifyH("RIGHT")
    row.rank = rank

    local barBg = holder:CreateTexture(nil, "ARTWORK")
    barBg:SetHeight(BAR_HEIGHT)
    barBg:SetPoint("TOPLEFT", holder, "TOPLEFT", ICON_SIZE + 8, BAR_Y)
    barBg:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, BAR_Y)
    barBg:SetTexture(WHITE)
    barBg:SetVertexColor(0.10, 0.11, 0.14, 0.9)
    row.barBg = barBg

    local barFill = holder:CreateTexture(nil, "OVERLAY")
    barFill:SetHeight(BAR_HEIGHT)
    barFill:SetPoint("TOPLEFT", barBg, "TOPLEFT", 0, 0)
    barFill:SetTexture(WHITE)
    row.barFill = barFill

    self.frame.rows[index] = row
    return row
end

function ProfessionsPanel:Update()
    if not self.frame then self:Create() end
    if not self.frame then return end
    local S = NS.Styling
    local f = self.frame

    local list = CollectProfessions()
    local shown = min(#list, 8)

    for i = 1, max(shown, #f.rows) do
        local row = f.rows[i]
        if i <= shown and not row then row = self:CreateRow(i) end
        if not row then break end

        if i > shown then
            row.holder:Hide()
        else
            local data = list[i]
            local entry = data.entry
            row.holder:Show()
            row.stripe:SetAlpha(i % 2 == 0 and 1 or 0)

            SetButtonSpell(row.openBtn, entry.open, L["Открыть окно профессии"])

            local rightPad = 0
            if entry.extra then
                SetButtonSpell(row.extraBtn, entry.extra)
                row.extraBtn:Show()
                rightPad = -(EXTRA_SIZE + 8)
            else
                row.extraBtn:Hide()
            end
            row.rank:SetPoint("TOPRIGHT", row.holder, "TOPRIGHT", rightPad, TEXT_Y)
            row.barBg:SetPoint("TOPRIGHT", row.holder, "TOPRIGHT", rightPad, BAR_Y)

            row.name:SetText(entry.skill or "")

            local rank, maxRank = data.rank, data.maxRank
            local capped = rank >= maxRank
            if data.modifier and data.modifier > 0 then
                row.rank:SetText(format("%d|cff40c040+%d|r / %d", rank, data.modifier, maxRank))
            else
                row.rank:SetText(format("%d / %d", rank, maxRank))
            end
            if capped then
                row.rank:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
                row.barFill:SetVertexColor(S.GOLD[1], S.GOLD[2], S.GOLD[3], 0.9)
            else
                row.rank:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
                row.barFill:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
            end

            local trackWidth = row.barBg:GetWidth() or 0
            local ratio = maxRank > 0 and (rank / maxRank) or 0
            if trackWidth > 1 and ratio > 0 then
                row.barFill:SetWidth(max(1, trackWidth * min(ratio, 1)))
                row.barFill:Show()
            else
                row.barFill:Hide()
            end
        end
    end

    if shown == 0 then
        f.empty:Show()
        f:SetHeight(MIN_HEIGHT)
    else
        f.empty:Hide()
        local height = -CONTENT_TOP + shown * ROW_PITCH + BOTTOM_PAD
        f:SetHeight(max(MIN_HEIGHT, min(MAX_HEIGHT, height)))
    end
end

function ProfessionsPanel:Toggle()
    if not self.frame then self:Create() end
    if not self.frame then return end
    if self.frame:IsShown() then
        NS.Styling.PanelOut(self.frame)
    else
        self:Update()
        NS.Styling.PanelIn(self.frame)
        NS.After(0.05, function()
            if ProfessionsPanel.frame and ProfessionsPanel.frame:IsShown() then
                ProfessionsPanel:Update()
            end
        end)
    end
end

function ProfessionsPanel:Hide() NS.Styling.PanelHideNow(self.frame) end

NS.ProfessionsPanel = ProfessionsPanel
