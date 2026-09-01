local addonName, NS = ...
local L = NS.L

local DEFAULTS = {
    minimapButton = true,
    minimapAngle = 3.84,
    showItemLevel = true,
    showEnchantInfo = true,
    showGemInfo = true,
    showStatsPanel = true,
    showComparison = true,
    screenshotQuality = 3,
    scaleOverride = nil,
    worldDim = 55,
    accentColor = "emerald",
    showItemNames = true,
    modelBacklight = true,
    animations = true,
    hideEmptySlots = false,
    nameLength = 24,
    locale = "auto",
    hideBlizzardUI = true,
    showStatCaps = true,
    openPanel = nil,
    rememberModelView = false,
}

local function InitDB()
    if not NarcissusSirusDB then
        NarcissusSirusDB = {}
    end
    for k, v in pairs(DEFAULTS) do
        if NarcissusSirusDB[k] == nil then
            NarcissusSirusDB[k] = v
        end
    end

    if NarcissusSirusDB.openPanel == nil then
        NarcissusSirusDB.openPanel =
            NarcissusSirusDB.showStatsPanel and "StatsPanel" or "none"
    end
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
        NS.db = NarcissusSirusDB
        if NS.ApplyLocale then NS.ApplyLocale(NarcissusSirusDB.locale) end
        NS.initialized = true
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        if NS.initialized then
            NS:OnPlayerLogin()
        end
    end
end)

SLASH_NARCISSUS1 = "/narci"
SLASH_NARCISSUS2 = "/narcissus"
SlashCmdList["NARCISSUS"] = function(msg)
    msg = strtrim(msg):lower()
    if msg == "config" or msg == "settings" then
        NS:ToggleSettings()
    elseif msg == "stats" then
        NS:ToggleStatsPanel()
    elseif msg == "title" then
        NS:ToggleTitleManager()
    elseif msg == "preview" then
        NS:ToggleCharPreview()
    elseif msg == "outfit" or msg == "outfits" then
        NS:ToggleOutfitManager()
    elseif msg == "screenshot" then
        NS:TakeScreenshot()
    elseif msg:sub(1, 5) == "save " then
        local name = msg:sub(6)
        if NS.OutfitManager then NS.OutfitManager:SaveOutfit(name) end
    elseif msg:sub(1, 5) == "load " then
        local name = msg:sub(6)
        if NS.OutfitManager then NS.OutfitManager:LoadOutfit(name) end
    elseif msg:sub(1, 7) == "delete " then
        local name = msg:sub(8)
        if NS.OutfitManager then NS.OutfitManager:DeleteOutfit(name) end
    elseif msg == "list" then
        if NS.OutfitManager then NS.OutfitManager:ListOutfits() end
    elseif msg == "prio" or msg:sub(1, 5) == "prio " then
        local arg = strtrim(msg:sub(6))
        if not NS.StatPriority then
            NS.Print(L["модуль приоритета характеристик не загружен"])
        elseif arg == "" then
            NS.StatPriority:Print()
        elseif arg == "auto" or arg == "off" then
            NS.StatPriority:SetTierOverride(nil)
        else
            local n = tonumber(arg:match("(%d+)"))
            if n and n >= 1 and n <= 10 then
                NS.StatPriority:SetTierOverride(n)
            else
                NS.Print(L["укажите номер набора от 1 до 10, либо auto"])
            end
        end
    elseif msg == "dim" or msg:sub(1, 4) == "dim " then
        local arg = strtrim(msg:sub(5))
        local n = tonumber(arg:match("(%d+)"))
        if arg == "" then
            NS.Print(L["затемнение мира: "] .. tostring(NS.db and NS.db.worldDim) ..
                     L[" (задать: /narci dim 0..100)"])
        elseif n and n >= 0 and n <= 100 then
            NS.db.worldDim = n
            if NS.NarciUI then NS.NarciUI:ApplyWorldDim() end
            NS.Print(L["затемнение мира: "] .. n)
        else
            NS.Print(L["укажите значение от 0 до 100"])
        end
    elseif msg == "scale" or msg:sub(1, 6) == "scale " then
        local arg = strtrim(msg:sub(7))
        local ui = NS.NarciUI
        if not ui then
            NS.Print(L["окно персонажа ещё не создано"])
        elseif arg == "" then
            NS.Print(format(L["масштаб: %.2f (расчётный %.2f%s)"],
                ui._appliedScale or 1, ui:GetAutoScale(),
                NS.db.scaleOverride and L[", закреплён вручную"] or ""))
        elseif arg == "auto" or arg == "off" then
            NS.db.scaleOverride = nil
            ui:ApplyScale()
            NS.Print(format(L["масштаб: автоподбор, %.2f"], ui._appliedScale or 1))
        else
            local n = tonumber((arg:gsub(",", ".")))
            if n and n >= 0.4 and n <= 1.5 then
                NS.db.scaleOverride = n
                ui:ApplyScale()
                NS.Print(format(L["масштаб закреплён: %.2f"], n))
            else
                NS.Print(L["укажите значение от 0.4 до 1.5, либо auto"])
            end
        end
    elseif msg == "bags" then
        if NS.NarciUI then NS.NarciUI:PrintBagDiagnostics() end
    else
        NS:ToggleCharacterUI()
    end
end
