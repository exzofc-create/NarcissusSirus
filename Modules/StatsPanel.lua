local addonName, NS = ...
local L = NS.L
local StatsPanel = {}
local format = string.format
local floor = math.floor

local PANEL_WIDTH = 440
local ROW_HEIGHT = 16

local LIST_WIDTH  = 412
local COL_WIDTH   = 196
local COL_GAP     = 12
local LEFT_X      = 4
local RIGHT_X     = LEFT_X + COL_WIDTH + COL_GAP
local DIVIDER_X   = LEFT_X + COL_WIDTH + COL_GAP / 2
local LABEL_INSET = 8
local VALUE_WIDTH = 78
local LABEL_WIDTH = COL_WIDTH - LABEL_INSET - VALUE_WIDTH

local function GetAttackPower()
    local base, pos, neg = UnitAttackPower("player")
    return floor((base or 0) + (pos or 0) + (neg or 0))
end

local function ValueColor(text)
    local S = NS.Styling
    if text == "0" or text == "-" or text:match("^0%.0+%%?$") then
        return S.TEXT_DIM
    end
    return S.TEXT_BRIGHT
end

local STAT_LEFT = {
    { label = "Сила",         key = "STR",   func = function() return floor(UnitStat("player", 1)) end },
    { label = "Ловкость",     key = "AGI",   func = function() return floor(UnitStat("player", 2)) end },
    { label = "Выносливость", key = "STA",   func = function() return floor(UnitStat("player", 3)) end },
    { label = "Интеллект",    key = "INT",   func = function() return floor(UnitStat("player", 4)) end },
    { label = "Дух",          key = "SPI",   func = function() return floor(UnitStat("player", 5)) end },
    { label = "Здоровье",                    func = function() return UnitHealthMax("player") end },
    { label = "Броня",        key = "ARMOR", func = function() return select(2, UnitArmor("player")) end },
    { label = "Ресурс",                      func = function() return UnitPowerMax("player") end },
    { label = "Скорость",     key = "HASTE", func = function() return format("%.2f", UnitAttackSpeed("player")) end },
    { label = "Уклонение",                   func = function() return format("%.1f%%", GetDodgeChance()) end },
    { label = "Парирование",                 func = function() return format("%.1f%%", GetParryChance()) end },
    { label = "Блок",         key = "BLOCK", func = function() return format("%.1f%%", GetBlockChance()) end },
}

local STAT_RIGHT = {
    { label = "Сила атаки",  key = "AP",         func = GetAttackPower },
    { label = "Крит.",       key = "CRIT",       func = function() return format("%.1f%%", GetCritChance()) end },
    { label = "Крит. закл.", key = "SPELLCRIT",  func = function()
        local maxCrit = 0
        for i = 2, 7 do
            local c = GetSpellCritChance(i) or 0
            if c > maxCrit then maxCrit = c end
        end
        return format("%.1f%%", maxCrit)
    end },
    { label = "Меткость",    key = "HIT",        func = function() return GetCombatRating(CR_HIT_MELEE) end },
    { label = "Мастерство",  key = "EXP",        func = function() return (GetExpertise()) end },
    { label = "Защита",      key = "DEF",        func = function()
        local base, modifier = UnitDefense("player")
        return floor((base or 0) + (modifier or 0))
    end },
    { label = "Пробивание",  key = "ARP",        func = function() return format("%.1f%%", GetArmorPenetration()) end },
    { label = "Стойкость",                       func = function() return GetCombatRating(CR_CRIT_TAKEN_MELEE) end },
    { label = "Скор. закл.", key = "SPELLHASTE", func = function() return GetCombatRating(CR_HASTE_SPELL) end },
    { label = "Проб. брони", key = "ARP",        func = function() return GetCombatRating(CR_ARMOR_PENETRATION) end },
    { label = "Урон закл.",  key = "SP",         func = function()
        local maxDmg = 0
        for i = 2, 7 do
            local d = GetSpellBonusDamage(i) or 0
            if d > maxDmg then maxDmg = d end
        end
        return maxDmg
    end },
    { label = "Исцеление",   key = "HEAL",       func = function() return GetSpellBonusHealing() end },
    { label = "МП5",         key = "MP5",        func = function()
        local pt = UnitPowerType("player")
        if pt ~= 0 then return "-" end
        local base, combat = GetManaRegen()
        return format("%.1f", (base or 0) * 2.5)
    end },
}

