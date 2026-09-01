local addonName, NS = ...
local L = NS.L

local PANEL_H     = 620
local PANEL_TOP   = 44
local PANEL_FOOT  = 26

local function CreateSettingsPanel()
    if NS.settingsFrame then return end

    local f = CreateFrame("Frame", "NarcissusSirus_SettingsFrame", UIParent)
    f:SetSize(360, PANEL_H)
    f:SetPoint("CENTER")
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetFrameLevel(240)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

    NS.Styling.ApplyPanelStyle(f, 360, PANEL_H)

    local title = f:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 15, "OUTLINE")
    title:SetTextColor(NS.Styling.ACCENT_GLOW[1], NS.Styling.ACCENT_GLOW[2], NS.Styling.ACCENT_GLOW[3])
    title:SetPoint("TOP", f, "TOP", 0, -16)
    title:SetText(L["Настройки NarcissusSirus"])

    local closeBtn = NS.Widgets.CreateCloseButton(f, 22, function() f:Hide() end)
    closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -8, -8)

    local scrollFrame = CreateFrame("ScrollFrame", "NarcissusSirus_SettingsScroll", f,
                                    "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 6, -PANEL_TOP)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -26, PANEL_FOOT)
    NS.Styling.StyleScrollBar(scrollFrame)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(320)
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)

    local yOffset = -4
    local db = NS.db

    local sectionTitle = content:CreateFontString(nil, "OVERLAY")
    sectionTitle:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    sectionTitle:SetTextColor(NS.Styling.ACCENT[1], NS.Styling.ACCENT[2], NS.Styling.ACCENT[3])
    sectionTitle:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    sectionTitle:SetText(L["Окно персонажа"])
    NS.Styling.CreateSectionRule(content, sectionTitle, 290)
    yOffset = yOffset - 26

    local function RefreshSlots()
        if NS.NarciUI and NS.NarciUI.isShown then NS.NarciUI:UpdateSlots() end
    end

    local iLvlCheck = NS.Widgets.CreateThemedCheckbox(content, L["Показывать ур. предметов на слотах"], db.showItemLevel, function(val)
        db.showItemLevel = val
        if NS.ItemLevel then
            if val then NS.ItemLevel:Update() else NS.ItemLevel:Hide() end
        end
        RefreshSlots()
    end)
    iLvlCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 24

    local enchantCheck = NS.Widgets.CreateThemedCheckbox(content, L["Показывать метки чар"], db.showEnchantInfo, function(val)
        db.showEnchantInfo = val
        if NS.EnchantInfo then
            if val then NS.EnchantInfo:Update() else NS.EnchantInfo:Hide() end
        end
        RefreshSlots()
    end)
    enchantCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 24

    local gemCheck = NS.Widgets.CreateThemedCheckbox(content, L["Показывать самоцветы у слотов"], db.showGemInfo, function(val)
        db.showGemInfo = val
        RefreshSlots()
    end)
    gemCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 24

    local compareCheck = NS.Widgets.CreateThemedCheckbox(content, L["Показывать сравнение предметов"], db.showComparison, function(val)
        db.showComparison = val
        if NS.ItemComparison then
            if val then NS.ItemComparison:Enable() else NS.ItemComparison:Disable() end
        end
    end)
    compareCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 24

    local namesCheck = NS.Widgets.CreateThemedCheckbox(content, L["Показывать названия предметов"], db.showItemNames, function(val)
        db.showItemNames = val
        RefreshSlots()
    end)
    namesCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 24

    local emptyCheck = NS.Widgets.CreateThemedCheckbox(content, L["Скрывать пустые ячейки"], db.hideEmptySlots, function(val)
        db.hideEmptySlots = val
        RefreshSlots()
    end)
    emptyCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 24

    local capsCheck = NS.Widgets.CreateThemedCheckbox(content, L["Подсвечивать важные характеристики"], db.showStatCaps, function(val)
        db.showStatCaps = val
        if NS.StatsPanel and NS.StatsPanel.frame and NS.StatsPanel.frame:IsShown() then
            NS.StatsPanel:Update()
        end
    end)
    capsCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 24

    local hideUICheck = NS.Widgets.CreateThemedCheckbox(content, L["Скрывать штатный интерфейс"], db.hideBlizzardUI, function(val)
        db.hideBlizzardUI = val
        if NS.NarciUI and NS.NarciUI.isShown then
            NS.NarciUI:RestoreOtherAddons()
            NS.NarciUI:HideOtherAddons()
        end
    end)
    hideUICheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 32

    local lenSlider = NS.Widgets.CreateThemedSlider(content, L["Длина названий предметов"], 12, 40, 1,
        db.nameLength or 24, function(val)
            db.nameLength = val
            RefreshSlots()
        end)
    lenSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    lenSlider:SetWidth(300)
    yOffset = yOffset - 40

    local sectionLook = content:CreateFontString(nil, "OVERLAY")
    sectionLook:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    sectionLook:SetTextColor(NS.Styling.ACCENT[1], NS.Styling.ACCENT[2], NS.Styling.ACCENT[3])
    sectionLook:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    sectionLook:SetText(L["Оформление"])
    NS.Styling.CreateSectionRule(content, sectionLook, 290)
    yOffset = yOffset - 28

    local dimSlider = NS.Widgets.CreateThemedSlider(content, L["Затемнение мира"], 0, 100, 5,
        db.worldDim or 0, function(val)
            db.worldDim = val
            if NS.NarciUI then NS.NarciUI:ApplyWorldDim() end
        end, "%")
    dimSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    dimSlider:SetWidth(300)
    yOffset = yOffset - 38

    local scaleSlider
    local autoScaleCheck = NS.Widgets.CreateThemedCheckbox(content, L["Подбирать масштаб автоматически"],
        db.scaleOverride == nil, function(val)
            if val then
                db.scaleOverride = nil
            else
                local ui = NS.NarciUI
                db.scaleOverride = (ui and ui._appliedScale) or 1
                if scaleSlider then
                    scaleSlider:SetValue(math.floor(db.scaleOverride * 100 + 0.5))
                end
            end
            if NS.NarciUI then NS.NarciUI:ApplyScale() end
        end)
    autoScaleCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 30

    scaleSlider = NS.Widgets.CreateThemedSlider(content, L["Масштаб окна"], 55, 100, 1,
        math.floor(((db.scaleOverride or (NS.NarciUI and NS.NarciUI:GetAutoScale()) or 1) * 100) + 0.5),
        function(val)
            db.scaleOverride = val / 100
            autoScaleCheck:SetChecked(false)
            if NS.NarciUI then NS.NarciUI:ApplyScale() end
        end, "%")
    scaleSlider:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    scaleSlider:SetWidth(300)
    yOffset = yOffset - 38

    local backlightCheck = NS.Widgets.CreateThemedCheckbox(content, L["Подсветка за моделью"], db.modelBacklight, function(val)
        db.modelBacklight = val
        if NS.NarciUI then NS.NarciUI:ApplyBacklight() end
    end)
    backlightCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 24

    local modelViewCheck = NS.Widgets.CreateThemedCheckbox(content, L["Запоминать поворот модели"], db.rememberModelView, function(val)
        db.rememberModelView = val
    end)
    modelViewCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 24

    local animCheck = NS.Widgets.CreateThemedCheckbox(content, L["Анимации интерфейса"], db.animations, function(val)
        db.animations = val
    end)
    animCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 28

    local accentLabel = content:CreateFontString(nil, "OVERLAY")
    accentLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    accentLabel:SetTextColor(NS.Styling.TEXT_BRIGHT[1], NS.Styling.TEXT_BRIGHT[2], NS.Styling.TEXT_BRIGHT[3])
    accentLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    accentLabel:SetText(L["Цвет темы"])
    yOffset = yOffset - 20

    local accentPicker = NS.Widgets.CreateAccentPicker(content, db.accentColor or "emerald", function(key)
        if key == db.accentColor then return end
        NS.Widgets.ShowConfirm(
            L["Сменить цвет темы?\nИнтерфейс будет перезагружен."],
            L["Сменить"],
            function()
                db.accentColor = key
                ReloadUI()
            end)
    end)
    accentPicker:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 26

    local localeLabel = content:CreateFontString(nil, "OVERLAY")
    localeLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    localeLabel:SetTextColor(NS.Styling.TEXT_BRIGHT[1], NS.Styling.TEXT_BRIGHT[2], NS.Styling.TEXT_BRIGHT[3])
    localeLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    localeLabel:SetText(L["Язык"])
    yOffset = yOffset - 20

    local localePicker = NS.Widgets.CreateOptionPicker(content, NS.LOCALE_OPTIONS,
        db.locale or "auto", function(key)
            if key == (db.locale or "auto") then return end
            NS.Widgets.ShowConfirm(
                L["Сменить язык?\nИнтерфейс будет перезагружен."],
                L["Сменить"],
                function()
                    db.locale = key
                    ReloadUI()
                end)
        end)
    localePicker:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 28

    local sectionTitle2 = content:CreateFontString(nil, "OVERLAY")
    sectionTitle2:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    sectionTitle2:SetTextColor(NS.Styling.ACCENT[1], NS.Styling.ACCENT[2], NS.Styling.ACCENT[3])
    sectionTitle2:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    sectionTitle2:SetText(L["Модули"])
    NS.Styling.CreateSectionRule(content, sectionTitle2, 290)
    yOffset = yOffset - 26

    local openLabel = content:CreateFontString(nil, "OVERLAY")
    openLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    openLabel:SetTextColor(NS.Styling.TEXT_BRIGHT[1], NS.Styling.TEXT_BRIGHT[2], NS.Styling.TEXT_BRIGHT[3])
    openLabel:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    openLabel:SetText(L["Вкладка при открытии"])
    yOffset = yOffset - 20

    local openOptions = {
        { key = "none",             label = L["нет"] },
        { key = "StatsPanel",       label = L["Статы"] },
        { key = "Enhancements",     label = L["Усиления"] },
        { key = "TalentPanel",      label = L["Таланты"] },
        { key = "ProfessionsPanel", label = L["Профессии"] },
        { key = "TitleManager",     label = L["Титулы"] },
        { key = "OutfitManager",    label = L["Быстрые наборы"] },
    }
    local openPicker
    openPicker = NS.Widgets.CreateOptionPicker(content, openOptions,
        db.openPanel or "none", function(key)
            db.openPanel = key
            db.showStatsPanel = (key == "StatsPanel")
            openPicker:Refresh(key)
        end, 300)
    openPicker:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - (openPicker:GetHeight() + 8)

    local minimapCheck = NS.Widgets.CreateThemedCheckbox(content, L["Показывать кнопку на миникарте"], db.minimapButton, function(val)
        db.minimapButton = val
        if NS.MinimapButton then
            if val then NS.MinimapButton:Show() else NS.MinimapButton:Hide() end
        end
    end)
    minimapCheck:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)
    yOffset = yOffset - 30

    NS.Styling.CreateAnimatedSeparator(content, yOffset)
    yOffset = yOffset - 12

    local statsBtn = NS.Widgets.CreateThemedButton(content, L["Характеристики"], 100, 24, function()
        NS:ToggleStatsPanel()
    end)
    statsBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)

    local titleBtn = NS.Widgets.CreateThemedButton(content, L["Титулы"], 100, 24, function()
        NS:ToggleTitleManager()
    end)
    titleBtn:SetPoint("LEFT", statsBtn, "RIGHT", 6, 0)

    local previewBtn = NS.Widgets.CreateThemedButton(content, L["Превью"], 100, 24, function()
        NS:ToggleCharPreview()
    end)
    previewBtn:SetPoint("LEFT", titleBtn, "RIGHT", 6, 0)
    yOffset = yOffset - 30

    local outfitBtn = NS.Widgets.CreateThemedButton(content, L["Быстрые наборы"], 100, 24, function()
        NS:ToggleOutfitManager()
    end)
    outfitBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 16, yOffset)

    local screenshotBtn = NS.Widgets.CreateThemedButton(content, L["Скриншот"], 100, 24, function()
        f:Hide()
        NS.After(0.3, function()
            NS.ScreenshotTool:Take(true)
        end)
    end)
    screenshotBtn:SetPoint("LEFT", outfitBtn, "RIGHT", 6, 0)

    local screenshotDelayBtn = NS.Widgets.CreateThemedButton(content, L["Скриншот через 3с"], 100, 24, function()
        f:Hide()
        NS.ScreenshotTool:TakeWithCountdown(3, true)
    end)
    screenshotDelayBtn:SetPoint("LEFT", screenshotBtn, "RIGHT", 6, 0)
    yOffset = yOffset - 40

    content:SetHeight(-yOffset + 8)

    local footRule = f:CreateTexture(nil, "ARTWORK")
    footRule:SetHeight(1)
    footRule:SetTexture("Interface\\Buttons\\WHITE8x8")
    footRule:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 40, PANEL_FOOT)
    footRule:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -40, PANEL_FOOT)
    footRule:SetVertexColor(NS.Styling.BORDER[1], NS.Styling.BORDER[2], NS.Styling.BORDER[3], 0.7)

    local info = f:CreateFontString(nil, "OVERLAY")
    info:SetFont("Fonts\\FRIZQT__.TTF", 9, "")
    info:SetTextColor(0.5, 0.5, 0.5)
    info:SetPoint("BOTTOM", f, "BOTTOM", 0, 12)
    info:SetText("NarcissusSirus v1.0.0 | /narci - " .. L["команды"])

    NS.settingsFrame = f
    f:Hide()
