local addonName, NS = ...
local L = NS.L

local TalentPanel = {}
local format = string.format

local MAX_HEIGHT   = 720
local TREE_GAP     = 22
local PANEL_PAD    = 18
local CARD_PAD     = 10
local HEADER_H     = 24
local GRID_TOP     = -118
local GRID_BOTTOM  = 18
local MAX_TIERS    = 11

local NUM_GLYPHS      = 6
local GLYPHTYPE_MAJOR = 1

local SIDEBAR_W = 150

local function ActiveGroup()
    if C_Talent and C_Talent.GetActiveTalentGroup then
        local ok, g = pcall(C_Talent.GetActiveTalentGroup, false, false)
        if ok and g then return g end
    end
    if GetActiveTalentGroup then
        local ok, g = pcall(GetActiveTalentGroup)
        if ok and g then return g end
    end
    return 1
end

local function NumGroups()
    if C_Talent and C_Talent.GetNumTalentGroups then
        local ok, n = pcall(C_Talent.GetNumTalentGroups, false, false)
        if ok and n then return n end
    end
    return 1
end

function TalentPanel:ViewGroup()
    local active = ActiveGroup()
    local g = self.viewGroup or active
    if g > NumGroups() then g = active end
    return g
end

function TalentPanel:ViewSlot()
    return (self:ViewGroup() == ActiveGroup()) and 1 or 2
end

local function Money(copper)
    if not copper then return "" end
    if GetMoneyString then
        local ok, s = pcall(GetMoneyString, copper)
        if ok and s then return s end
    end
    return tostring(math.floor(copper / 10000)) .. L["з"]
end

function TalentPanel:CreateTalentButton(parent, tabIndex, talentIndex)
    local S = NS.Styling

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(self.iconSize, self.iconSize)
    btn:RegisterForClicks("LeftButtonUp")

    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    btn.icon = icon

    local border = CreateFrame("Frame", nil, btn)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:EnableMouse(false)
    btn.border = border

    local rankBg = btn:CreateTexture(nil, "OVERLAY", nil, -1)
    rankBg:SetSize(18, 12)
    rankBg:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 2, -2)
    rankBg:SetTexture("Interface\\Buttons\\WHITE8x8")
    rankBg:SetVertexColor(0, 0, 0, 0.75)
    btn.rankBg = rankBg

    local rank = btn:CreateFontString(nil, "OVERLAY")
    rank:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    rank:SetPoint("CENTER", rankBg, "CENTER", 0, 0)
    btn.rank = rank

    btn:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
    btn:GetHighlightTexture():SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.25)

    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        pcall(GameTooltip.SetTalent, GameTooltip, tabIndex, talentIndex, false, false, TalentPanel:ViewSlot())
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    btn:SetScript("OnClick", function(self)
        if not self.learnable then return end
        pcall(LearnTalent, tabIndex, talentIndex, false, 1)
        TalentPanel:Update()
    end)

    btn.tabIndex = tabIndex
    btn.talentIndex = talentIndex
    return btn
end