function StatsPanel:Create()
    if self.frame then return end
    local S = NS.Styling
    local parent = (NS.NarciUI and NS.NarciUI.mainFrame) or UIParent

    local f = CreateFrame("Frame", "NarcissusSirus_StatsPanel", parent)
    f:SetWidth(PANEL_WIDTH)
    f:SetPoint("RIGHT", parent, "RIGHT", S.PANEL_X, S.PANEL_Y)
    f:SetHeight(S.PANEL_HEIGHT)
    f:SetFrameLevel(parent:GetFrameLevel() + 5)

    if f.SetBackdrop then
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        f:SetBackdropColor(S.BG_DARK[1], S.BG_DARK[2], S.BG_DARK[3], S.BG_DARK_A)
        f:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], S.BORDER[4])
    end
    S.CreateShadow(f, 5, 0.4)
    S.ApplyTabChrome(f)
    S.CreateGradientTopBorder(f)

    local nameLabel = f:CreateFontString(nil, "OVERLAY")
    nameLabel:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    nameLabel:SetPoint("TOP", f, "TOP", 0, -12)
    f.nameLabel = nameLabel

    local titleLine = f:CreateFontString(nil, "OVERLAY")
    titleLine:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    titleLine:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    titleLine:SetPoint("TOP", nameLabel, "BOTTOM", 0, -2)
    f.titleLine = titleLine

    local barY = -48

    local infoBox = CreateFrame("Frame", nil, f)
    infoBox:SetSize(PANEL_WIDTH - 20, 42)
    infoBox:SetPoint("TOP", f, "TOP", 0, barY - 4)
    if infoBox.SetBackdrop then
        infoBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        infoBox:SetBackdropColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.6)
        infoBox:SetBackdropBorderColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.35)
    end

    local eaLabel = infoBox:CreateFontString(nil, "OVERLAY")
    eaLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    eaLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    eaLabel:SetPoint("TOPLEFT", infoBox, "TOPLEFT", 10, -4)
    eaLabel:SetText(L["ЧАРЫ"])
    local eaValue = infoBox:CreateFontString(nil, "OVERLAY")
    eaValue:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    eaValue:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    eaValue:SetPoint("TOPLEFT", infoBox, "TOPLEFT", 10, -17)
    f.eaValue = eaValue

    local maxBox = CreateFrame("Frame", nil, infoBox)
    maxBox:SetSize(84, 36)
    maxBox:SetPoint("CENTER", infoBox, "CENTER", 0, 0)
    if maxBox.SetBackdrop then
        maxBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 2, right = 2, top = 2, bottom = 2 },
        })
        maxBox:SetBackdropColor(0.04, 0.04, 0.08, 0.9)
        maxBox:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.5)
    end
    local maxLbl = maxBox:CreateFontString(nil, "OVERLAY")
    maxLbl:SetFont("Fonts\\FRIZQT__.TTF", 8, "")
    maxLbl:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    maxLbl:SetPoint("TOP", maxBox, "TOP", 0, -3)
    maxLbl:SetText(L["УР.ПРЕДМ."])
    local maxVal = maxBox:CreateFontString(nil, "OVERLAY")
    maxVal:SetFont("Fonts\\FRIZQT__.TTF", 20, "OUTLINE")
    maxVal:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    maxVal:SetPoint("TOP", maxLbl, "BOTTOM", 0, -1)
    f.maxValue = maxVal

    local maxGlow = maxBox:CreateTexture(nil, "OVERLAY", nil, -1)
    maxGlow:SetAllPoints(maxVal)
    maxGlow:SetTexture("Interface\\Buttons\\WHITE8x8")
    maxGlow:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.3)
    S.AddBreathingGlow(maxGlow, 0.15, 0.35, 2.5)

    local tierLabel = infoBox:CreateFontString(nil, "OVERLAY")
    tierLabel:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    tierLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    tierLabel:SetPoint("TOPRIGHT", infoBox, "TOPRIGHT", -10, -4)
    tierLabel:SetText(L["НАБОР"])
    local tierValue = infoBox:CreateFontString(nil, "OVERLAY")
    tierValue:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    tierValue:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    tierValue:SetPoint("TOPRIGHT", infoBox, "TOPRIGHT", -10, -17)
    f.tierValue = tierValue

    S.CreateAnimatedSeparator(f, barY - 52)

    local legend = f:CreateFontString(nil, "OVERLAY")
    legend:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    legend:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    legend:SetPoint("TOPLEFT", f, "TOPLEFT", LEFT_X + LABEL_INSET + 11, barY - 56)
    legend:SetJustifyH("LEFT")
    legend:SetText(L["важные статы"])

    local swatch = f:CreateTexture(nil, "ARTWORK")
    swatch:SetSize(6, 6)
    swatch:SetPoint("RIGHT", legend, "LEFT", -5, 0)
    swatch:SetTexture("Interface\\Buttons\\WHITE8x8")
    swatch:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)

    f.capsLegend = legend
    f.capsSwatch = swatch

    local source = f:CreateFontString(nil, "OVERLAY")
    source:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    source:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    source:SetPoint("TOPRIGHT", f, "TOPRIGHT", -(PANEL_WIDTH - (RIGHT_X + COL_WIDTH)), barY - 56)
    source:SetJustifyH("RIGHT")
    f.sourceText = source

    local scrollTop = barY - 70
    local scrollBottom = 8

    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 0, scrollTop)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -24, scrollBottom)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(LIST_WIDTH)
    scrollFrame:SetScrollChild(scrollChild)
    S.StyleScrollBar(scrollFrame)

    local tableY = 0

    local function DividerHalf(upper)
        local t = scrollChild:CreateTexture(nil, "BACKGROUND")
        t:SetWidth(1)
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        local B = S.BORDER
        if upper then
            t:SetPoint("TOP", scrollChild, "TOPLEFT", DIVIDER_X, 0)
            t:SetPoint("BOTTOM", scrollChild, "LEFT", DIVIDER_X, 0)
            t:SetGradientAlpha("VERTICAL", B[1], B[2], B[3], 0.55, B[1], B[2], B[3], 0)
        else
            t:SetPoint("TOP", scrollChild, "LEFT", DIVIDER_X, 0)
            t:SetPoint("BOTTOM", scrollChild, "BOTTOMLEFT", DIVIDER_X, 0)
            t:SetGradientAlpha("VERTICAL", B[1], B[2], B[3], 0, B[1], B[2], B[3], 0.55)
        end
    end
    DividerHalf(true)
    DividerHalf(false)

    local function CreateHighlight(x1, x2, y)
        local plate = scrollChild:CreateTexture(nil, "BORDER")
        plate:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", x1, y + 1)
        plate:SetPoint("BOTTOMRIGHT", scrollChild, "TOPLEFT", x2, y - ROW_HEIGHT + 3)
        plate:SetTexture("Interface\\Buttons\\WHITE8x8")
        plate:SetGradientAlpha("HORIZONTAL",
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.20,
            S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.0)
        plate:Hide()

        local bar = scrollChild:CreateTexture(nil, "ARTWORK")
        bar:SetWidth(2)
        bar:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", x1, y + 1)
        bar:SetPoint("BOTTOMLEFT", scrollChild, "TOPLEFT", x1, y - ROW_HEIGHT + 3)
        bar:SetTexture("Interface\\Buttons\\WHITE8x8")
        bar:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.95)
        bar:Hide()

        return { plate = plate, bar = bar }
    end

    f.statRows = {}
    local maxRows = math.max(#STAT_LEFT, #STAT_RIGHT)

    for i = 1, maxRows do
        local y = tableY - (i - 1) * ROW_HEIGHT
        local row = {}

        if i % 2 == 0 then
            local stripe = scrollChild:CreateTexture(nil, "BACKGROUND")
            stripe:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", LEFT_X, y + 2)
            stripe:SetPoint("BOTTOMRIGHT", scrollChild, "TOPLEFT", RIGHT_X + COL_WIDTH, y - ROW_HEIGHT + 2)
            stripe:SetTexture("Interface\\Buttons\\WHITE8x8")
            stripe:SetVertexColor(S.BG_STRIPE[1], S.BG_STRIPE[2], S.BG_STRIPE[3], 0.10)
        end

        if STAT_LEFT[i] then
            local ll = scrollChild:CreateFontString(nil, "OVERLAY")
            ll:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            ll:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
            ll:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", LEFT_X + LABEL_INSET, y)
            ll:SetWidth(LABEL_WIDTH)
            ll:SetJustifyH("LEFT")
            ll:SetText(L[STAT_LEFT[i].label])
            local lv = scrollChild:CreateFontString(nil, "OVERLAY")
            lv:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            lv:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
            lv:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", LEFT_X + COL_WIDTH - VALUE_WIDTH, y)
            lv:SetWidth(VALUE_WIDTH)
            lv:SetJustifyH("RIGHT")
            row.leftValue = lv
            row.leftFunc = STAT_LEFT[i].func
            row.leftLabel = ll
            row.leftKey = STAT_LEFT[i].key
            if row.leftKey then
                row.leftHL = CreateHighlight(LEFT_X, LEFT_X + COL_WIDTH, y)
            end
        end

        if STAT_RIGHT[i] then
            local rl = scrollChild:CreateFontString(nil, "OVERLAY")
            rl:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
            rl:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
            rl:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", RIGHT_X + LABEL_INSET, y)
            rl:SetWidth(LABEL_WIDTH)
            rl:SetJustifyH("LEFT")
            rl:SetText(L[STAT_RIGHT[i].label])
            local rv = scrollChild:CreateFontString(nil, "OVERLAY")
            rv:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
            rv:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
            rv:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", RIGHT_X + COL_WIDTH - VALUE_WIDTH, y)
            rv:SetWidth(VALUE_WIDTH)
            rv:SetJustifyH("RIGHT")
            row.rightValue = rv
            row.rightFunc = STAT_RIGHT[i].func
            row.rightLabel = rl
            row.rightKey = STAT_RIGHT[i].key
            if row.rightKey then
                row.rightHL = CreateHighlight(RIGHT_X, RIGHT_X + COL_WIDTH, y)
            end
        end

        f.statRows[i] = row
    end

    scrollChild:SetHeight(maxRows * ROW_HEIGHT + 4)

    self.frame = f
    f:Hide()
end

function StatsPanel:Update()
    if not self.frame then self:Create() end
    local S = NS.Styling
    local f = self.frame

    local showCaps = not NS.db or NS.db.showStatCaps ~= false
    local priority, info, tierText, sourceText
    if NS.StatPriority then
        local ok, set, detected = pcall(NS.StatPriority.Get, NS.StatPriority)
        if ok then
            priority, info = set, detected
            local okt, t = pcall(NS.StatPriority.GetTierLabel, NS.StatPriority, info)
            if okt then tierText = t end
            local oks, s = pcall(NS.StatPriority.GetSourceLabel, NS.StatPriority, info)
            if oks then sourceText = s end
        end
    end
    priority = (showCaps and priority) or {}
    f.sourceText:SetText(showCaps and (sourceText or "") or "")
    if f.capsLegend then
        if showCaps then f.capsLegend:Show() else f.capsLegend:Hide() end
    end
    if f.capsSwatch then
        if showCaps then f.capsSwatch:Show() else f.capsSwatch:Hide() end
    end

    local name = UnitName("player")
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class]
    if color then
        f.nameLabel:SetText(format("|cff%02x%02x%02x%s|r", color.r*255, color.g*255, color.b*255, name))
    else
        f.nameLabel:SetText(name or "")
    end
    local level = UnitLevel("player")
    local race = UnitRace("player")
    local _, localizedClass = UnitClass("player")
    local subtitle = format("|cff00ccff%d|r %s %s", level, race, localizedClass)
    if info and info.specName then
        subtitle = subtitle .. format("  |cff%02x%02x%02x%s|r",
            S.ACCENT_GLOW[1] * 255, S.ACCENT_GLOW[2] * 255, S.ACCENT_GLOW[3] * 255,
            info.specName)
    end
    f.titleLine:SetText(subtitle)

    f.maxValue:SetText(floor(NS.GetAverageItemLevel()))
    local enchantCount, totalEnchantable = 0, 0
    for slotId, _ in pairs(NS.ENCHANTABLE_SLOTS or {}) do
        totalEnchantable = totalEnchantable + 1
        local link = GetInventoryItemLink("player", slotId)
        if link and NS.GetEnchantInfo(link) then enchantCount = enchantCount + 1 end
    end
    f.eaValue:SetText(format("%d/%d", enchantCount, totalEnchantable))
    f.tierValue:SetText(tierText or L["нет"])
    if info and info.tier then
        f.tierValue:SetTextColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3])
    else
        f.tierValue:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    end

    local function UpdateValue(fs, func)
        if not func then return end
        local ok, val = pcall(func)
        local newText = ok and tostring(val) or "-"
        local color = ValueColor(newText)
        local changed = fs:GetText() ~= newText
        fs:SetText(newText)
        fs:SetTextColor(color[1], color[2], color[3])
        if changed then S.FlashValue(fs, 0.35, color) end
    end

    local function UpdateLabel(fs, hl, key)
        if not fs then return end
        local on = (key and priority[key]) and true or false
        if on then
            fs:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
        else
            fs:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
        end
        if hl then
            if on then
                hl.plate:Show()
                hl.bar:Show()
            else
                hl.plate:Hide()
                hl.bar:Hide()
            end
        end
    end

    for _, row in ipairs(f.statRows) do
        UpdateValue(row.leftValue, row.leftFunc)
        UpdateValue(row.rightValue, row.rightFunc)
        UpdateLabel(row.leftLabel, row.leftHL, row.leftKey)
        UpdateLabel(row.rightLabel, row.rightHL, row.rightKey)
    end
end

function StatsPanel:Toggle()
    if not self.frame then self:Create() end
    if self.frame:IsShown() then
        NS.Styling.PanelOut(self.frame)
    else
        self:Update()
        NS.Styling.PanelIn(self.frame)
    end
end

function StatsPanel:Hide() NS.Styling.PanelHideNow(self.frame) end

NS.StatsPanel = StatsPanel