end

function NS:OnPlayerLogin()
    if NS.Styling and NS.Styling.ApplyAccent and NS.db then
        NS.Styling.ApplyAccent(NS.db.accentColor or "emerald")
    end

    if PlayerTalentFrame and not PlayerTalentFrame._narciGlyphHook then
        PlayerTalentFrame._narciGlyphHook = true
        PlayerTalentFrame:HookScript("OnShow", function(self)
            if NS.NarciUI and NS.NarciUI.isShown then
                HideUIPanel(self)
            end
        end)
    end

    if NS.CharFrame then
        NS.CharFrame:Init()
    end

    if NS.ItemComparison and NS.db.showComparison then
        NS.ItemComparison:Enable()
    end

    if NS.db.minimapButton and NS.MinimapButton then
        NS.MinimapButton:Show()
    end

    local eventFrame = CreateFrame("Frame")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("UNIT_INVENTORY_CHANGED")
    eventFrame:RegisterEvent("COMBAT_RATING_UPDATE")
    eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
    eventFrame:RegisterEvent("UNIT_MODEL_CHANGED")
    eventFrame:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
    eventFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
    eventFrame:RegisterEvent("GLYPH_UPDATED")
    eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    eventFrame:RegisterEvent("PLAYER_MONEY")

    local slotsPending, statsPending, modelPending = false, false, false

    local function RefreshEquipment()
        slotsPending = false
        if NS.NarciUI and NS.NarciUI.isShown then
            NS.NarciUI:UpdateSlots()
            NS.NarciUI:UpdatePlayerInfo()
        end
        if CharacterFrame and CharacterFrame:IsShown() then
            if NS.CharFrame then NS.CharFrame:UpdateInfoPanel() end
            if NS.ItemLevel then NS.ItemLevel:Update() end
            if NS.EnchantInfo then NS.EnchantInfo:Update() end
        end
    end

    local function RefreshStats()
        statsPending = false
        if NS.StatsPanel and NS.StatsPanel.frame and NS.StatsPanel.frame:IsShown() then
            NS.StatsPanel:Update()
        end
        if NS.TalentPanel and NS.TalentPanel.frame and NS.TalentPanel.frame:IsShown() then
            NS.TalentPanel:Update()
        end
    end

    local function RefreshModel()
        modelPending = false
        if NS.NarciUI and NS.NarciUI.isShown then
            NS.NarciUI:RefreshModel()
        end
    end

    eventFrame:SetScript("OnEvent", function(self, event, arg1)
        if (event == "UNIT_INVENTORY_CHANGED" or event == "UNIT_MODEL_CHANGED")
           and arg1 ~= "player" then
            return
        end

        local equipmentChanged = event == "PLAYER_EQUIPMENT_CHANGED"
                              or event == "UNIT_INVENTORY_CHANGED"

        if equipmentChanged then
            if not slotsPending then
                slotsPending = true
                NS.After(0.1, RefreshEquipment)
            end
        end

        if equipmentChanged
           or event == "UNIT_MODEL_CHANGED"
           or event == "UPDATE_SHAPESHIFT_FORM" then
            if not modelPending then
                modelPending = true
                NS.After(0.1, RefreshModel)
            end
        end

        if not statsPending then
            statsPending = true
            NS.After(0.1, RefreshStats)
        end
    end)

    NS.Print(L["Загружен! Введите |cff00ccff/narci|r для списка команд."])