function TalentPanel:CreateTree(parent, tabIndex, x)
    local S = NS.Styling
    local gridW = self.colPitch * 4
    local gridH = MAX_TIERS * self.rowPitch

    local tree = CreateFrame("Frame", nil, parent)
    tree:SetSize(gridW + CARD_PAD * 2, HEADER_H + gridH + CARD_PAD)
    tree:SetPoint("TOPLEFT", parent, "TOPLEFT", x, GRID_TOP)
    if tree.SetBackdrop then
        tree:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        tree:SetBackdropColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.5)
        tree:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.95)
    end

    local strip = tree:CreateTexture(nil, "BACKGROUND")
    strip:SetPoint("TOPLEFT", tree, "TOPLEFT", 1, -1)
    strip:SetPoint("TOPRIGHT", tree, "TOPRIGHT", -1, -1)
    strip:SetHeight(HEADER_H)
    strip:SetTexture("Interface\\Buttons\\WHITE8x8")
    strip:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.30,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)
    tree.strip = strip

    local rule = tree:CreateTexture(nil, "ARTWORK")
    rule:SetHeight(1)
    rule:SetPoint("TOPLEFT", strip, "BOTTOMLEFT", 0, 0)
    rule:SetPoint("TOPRIGHT", strip, "BOTTOMRIGHT", 0, 0)
    rule:SetTexture("Interface\\Buttons\\WHITE8x8")
    rule:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55)

    local header = tree:CreateFontString(nil, "OVERLAY")
    header:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    header:SetPoint("LEFT", strip, "LEFT", 8, 0)
    header:SetJustifyH("LEFT")
    tree.header = header

    local spent = tree:CreateFontString(nil, "OVERLAY")
    spent:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    spent:SetPoint("RIGHT", strip, "RIGHT", -8, 0)
    spent:SetJustifyH("RIGHT")
    tree.spent = spent

    tree.gridX = CARD_PAD
    tree.gridY = -(HEADER_H + CARD_PAD)

    tree.buttons = {}
    tree.links = {}
    tree.tabIndex = tabIndex
    return tree
end

function TalentPanel:GetLink(tree, index)
    local link = tree.links[index]
    if not link then
        link = tree:CreateTexture(nil, "BACKGROUND")
        link:SetTexture("Interface\\Buttons\\WHITE8x8")
        tree.links[index] = link
    end
    return link
end

function TalentPanel:Create()
    if self.frame then return end
    local S = NS.Styling
    local parent = (NS.NarciUI and NS.NarciUI.mainFrame) or UIParent

    local ph = parent:GetHeight() or 768
    local height = math.min(MAX_HEIGHT, ph - 120)

    local gridHeight = height + GRID_TOP - GRID_BOTTOM - HEADER_H - CARD_PAD
    self.rowPitch = math.max(26, math.floor(gridHeight / MAX_TIERS))
    self.iconSize = math.max(20, math.min(self.rowPitch - 8, 46))
    self.colPitch = self.iconSize + 14

    local cardWidth = self.colPitch * 4 + CARD_PAD * 2
    local width = SIDEBAR_W + cardWidth * 3 + TREE_GAP * 2 + PANEL_PAD * 2
    self.cardWidth = cardWidth

    local f = CreateFrame("Frame", "NarcissusSirus_TalentPanel", parent)
    f:SetSize(width, height)
    f:SetPoint("CENTER", parent, "CENTER", 0, 10)
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

    local sidebar = f:CreateTexture(nil, "BACKGROUND")
    sidebar:SetPoint("TOPLEFT", f, "TOPLEFT", 4, -4)
    sidebar:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 4, 4)
    sidebar:SetWidth(SIDEBAR_W - 8)
    sidebar:SetTexture("Interface\\Buttons\\WHITE8x8")
    sidebar:SetVertexColor(0, 0, 0, 0.35)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    title:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    title:SetPoint("TOP", f, "TOPLEFT", SIDEBAR_W + (width - SIDEBAR_W) / 2, -12)
    f.title = title

    local points = f:CreateFontString(nil, "OVERLAY")
    points:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    points:SetPoint("TOPRIGHT", f, "TOPRIGHT", -14, -16)
    points:SetJustifyH("RIGHT")
    f.points = points

    local specIcon = f:CreateTexture(nil, "ARTWORK")
    specIcon:SetSize(44, 44)
    specIcon:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -18)
    specIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    f.specIcon = specIcon

    local specRing = CreateFrame("Frame", nil, f)
    specRing:SetPoint("TOPLEFT", specIcon, "TOPLEFT", -1, 1)
    specRing:SetPoint("BOTTOMRIGHT", specIcon, "BOTTOMRIGHT", 1, -1)
    specRing:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    specRing:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
    specRing:EnableMouse(false)

    local specName = f:CreateFontString(nil, "OVERLAY")
    specName:SetFont("Fonts\\FRIZQT__.TTF", 13, "OUTLINE")
    specName:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    specName:SetPoint("LEFT", specIcon, "RIGHT", 8, 6)
    specName:SetJustifyH("LEFT")
    specName:SetWidth(SIDEBAR_W - 74)
    f.specName = specName

    local specSplit = f:CreateFontString(nil, "OVERLAY")
    specSplit:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    specSplit:SetTextColor(S.GOLD_DIM[1], S.GOLD_DIM[2], S.GOLD_DIM[3])
    specSplit:SetPoint("TOPLEFT", specName, "BOTTOMLEFT", 0, -2)
    specSplit:SetJustifyH("LEFT")
    f.specSplit = specSplit

    local specRule = f:CreateTexture(nil, "ARTWORK")
    specRule:SetHeight(1)
    specRule:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -74)
    specRule:SetPoint("TOPRIGHT", f, "TOPLEFT", SIDEBAR_W - 12, -74)
    specRule:SetTexture("Interface\\Buttons\\WHITE8x8")
    specRule:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.6,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.05)

    local talentBtn = NS.Widgets.CreateThemedButton(f, L["Таланты"], SIDEBAR_W - 24, 20, function()
        self.view = "talents"
        self:Update()
    end)
    talentBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -106)
    f.talentBtn = talentBtn

    local glyphBtn = NS.Widgets.CreateThemedButton(f, L["Символы"], SIDEBAR_W - 24, 20, function()
        self.view = "glyphs"
        self:Update()
    end)
    glyphBtn:SetPoint("TOPLEFT", talentBtn, "BOTTOMLEFT", 0, -4)
    f.glyphBtn = glyphBtn

    local groupsLabel = f:CreateFontString(nil, "OVERLAY")
    groupsLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
    groupsLabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    groupsLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -160)
    groupsLabel:SetText(L["НАБОРЫ"])

    local divider = f:CreateTexture(nil, "ARTWORK")
    divider:SetWidth(1)
    divider:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 0, 0)
    divider:SetPoint("BOTTOMLEFT", sidebar, "BOTTOMRIGHT", 0, 0)
    divider:SetTexture("Interface\\Buttons\\WHITE8x8")
    divider:SetVertexColor(S.ACCENT_DIM[1], S.ACCENT_DIM[2], S.ACCENT_DIM[3], 0.8)

    f.groupButtons = {}
    for i = 1, 5 do
        local gb = NS.Widgets.CreateThemedButton(f, "", SIDEBAR_W - 24, 20, function()
            self.viewGroup = i
            self.talentsReady = (i == ActiveGroup())
            if C_Talent and C_Talent.SelectTalentGroup then
                pcall(C_Talent.SelectTalentGroup, i)
            end
            self:Update()
        end)
        gb:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -174 - (i - 1) * 26)
        gb:Hide()
        f.groupButtons[i] = gb
    end

    local activateBtn = NS.Widgets.CreateThemedButton(f, L["Активировать"], 110, 20, function()
        local g = self:ViewGroup()
        NS.Widgets.ShowConfirm(
            format(L["Сделать набор %d активным?"], g), L["Активировать"],
            function()
                if C_Talent and C_Talent.SelectTalentGroup then
                    pcall(C_Talent.SelectTalentGroup, g)
                end
                pcall(C_Talent.SetActiveTalentGroup, g)
                self.viewGroup = nil
                self:Update()
            end)
    end)
    activateBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -96 - 5 * 24 - 8)
    activateBtn:Hide()
    f.activateBtn = activateBtn

    f.currencyButtons = {}
    for i = 1, 2 do
        local cb = CreateFrame("Button", nil, f)
        cb:SetSize(24, 24)
        cb:SetPoint("TOPLEFT", activateBtn, "BOTTOMLEFT", (i - 1) * 30, -6)

        local ci = cb:CreateTexture(nil, "ARTWORK")
        ci:SetAllPoints()
        ci:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        cb.icon = ci

        local cborder = CreateFrame("Frame", nil, cb)
        cborder:SetPoint("TOPLEFT", -1, 1)
        cborder:SetPoint("BOTTOMRIGHT", 1, -1)
        cborder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        cborder:EnableMouse(false)
        cb.border = cborder

        local ccount = cb:CreateFontString(nil, "OVERLAY")
        ccount:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        ccount:SetPoint("BOTTOMRIGHT", cb, "BOTTOMRIGHT", 1, -1)
        cb.count = ccount

        cb:SetScript("OnEnter", function(slf)
            if not slf.link then return end
            GameTooltip:SetOwner(slf, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(slf.link)
            GameTooltip:Show()
        end)
        cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
        cb:SetScript("OnClick", function()
            pcall(C_Talent.SelectedCurrency, i)
            self:Update()
        end)

        cb:Hide()
        f.currencyButtons[i] = cb
    end

    local buyBtn = NS.Widgets.CreateThemedButton(f, L["Купить второй набор"], 150, 20, function()
        local price
        if C_Talent and C_Talent.GetSecondSpecPrice then
            local ok, p = pcall(C_Talent.GetSecondSpecPrice)
            if ok then price = p end
        end
        NS.Widgets.ShowConfirm(
            L["Купить второй набор талантов?\n"] .. Money(price),
            L["Купить"],
            function()
                pcall(C_Talent.PurchaseSecondSpec)
                self:Update()
            end)
    end, S.GOLD)
    buyBtn:SetWidth(SIDEBAR_W - 24)
    buyBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 12, -96 - 5 * 24 - 8)
    buyBtn:Hide()
    f.buyBtn = buyBtn

    local resetBtn = NS.Widgets.CreateThemedButton(f, L["Сбросить таланты"], 130, 20, function()
        local cost = C_Talent.GetResetCost and C_Talent.GetResetCost()
        NS.Widgets.ShowConfirm(
            L["Сбросить все таланты активного набора?\n"] ..
                (cost and (L["Стоимость: "] .. Money(cost)) or ""),
            L["Сбросить"],
            function()
                pcall(C_Talent.RequestResetTalent)
                self:Update()
            end)
    end, { 0.85, 0.35, 0.35 })
    resetBtn:SetWidth(SIDEBAR_W - 24)
    resetBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 12, 14)
    f.resetBtn = resetBtn

    f.trees = {}
    for tab = 1, 3 do
        local x = SIDEBAR_W + PANEL_PAD + (tab - 1) * (self.cardWidth + TREE_GAP)
        f.trees[tab] = self:CreateTree(f, tab, x)
    end

    local loading = f:CreateFontString(nil, "OVERLAY")
    loading:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    loading:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    loading:SetPoint("CENTER", f, "LEFT", SIDEBAR_W + (width - SIDEBAR_W) / 2, 0)
    loading:SetText(L["Загрузка набора..."])
    loading:Hide()
    f.loading = loading

    local glyphs = CreateFrame("Frame", nil, f)
    glyphs:SetPoint("TOPLEFT", f, "TOPLEFT", SIDEBAR_W, -80)
    glyphs:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", 0, 0)
    glyphs:Hide()
    f.glyphFrame = glyphs

    local hint = glyphs:CreateFontString(nil, "OVERLAY")
    hint:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    hint:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    hint:SetPoint("TOP", glyphs, "TOP", 0, -8)
    hint:SetWidth(width - SIDEBAR_W - 40)
    hint:SetJustifyH("CENTER")
    hint:SetText(L["Щёлкните символ в сумке правой кнопкой, затем левой по гнезду.\nShift + ПКМ по гнезду убирает символ."])

    f.glyphSlots = {}
    for i = 1, NUM_GLYPHS do
        local slot = CreateFrame("Button", nil, glyphs)
        slot:SetSize(56, 56)
        local col = (i - 1) % 3
        local row = math.floor((i - 1) / 3)
        slot:SetPoint("TOP", glyphs, "TOP", (col - 1) * 200, -76 - row * 130)
        slot:RegisterForClicks("LeftButtonUp", "RightButtonUp")

        local sbg = slot:CreateTexture(nil, "BACKGROUND")
        sbg:SetAllPoints()
        sbg:SetTexture("Interface\\Buttons\\WHITE8x8")
        sbg:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.9)

        local sicon = slot:CreateTexture(nil, "ARTWORK")
        sicon:SetPoint("TOPLEFT", 2, -2)
        sicon:SetPoint("BOTTOMRIGHT", -2, 2)
        sicon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        slot.icon = sicon

        local rune = slot:CreateTexture(nil, "ARTWORK")
        rune:SetPoint("TOPLEFT", 6, -6)
        rune:SetPoint("BOTTOMRIGHT", -6, 6)
        rune:SetTexture("Interface\\Spellbook\\UI-Glyph-Rune1")
        rune:SetVertexColor(0.45, 0.48, 0.58, 0.55)
        slot.emptyRune = rune

        local kind = slot:CreateFontString(nil, "OVERLAY")
        kind:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
        kind:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        kind:SetPoint("BOTTOM", slot, "TOP", 0, 3)
        slot.kind = kind

        local sborder = CreateFrame("Frame", nil, slot)
        sborder:SetPoint("TOPLEFT", -1, 1)
        sborder:SetPoint("BOTTOMRIGHT", 1, -1)
        sborder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        sborder:EnableMouse(false)
        slot.border = sborder

        local slabel = slot:CreateFontString(nil, "OVERLAY")
        slabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "")
        slabel:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        slabel:SetPoint("TOP", slot, "BOTTOM", 0, -5)
        slabel:SetWidth(180)
        slabel:SetJustifyH("CENTER")
        slot.label = slabel

        slot:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
        slot:GetHighlightTexture():SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.2)

        slot:SetScript("OnEnter", function(self)
            if not self.enabled then return end
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            local link = GetGlyphLink and GetGlyphLink(i, TalentPanel:ViewSlot())
            if link and link ~= "" then
                GameTooltip:SetHyperlink(link)
            else
                GameTooltip:SetText(L["Пустое гнездо символа"], 0.8, 0.8, 0.8)
            end
            GameTooltip:Show()
        end)
        slot:SetScript("OnLeave", function() GameTooltip:Hide() end)

        slot:SetScript("OnClick", function(self, button)
            if not self.enabled then return end
            if TalentPanel:ViewGroup() ~= ActiveGroup() then return end
            if button == "RightButton" then
                if IsShiftKeyDown() and self.hasGlyph then
                    NS.Widgets.ShowConfirm(L["Убрать символ из этого гнезда?"], L["Убрать"], function()
                        pcall(RemoveGlyphFromSocket, i)
                        TalentPanel:Update()
                    end)
                end
                return
            end
            pcall(PlaceGlyphInSocket, i)
            TalentPanel:Update()
        end)

        f.glyphSlots[i] = slot
    end

    local ev = CreateFrame("Frame")
    if ev.RegisterCustomEvent then
        pcall(ev.RegisterCustomEvent, ev, "PLAYER_TALENT_ACTIVE_GROUP_CHANGED")
        pcall(ev.RegisterCustomEvent, ev, "PLAYER_TALENT_UPDATE_EX")
    end
    ev:SetScript("OnEvent", function(_, event, groupID, groupIndex, ready)
        if event == "PLAYER_TALENT_ACTIVE_GROUP_CHANGED" then
            self.talentsReady = ready and true or false
        end
        if self.frame and self.frame:IsShown() then self:Update() end
    end)
    f.eventFrame = ev

    f:SetScript("OnHide", function()
        if NS.NarciUI and NS.NarciUI.isShown then
            NS.NarciUI:SetSceneVisible(true)
        end
        self.viewGroup = nil
    end)

    self.view = self.view or "talents"
    self.frame = f
    f:Hide()