end

function NS:ToggleCharacterUI()
    if NS.NarciUI then
        NS.NarciUI:Toggle()
    else
        if CharacterFrame then
            if CharacterFrame:IsShown() then
                HideUIPanel(CharacterFrame)
            else
                ShowUIPanel(CharacterFrame)
            end
        end
    end
end

function NS:ToggleSettings()
    CreateSettingsPanel()
    if NS.settingsFrame:IsShown() then
        NS.settingsFrame:Hide()
    else
        NS.settingsFrame:Show()
    end
end

local EXCLUSIVE_PANELS = { "StatsPanel", "Enhancements", "TalentPanel", "ProfessionsPanel",
                           "TitleManager", "OutfitManager" }

function NS:HideAllPanels()
    for _, name in ipairs(EXCLUSIVE_PANELS) do
        local panel = NS[name]
        if panel and panel.Hide then panel:Hide() end
    end
    if NS.NarciUI and NS.NarciUI.UpdateToolbarState then
        NS.NarciUI:UpdateToolbarState()
    end
end

local function TogglePanel(name)
    local panel = NS[name]
    if not panel then
        NS.Print(L["Модуль не загружен: "] .. name)
        return
    end
    local opening = not (panel.frame and panel.frame:IsShown())

    for _, other in ipairs(EXCLUSIVE_PANELS) do
        if other ~= name then
            local p = NS[other]
            if p and p.frame and p.frame:IsShown() then
                NS.Styling.PanelOut(p.frame)
            end
        end
    end

    panel:Toggle()
    if NS.NarciUI and NS.NarciUI.UpdateToolbarState then
        NS.NarciUI:UpdateToolbarState(opening and name or nil)
    end
end

function NS:TogglePanelByName(name) TogglePanel(name) end

function NS:ToggleStatsPanel()    TogglePanel("StatsPanel")    end
function NS:ToggleEnhancements()  TogglePanel("Enhancements")  end
function NS:ToggleTalentPanel()   TogglePanel("TalentPanel")   end
function NS:ToggleProfessions()   TogglePanel("ProfessionsPanel") end
function NS:ToggleTitleManager()  TogglePanel("TitleManager")  end
function NS:ToggleOutfitManager() TogglePanel("OutfitManager") end

function NS:ToggleCharPreview()
    if NS.CharPreview then
        NS.CharPreview:Toggle()
    end
end

function NS:TakeScreenshot()
    if NS.ScreenshotTool then
        NS.ScreenshotTool:Take(true)
    end
end