end

function TalentPanel:UpdateTree(tree)
    local S = NS.Styling
    local tab = tree.tabIndex
    local slot = self:ViewSlot()
    local isActiveGroup = self:ViewGroup() == ActiveGroup()

    local name, _, pointsSpent = GetTalentTabInfo(tab, false, false, slot)
    pointsSpent = pointsSpent or 0
    tree.header:SetText(name or "?")
    tree.header:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    tree.spent:SetText(pointsSpent)
    if pointsSpent > 0 then
        tree.spent:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
    else
        tree.spent:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
    end

    local unspent = GetUnspentTalentPoints and GetUnspentTalentPoints(false, false, slot) or 0
    local numTalents = GetNumTalents(tab, false, false) or 0

    for i = 1, numTalents do
        local btn = tree.buttons[i]
        if not btn then
            btn = self:CreateTalentButton(tree, tab, i)
            tree.buttons[i] = btn
        end

        local tName, icon, tier, column, rank, maxRank, _, meetsPrereq =
            GetTalentInfo(tab, i, false, false, slot)

        if tName and tier and column then
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", tree, "TOPLEFT",
                tree.gridX + (column - 1) * self.colPitch,
                tree.gridY - (tier - 1) * self.rowPitch)
            btn:Show()
            btn.icon:SetTexture(icon)

            rank = rank or 0
            maxRank = maxRank or 0
            btn.rank:SetText(format("%d/%d", rank, maxRank))

            local spent = rank > 0
            if btn.icon.SetDesaturated then
                btn.icon:SetDesaturated(not spent)
            end
            if spent then
                btn.icon:SetVertexColor(1, 1, 1, 1)
            elseif meetsPrereq then
                btn.icon:SetVertexColor(0.85, 0.85, 0.85, 1)
            else
                btn.icon:SetVertexColor(0.40, 0.40, 0.45, 1)
            end

            if rank >= maxRank and maxRank > 0 then
                btn.border:SetBackdropBorderColor(S.GOLD[1], S.GOLD[2], S.GOLD[3], 0.95)
                btn.rank:SetTextColor(S.GOLD[1], S.GOLD[2], S.GOLD[3])
            elseif rank > 0 then
                btn.border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.95)
                btn.rank:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
            elseif meetsPrereq then
                btn.border:SetBackdropBorderColor(S.BORDER_LIGHT[1], S.BORDER_LIGHT[2], S.BORDER_LIGHT[3], 0.9)
                btn.rank:SetTextColor(S.TEXT_NORMAL[1], S.TEXT_NORMAL[2], S.TEXT_NORMAL[3])
            else
                btn.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.6)
                btn.rank:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
            end

            btn.learnable = isActiveGroup
                and meetsPrereq and rank < maxRank and unspent > 0

            local link = self:GetLink(tree, i)
            local pTier, pColumn = GetTalentPrereqs(tab, i, false, false, slot)
            if pTier and pColumn then
                link:ClearAllPoints()
                link:SetVertexColor(
                    meetsPrereq and S.ACCENT_DIM[1] or S.BORDER[1],
                    meetsPrereq and S.ACCENT_DIM[2] or S.BORDER[2],
                    meetsPrereq and S.ACCENT_DIM[3] or S.BORDER[3],
                    meetsPrereq and 0.5 or 0.3)
                local half = self.iconSize / 2
                local x1 = tree.gridX + (pColumn - 1) * self.colPitch + half
                local y1 = tree.gridY - (pTier - 1) * self.rowPitch - half
                local x2 = tree.gridX + (column - 1) * self.colPitch + half
                local y2 = tree.gridY - (tier - 1) * self.rowPitch - half
                if pColumn == column then
                    link:SetWidth(2)
                    link:SetPoint("TOPLEFT", tree, "TOPLEFT", x1 - 1, y1)
                    link:SetPoint("BOTTOMRIGHT", tree, "TOPLEFT", x1 + 1, y2)
                else
                    link:SetHeight(2)
                    link:SetPoint("TOPLEFT", tree, "TOPLEFT", math.min(x1, x2), y1 + 1)
                    link:SetPoint("BOTTOMRIGHT", tree, "TOPLEFT", math.max(x1, x2), y1 - 1)
                end
                link:Show()
            else
                link:Hide()
            end
        else
            btn:Hide()
            local link = tree.links[i]
            if link then link:Hide() end
        end
    end

    for i = numTalents + 1, #tree.buttons do
        tree.buttons[i]:Hide()
        if tree.links[i] then tree.links[i]:Hide() end
    end
end

function TalentPanel:UpdateGlyphs()
    local S = NS.Styling
    local f = self.frame
    local groupSlot = self:ViewSlot()

    for i = 1, NUM_GLYPHS do
        local slot = f.glyphSlots[i]
        local enabled, glyphType, glyphSpell = GetGlyphSocketInfo(i, groupSlot)

        slot.enabled = enabled and true or false
        slot.hasGlyph = glyphSpell and true or false
        slot.kind:SetText(glyphType == GLYPHTYPE_MAJOR and L["большой"] or L["малый"])

        if not enabled then
            slot.icon:SetTexture(nil)
            slot.emptyRune:Hide()
            slot.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.4)
            slot.label:SetText(L["недоступно"])
            slot.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        elseif glyphSpell then
            local spellName, _, spellIcon = GetSpellInfo(glyphSpell)
            slot.icon:SetTexture(spellIcon or "Interface\\Spellbook\\UI-Glyph-Rune1")
            slot.icon:SetVertexColor(1, 1, 1, 1)
            slot.icon:Show()
            slot.emptyRune:Hide()
            slot.border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
            slot.label:SetText(spellName or "")
            slot.label:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        else
            slot.icon:SetTexture(nil)
            slot.emptyRune:Show()
            slot.border:SetBackdropBorderColor(S.BORDER_LIGHT[1], S.BORDER_LIGHT[2], S.BORDER_LIGHT[3], 0.8)
            slot.label:SetText(L["пустое гнездо"])
            slot.label:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
    end
end

function TalentPanel:UpdateGroups()
    local S = NS.Styling
    local f = self.frame
    local active = ActiveGroup()
    local view = self:ViewGroup()
    local total = NumGroups()

    local lastVisible

    for i = 1, #f.groupButtons do
        local gb = f.groupButtons[i]
        if i > total then
            gb:Hide()
        else
            lastVisible = gb
            local name
            if C_Talent and C_Talent.GetTalentGroupNote then
                local ok, n = pcall(C_Talent.GetTalentGroupNote, i)
                if ok and n and n ~= "" then name = n end
            end
            gb:SetText(name or format(L["Набор %d"], i))

            local color
            if i == active then
                color = S.ACCENT_GLOW
            elseif i == view then
                color = S.GOLD
            else
                color = S.TEXT_DIM
            end
            gb.label:SetTextColor(color[1], color[2], color[3])
            gb:Show()
        end
    end

    local needActivate = view ~= active and view <= total
    local needCurrency = needActivate and view > 2

    local anchor = lastVisible or f.groupButtons[1]
    f.activateBtn:ClearAllPoints()
    f.activateBtn:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)
    f.buyBtn:ClearAllPoints()
    f.buyBtn:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -10)

    if needActivate then
        f.activateBtn:Show()
    else
        f.activateBtn:Hide()
    end

    for i = 1, #f.currencyButtons do
        local cb = f.currencyButtons[i]
        local name, icon, amount, _, link
        if C_Talent and C_Talent.GetCurrencyInfo then
            local ok, a, b, c, d, e = pcall(C_Talent.GetCurrencyInfo, i)
            if ok then name, icon, amount, _, link = a, b, c, d, e end
        end

        if needCurrency and name then
            cb.icon:SetTexture(icon)
            cb.count:SetText(amount or 0)
            cb.link = link
            local selected = C_Talent.GetSelectedCurrency and C_Talent.GetSelectedCurrency() == i
            if selected then
                cb.border:SetBackdropBorderColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
            else
                cb.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
            end
            cb.icon:SetVertexColor(1, 1, 1, (amount or 0) > 0 and 1 or 0.35)
            cb.count:SetTextColor(
                (amount or 0) > 0 and S.TEXT_BRIGHT[1] or 0.9,
                (amount or 0) > 0 and S.TEXT_BRIGHT[2] or 0.3,
                (amount or 0) > 0 and S.TEXT_BRIGHT[3] or 0.3)
            cb:Show()
        else
            cb:Hide()
        end
    end

    local canBuy = total < 2 and C_Talent and C_Talent.CanPurchaseSecondSpec
        and select(2, pcall(C_Talent.CanPurchaseSecondSpec)) and true or false
    if canBuy then f.buyBtn:Show() else f.buyBtn:Hide() end

    local canReset = C_Talent and C_Talent.CanResetTalents
        and select(2, pcall(C_Talent.CanResetTalents)) and true or false
    f.resetBtn:SetAlpha(canReset and 1 or 0.4)
    f.resetBtn:EnableMouse(canReset)
end

function TalentPanel:Update()
    if not self.frame then self:Create() end
    local S = NS.Styling
    local f = self.frame
    local slot = self:ViewSlot()

    self:UpdateGroups()

    local unspent = GetUnspentTalentPoints and GetUnspentTalentPoints(false, false, slot) or 0
    if unspent > 0 then
        f.points:SetText(format(L["|cff%02x%02x%02xочков: %d|r"],
            S.GOLD[1] * 255, S.GOLD[2] * 255, S.GOLD[3] * 255, unspent))
    else
        f.points:SetText("")
    end

    local talentView = self.view ~= "glyphs"

    f.title:SetText(talentView and L["Таланты"] or L["Символы"])

    local t1, t2, t3 = 0, 0, 0
    local topTab, topPoints = 1, -1
    for tab = 1, 3 do
        local _, _, sp = GetTalentTabInfo(tab, false, false, slot)
        sp = sp or 0
        if tab == 1 then t1 = sp elseif tab == 2 then t2 = sp else t3 = sp end
        if sp > topPoints then topPoints, topTab = sp, tab end
    end
    local topName, topIcon = GetTalentTabInfo(topTab, false, false, slot)
    f.specIcon:SetTexture(topIcon)
    f.specName:SetText(topPoints > 0 and (topName or "") or L["нет очков"])
    f.specSplit:SetText(format("%d / %d / %d", t1, t2, t3))

    f.talentBtn.label:SetTextColor(
        talentView and S.ACCENT_GLOW[1] or S.TEXT_DIM[1],
        talentView and S.ACCENT_GLOW[2] or S.TEXT_DIM[2],
        talentView and S.ACCENT_GLOW[3] or S.TEXT_DIM[3])
    f.glyphBtn.label:SetTextColor(
        talentView and S.TEXT_DIM[1] or S.ACCENT_GLOW[1],
        talentView and S.TEXT_DIM[2] or S.ACCENT_GLOW[2],
        talentView and S.TEXT_DIM[3] or S.ACCENT_GLOW[3])

    local ready = (self:ViewGroup() == ActiveGroup()) or (self.talentsReady ~= false)

    for tab = 1, 3 do
        if talentView and ready then
            f.trees[tab]:Show()
            self:UpdateTree(f.trees[tab])
        else
            f.trees[tab]:Hide()
        end
    end

    if talentView and not ready then
        f.loading:Show()
    else
        f.loading:Hide()
    end

    if talentView then
        f.glyphFrame:Hide()
    else
        f.glyphFrame:Show()
        self:UpdateGlyphs()
    end
end

function TalentPanel:Toggle()
    if not self.frame then self:Create() end
    if self.frame:IsShown() then
        NS.Styling.PanelOut(self.frame)
    else
        if NS.NarciUI then NS.NarciUI:SetSceneVisible(false) end
        self:Update()
        NS.Styling.PanelIn(self.frame)
    end
end

function TalentPanel:Hide() NS.Styling.PanelHideNow(self.frame) end

NS.TalentPanel = TalentPanel
